const vk = @import("vulkan").vulkan;
const sdl = @import("sdl").sdl;
const spirv = @cImport(@cInclude("spirv_reflect/spirv_reflect.h"));
const SDL_CheckResult = @import("sdlError").SDL_CheckResult;
const std = @import("std");
const output = @import("output");
const Allocator = std.mem.Allocator;
const vulkanType = @import("vulkanType.zig");
const VkError = vulkanType.VkError;
const VkResult = vulkanType.VkResult;
const VkPhysicalType = vulkanType.VkPhysicalDeviceType;
const VkResultToError = @import("resultToError.zig");
const Mutex = std.Thread.Mutex;
const Thread = std.Thread;
const builtin = @import("builtin");
const VulkanPipelineInfo = @import("translate").VulkanPipelineInfo;

const layerNeeded = layer: {
    break :layer switch (builtin.mode) {
        .Debug, .ReleaseSafe => [_][*c]const u8{"VK_LAYER_KHRONOS_validation"},
        .ReleaseFast, .ReleaseSmall => [_][*c]const u8{},
    };
};
const extensionNeeded = [_][*c]const u8{ "VK_KHR_surface", "VK_KHR_win32_surface" };
const deviceExtensionNeeded = [_][*c]const u8{
    "VK_KHR_swapchain",
    "VK_EXT_descriptor_indexing",
    "VK_KHR_maintenance3",
    "VK_KHR_synchronization2",
    "VK_KHR_timeline_semaphore",
    "VK_KHR_dynamic_rendering",
    "VK_EXT_extended_dynamic_state",
};
const featureNeed = [_][]const u8{
    "geometryShader",
    "independentBlend",
    "samplerAnisotropy",
    "logicOp",
    "depthClamp",
    "depthBiasClamp",
    "wideLines",
};
const featureIndexingNeed = [_][]const u8{
    "shaderUniformBufferArrayNonUniformIndexing",
    "shaderStorageBufferArrayNonUniformIndexing",
    "shaderSampledImageArrayNonUniformIndexing",
    "descriptorBindingPartiallyBound",
    "runtimeDescriptorArray",
};
const featureTimelineSemaphoreNeed = [_][]const u8{"timelineSemaphore"};
const featureDynamicRenderingNeed = [_][]const u8{"dynamicRendering"};

fn comptime_print(comptime format: []const u8, comptime args: anytype) void {
    @compileLog(std.fmt.comptimePrint(format, args));
}

fn showErrorWithMessageBox(window: *sdl.SDL_Window, err: []const u8) void {
    var buffer: [256]u8 = undefined;
    const buffers: []const u8 = std.fmt.bufPrint(&buffer, "memory alloc failed\nERROR: {s}\n", .{err}) catch |err2| blk: {
        std.log.warn("buffer is not big enough {s}\n", .{@errorName(err2)});
        const backupMessage = "error\n";
        break :blk backupMessage;
    };

    SDL_CheckResult(sdl.SDL_ShowSimpleMessageBox(sdl.SDL_MESSAGEBOX_ERROR, "memory alloc failed", @ptrCast(buffers.ptr), window)) catch |err3| {
        std.log.err("{s}", .{@errorName(err3)});
    };
}

fn calculateMemoryGPU(memoryProperty: vk.VkPhysicalDeviceMemoryProperties) u64 {
    var totalCount: u64 = 0;
    for (0..memoryProperty.memoryHeapCount) |i| {
        if (memoryProperty.memoryHeaps[i].flags & vk.VK_MEMORY_HEAP_DEVICE_LOCAL_BIT != 0) {
            totalCount += memoryProperty.memoryHeaps[i].size;
        }
    }
    return totalCount;
}

fn featureNeededCheck(comptime featureType: type, featurePack: anytype) bool {
    var count: u32 = 0;
    var len: u32 = 0;
    switch (featureType) {
        vk.VkPhysicalDeviceFeatures => {
            len = featureNeed.len;
            inline for (featureNeed) |feature| {
                // if (@field(featurePack, feature) == 1) {
                //     count += 1;
                // }
                count += @field(featurePack, feature);
            }
        },
        vk.VkPhysicalDeviceDescriptorIndexingFeatures => {
            len = featureIndexingNeed.len;
            inline for (featureIndexingNeed) |feature| {
                count += @field(featurePack, feature);
            }
        },
        vk.VkPhysicalDeviceTimelineSemaphoreFeatures => {
            len = featureTimelineSemaphoreNeed.len;
            inline for (featureTimelineSemaphoreNeed) |feature| {
                count += @field(featurePack, feature);
            }
        },
        vk.VkPhysicalDeviceDynamicRenderingFeatures => {
            len = featureDynamicRenderingNeed.len;
            inline for (featureDynamicRenderingNeed) |feature| {
                count += @field(featurePack, feature);
            }
        },
        else => {
            @compileError("unsupported");
        },
    }
    return count == len;
}

const VkQueueFamily = struct {
    familyIndice: i32 = -1,
    queueCount: u32 = 0,
};
const VkTheadQueue = struct { queue: vk.VkQueue = null, mutex: Mutex = .{} };

const setLayoutLimit = @import("translate").setLayoutLimit;
const Pipeline = struct {
    descriptorSetLayouts: [setLayoutLimit]vk.VkDescriptorSetLayout,
    setCount: u32,
    pipelineLayout: vk.VkPipelineLayout,
    pipeline: vk.VkPipeline,
};

pub const VkStruct = struct {
    const Self = @This();

    allocator: Allocator,
    allocCallBacks: vk.VkAllocationCallbacks = undefined,
    pAllocCallBacks: [*c]vk.VkAllocationCallbacks = null,
    window: *sdl.SDL_Window = undefined,
    instance: vk.VkInstance = null,
    surface: vk.VkSurfaceKHR = null,
    physicalDevice: vk.VkPhysicalDevice = null,
    device: vk.VkDevice = null,

    graphicQueueFamily: VkQueueFamily = .{},
    graphicQueue: [16]VkTheadQueue = undefined,
    graphicQueueCrashList: [16]usize = undefined,
    computeQueueFamily: VkQueueFamily = .{},
    computeQueue: [16]VkTheadQueue = undefined,
    computeQueueCrashList: [16]usize = undefined,
    transferQueueFamily: VkQueueFamily = .{},
    transferQueue: [8]VkTheadQueue = undefined,
    transferQueueCrashList: [8]usize = undefined,

    shaderModules: std.StringHashMap(vk.VkShaderModule),
    entryNames: std.StringHashMap(void),

    pipelineCache: vk.VkPipelineCache = null,

    graphicPipelineCreateInfo: [10]vk.VkGraphicsPipelineCreateInfo = undefined,
    preGraphicInfoPtrs: [10]VulkanPipelineInfo = undefined,
    graphicInfoCount: u32 = 0,

    pipelines: std.StringHashMap(Pipeline),

    pub fn init(allocator: Allocator) VkStruct {
        return VkStruct{
            .allocator = allocator,
            .shaderModules = std.StringHashMap(vk.VkShaderModule).init(allocator),
            .entryNames = std.StringHashMap(void).init(allocator),
            .pipelines = std.StringHashMap(Pipeline).init(allocator),
        };
    }

    pub fn initVulkan(self: *Self) !void {
        try self.*.createWindow();
        const version = try getVulkanVersion();
        printVersion(version);
        try self.createInstance();
        try self.createSurface();
        try self.pickPhysicalDevice();
        try self.setQueueFamilies();
        try self.createDevice();
        self.createQueue();
    }

    pub fn deinit(self: *Self) void {
        var pipelines = self.pipelines.valueIterator();
        while (pipelines.next()) |val| {
            vk.vkDestroyPipeline(self.device, val.pipeline, self.pAllocCallBacks);
            vk.vkDestroyPipelineLayout(self.device, val.pipelineLayout, self.pAllocCallBacks);
            for (0..val.setCount) |i| {
                vk.vkDestroyDescriptorSetLayout(
                    self.device,
                    val.descriptorSetLayouts[i],
                    self.pAllocCallBacks,
                );
            }
        }

        var entryNames = self.entryNames.keyIterator();
        while (entryNames.next()) |name| {
            self.allocator.free(name.*);
        }

        var shaderCodes = self.shaderModules.valueIterator();
        while (shaderCodes.next()) |code| {
            vk.vkDestroyShaderModule(self.device, code.*, self.pAllocCallBacks);
        }

        vk.vkDestroyDevice(self.device, self.pAllocCallBacks);
        sdl.SDL_Vulkan_DestroySurface(@ptrCast(self.*.instance), @ptrCast(self.*.surface), @ptrCast(self.*.pAllocCallBacks));
        vk.vkDestroyInstance(self.*.instance, self.*.pAllocCallBacks);
        sdl.SDL_DestroyWindow(self.*.window);
    }

    fn createWindow(self: *Self) !void {
        const temp = sdl.SDL_CreateWindow("window", 800, 600, sdl.SDL_WINDOW_VULKAN);
        if (temp) |window| {
            self.*.window = window;
        } else {
            std.log.err("SDL error {s}", .{sdl.SDL_GetError()});
            return VkError.VK_ERROR_UNKNOWN;
        }
    }

    fn initAllocCallBacks(self: *Self) void {
        _ = self;
        // self.*.allocCallBacks.pUserData = null;
        // self.*.allocCallBacks.pfnAllocation = vkAlloc;
        // self.*.allocCallBacks.pfnReallocation = vkRealloc;
        // self.*.allocCallBacks.pfnFree = vkFree;
        // self.*.allocCallBacks.pfnInternalAllocation = null;
        // self.*.allocCallBacks.pfnInternalFree = null;
    }

    fn checkVkResult(result: vk.VkResult) VkError!void {
        VkResultToError.VkResultToError(@enumFromInt(result)) catch |err| {
            return err;
        };
    }

    fn getVulkanVersion() VkError!u32 {
        var apiVersion: c_uint = 0;
        try checkVkResult(vk.vkEnumerateInstanceVersion(&apiVersion));

        return apiVersion;
    }

    fn printVersion(apiVersion: u32) void {
        const major = vk.VK_VERSION_MAJOR(apiVersion);
        const minor = vk.VK_VERSION_MINOR(apiVersion);
        const patch = vk.VK_VERSION_PATCH(apiVersion);

        std.debug.print("Vulkan API Version: {d}.{d}.{d}\n", .{ major, minor, patch });
    }

    fn createInstance(self: *Self) VkError!void {
        var appInfo = vk.VkApplicationInfo{
            .sType = vk.VK_STRUCTURE_TYPE_APPLICATION_INFO,
            .pNext = null,
            .pApplicationName = "game",
            .applicationVersion = vk.VK_MAKE_API_VERSION(0, 1, 0, 0),
            .pEngineName = "engine",
            .engineVersion = vk.VK_MAKE_API_VERSION(0, 1, 0, 0),
            .apiVersion = vk.VK_API_VERSION_1_4,
        };

        const layers = try self.*.chooseEnabledLayers(vk.VkLayerProperties, "layerName", layerNeeded[0..layerNeeded.len], null);
        defer layers.deinit();
        const extension = try self.*.chooseEnabledLayers(vk.VkExtensionProperties, "extensionName", extensionNeeded[0..extensionNeeded.len], null);
        defer extension.deinit();

        const createInfo = self.*.allocator.create(vk.VkInstanceCreateInfo) catch |err| {
            std.debug.print("err: {s}\n", .{@errorName(err)});
            return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
        };
        defer self.*.allocator.destroy(createInfo);

        createInfo.*.sType = vk.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
        createInfo.*.pNext = null;
        createInfo.*.flags = 0;
        createInfo.*.pApplicationInfo = &appInfo;
        createInfo.*.enabledLayerCount = @truncate(layers.items.len);
        createInfo.*.ppEnabledLayerNames = @ptrCast(layers.items.ptr);
        createInfo.*.enabledExtensionCount = @truncate(extension.items.len);
        // std.debug.print("len {d}\n", .{extension.items.len});
        createInfo.*.ppEnabledExtensionNames = @ptrCast(extension.items.ptr);

        try checkVkResult(vk.vkCreateInstance(createInfo, self.*.pAllocCallBacks, @ptrCast(&self.*.instance)));
    }

    fn chooseEnabledLayers(self: *Self, comptime fields: type, comptime field_name: []const u8, neededName: []const [*c]const u8, physicalDevice: vk.VkPhysicalDevice) VkError!std.array_list.Managed([*c]const u8) {
        var namesEnabled = std.array_list.Managed([*c]const u8).init(self.*.allocator);

        var count: u32 = 0;
        var vulkanNames: []fields = undefined;
        switch (fields) {
            vk.VkLayerProperties => {
                try checkVkResult(vk.vkEnumerateInstanceLayerProperties(&count, null));
                vulkanNames = self.*.allocator.alloc(fields, count) catch |err| {
                    std.debug.print("err: {s}\n", .{@errorName(err)});
                    return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
                };
                try checkVkResult(vk.vkEnumerateInstanceLayerProperties(&count, vulkanNames.ptr));
            },
            vk.VkExtensionProperties => {
                if (physicalDevice) |device| {
                    try checkVkResult(vk.vkEnumerateDeviceExtensionProperties(device, null, &count, null));
                    vulkanNames = self.*.allocator.alloc(fields, count) catch |err| {
                        std.debug.print("err: {s}\n", .{@errorName(err)});
                        return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
                    };
                    try checkVkResult(vk.vkEnumerateDeviceExtensionProperties(device, null, &count, vulkanNames.ptr));
                } else {
                    try checkVkResult(vk.vkEnumerateInstanceExtensionProperties(null, &count, null));
                    vulkanNames = self.*.allocator.alloc(fields, count) catch |err| {
                        std.debug.print("err: {s}\n", .{@errorName(err)});
                        return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
                    };
                    try checkVkResult(vk.vkEnumerateInstanceExtensionProperties(null, &count, vulkanNames.ptr));
                }
            },
            else => {
                @compileError("not supported type");
            },
        }
        defer self.*.allocator.free(vulkanNames);

        for (neededName) |need| {
            var str: [256]u8 = undefined;
            const len = sdl.SDL_strlen(need);
            for (vulkanNames) |vulkan| {
                @memcpy(str[0..len], need);
                // std.debug.print("len: {d}, name1: {s}, name2: {s}\n", .{ len, str[0..len], @field(vulkan, field_name) });
                if (std.mem.eql(u8, str[0..len], @field(vulkan, field_name)[0..len])) {
                    namesEnabled.append(need) catch |err| {
                        std.debug.print("err: {s}\n", .{@errorName(err)});
                        return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
                    };
                    break;
                }
            }
        }
        return namesEnabled;
    }

    fn createSurface(self: *Self) !void {
        try SDL_CheckResult(sdl.SDL_Vulkan_CreateSurface(self.*.window, @ptrCast(self.*.instance), @ptrCast(self.*.pAllocCallBacks), @ptrCast(&self.*.surface)));
    }

    fn pickPhysicalDevice(self: *Self) !void {
        var deviceCount: u32 = 0;
        try checkVkResult(vk.vkEnumeratePhysicalDevices(self.*.instance, @ptrCast(&deviceCount), null));
        if (deviceCount == 0) {
            try SDL_CheckResult(sdl.SDL_ShowSimpleMessageBox(sdl.SDL_MESSAGEBOX_ERROR, "vulkan not support", "you device is not support vulkan", self.*.window));
        }

        const physicalDevices: []vk.VkPhysicalDevice = self.*.allocator.alloc(vk.VkPhysicalDevice, deviceCount) catch |err| {
            showErrorWithMessageBox(self.*.window, @errorName(err));

            return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
        };
        defer self.*.allocator.free(physicalDevices);
        std.debug.print("device count: {d}\n", .{deviceCount});
        try checkVkResult(vk.vkEnumeratePhysicalDevices(self.*.instance, @ptrCast(&deviceCount), @ptrCast(physicalDevices.ptr)));

        var biggestMemory: u64 = 0;
        for (physicalDevices) |device| {
            if (device) |devicee| {
                const array = try self.*.chooseEnabledLayers(vk.VkExtensionProperties, "extensionName", deviceExtensionNeeded[0..deviceExtensionNeeded.len], devicee);
                defer array.deinit();
                if (array.items.len != deviceExtensionNeeded.len) {
                    continue;
                }
                var deviceProperty: vk.VkPhysicalDeviceProperties = undefined;
                var deviceMemoryProperty: vk.VkPhysicalDeviceMemoryProperties = undefined;
                var deviceFeatures: vk.VkPhysicalDeviceFeatures = undefined;

                var renderingFeature = vk.VkPhysicalDeviceDynamicRenderingFeatures{
                    .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES,
                    .pNext = null,
                };
                var timelineFeature = vk.VkPhysicalDeviceTimelineSemaphoreFeatures{
                    .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES,
                    .pNext = &renderingFeature,
                };
                var indexingFeature = vk.VkPhysicalDeviceDescriptorIndexingFeatures{
                    .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES,
                    .pNext = &timelineFeature,
                };
                var deviceFeatures2 = vk.VkPhysicalDeviceFeatures2{
                    .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
                    .pNext = &indexingFeature,
                };

                vk.vkGetPhysicalDeviceProperties(devicee, @ptrCast(&deviceProperty));
                vk.vkGetPhysicalDeviceMemoryProperties(devicee, @ptrCast(&deviceMemoryProperty));
                vk.vkGetPhysicalDeviceFeatures(devicee, @ptrCast(&deviceFeatures));
                vk.vkGetPhysicalDeviceFeatures2(devicee, @ptrCast(&deviceFeatures2));

                // TODO memory requirement undeclared
                const memoryCount = calculateMemoryGPU(deviceMemoryProperty);
                if (memoryCount < biggestMemory) {
                    continue;
                }

                const featureSupported = featureNeededCheck(vk.VkPhysicalDeviceFeatures, deviceFeatures);
                const featureIndexingSupported = featureNeededCheck(vk.VkPhysicalDeviceDescriptorIndexingFeatures, indexingFeature);
                const featureTimelineSemaphoreSupported = featureNeededCheck(vk.VkPhysicalDeviceTimelineSemaphoreFeatures, timelineFeature);
                const featureDynamicRenderingSupported = featureNeededCheck(vk.VkPhysicalDeviceDynamicRenderingFeatures, renderingFeature);

                if (featureSupported and featureIndexingSupported and featureTimelineSemaphoreSupported and featureDynamicRenderingSupported) {
                    switch (deviceProperty.deviceType) {
                        vk.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU => {
                            self.*.physicalDevice = devicee;
                            biggestMemory = @max(biggestMemory, memoryCount);
                        },
                        vk.VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU => {
                            if (self.*.physicalDevice == null) {
                                self.*.physicalDevice = devicee;
                                biggestMemory = @max(biggestMemory, memoryCount);
                            }
                        },
                        else => {
                            // TODO add warn message box
                            return VkError.VK_ERROR_UNKNOWN;
                        },
                    }
                } else {}

                std.debug.print("device: choosed {s}\n", .{@tagName(@as(VkPhysicalType, @enumFromInt(deviceProperty.deviceType)))});
            } else {}
        }
    }

    fn setQueueFamilies(self: *Self) !void {
        var queueFamilyCount: u32 = 0;
        vk.vkGetPhysicalDeviceQueueFamilyProperties(self.*.physicalDevice, &queueFamilyCount, null);

        const queueFamilys: []vk.VkQueueFamilyProperties = self.*.allocator.alloc(vk.VkQueueFamilyProperties, queueFamilyCount) catch |err| {
            showErrorWithMessageBox(self.*.window, @errorName(err));

            return VkError.VK_ERROR_OUT_OF_HOST_MEMORY;
        };
        defer self.*.allocator.free(queueFamilys);
        vk.vkGetPhysicalDeviceQueueFamilyProperties(self.*.physicalDevice, &queueFamilyCount, @ptrCast(queueFamilys.ptr));

        var graphic: bool = false;
        var compute: bool = false;
        var transfer: bool = false;
        var present: bool = false;
        var sparse: bool = false;
        var encode: bool = false;
        var decode: bool = false;
        for (queueFamilys, 0..queueFamilyCount) |queueFamily, i_usize| {
            const i: u32 = @truncate(i_usize);
            const i_i32 = @as(i32, @bitCast(i));
            graphic = false;
            transfer = false;
            present = false;
            compute = false;
            sparse = false;
            encode = false;
            decode = false;
            if ((queueFamily.queueFlags & vk.VK_QUEUE_GRAPHICS_BIT) != 0) {
                graphic = true;
            }
            if ((queueFamily.queueFlags & vk.VK_QUEUE_COMPUTE_BIT) != 0) {
                compute = true;
            }
            if ((queueFamily.queueFlags & vk.VK_QUEUE_TRANSFER_BIT) != 0) {
                transfer = true;
            }
            if ((queueFamily.queueFlags & vk.VK_QUEUE_SPARSE_BINDING_BIT) != 0) {
                sparse = true;
            }
            if ((queueFamily.queueFlags & vk.VK_QUEUE_VIDEO_ENCODE_BIT_KHR) != 0) {
                encode = true;
            }
            if ((queueFamily.queueFlags & vk.VK_QUEUE_VIDEO_DECODE_BIT_KHR) != 0) {
                decode = true;
            }
            var presentSupport: u32 = 0;
            try checkVkResult(vk.vkGetPhysicalDeviceSurfaceSupportKHR(self.*.physicalDevice, i, self.*.surface, @ptrCast(&presentSupport)));
            if (presentSupport == 1) {
                present = true;
            }

            if (graphic and present) {
                self.graphicQueueFamily.familyIndice = i_i32;
                self.graphicQueueFamily.queueCount = queueFamily.queueCount;
                // std.debug.print("family a g_P {d}\n", .{i_usize});
            }

            if (compute and !graphic) {
                self.computeQueueFamily.familyIndice = i_i32;
                self.computeQueueFamily.queueCount = queueFamily.queueCount;
                // std.debug.print("family a com {d}\n", .{i_usize});
            }

            if (transfer and !graphic and !compute and !decode and !encode) {
                self.transferQueueFamily.familyIndice = i_i32;
                self.transferQueueFamily.queueCount = queueFamily.queueCount;
                // std.debug.print("family a tra\n", .{});
            }
        }
    }
    fn createDevice(self: *Self) !void {
        var dynamicRenderingFeature = vk.VkPhysicalDeviceDynamicRenderingFeatures{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES,
            .pNext = null,
        };
        inline for (featureDynamicRenderingNeed) |feature| {
            @field(dynamicRenderingFeature, feature) = 1;
        }
        var timelineSemaphoreFeature = vk.VkPhysicalDeviceTimelineSemaphoreFeatures{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES,
            .pNext = &dynamicRenderingFeature,
        };
        inline for (featureTimelineSemaphoreNeed) |feature| {
            @field(timelineSemaphoreFeature, feature) = 1;
        }
        var indexingFeature = vk.VkPhysicalDeviceDescriptorIndexingFeatures{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES,
            .pNext = &timelineSemaphoreFeature,
        };
        inline for (featureIndexingNeed) |feature| {
            @field(indexingFeature, feature) = 1;
        }
        var feature2 = vk.VkPhysicalDeviceFeatures2{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
            .pNext = &indexingFeature,
        };
        inline for (featureNeed) |feature| {
            @field(feature2.features, feature) = 1;
        }

        const queueCreateInfo, const queueCount = blk: {
            const queuePriorities = [_]f32{0.0} ** 16;
            var count: u32 = 0;
            var createInfos: [3]vk.VkDeviceQueueCreateInfo = undefined;
            const queueFamilies: [3]VkQueueFamily = .{ self.graphicQueueFamily, self.computeQueueFamily, self.transferQueueFamily };
            for (queueFamilies) |queue| {
                if (queue.familyIndice != -1) {
                    createInfos[count].sType = vk.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
                    createInfos[count].pNext = null;
                    createInfos[count].flags = 0;
                    createInfos[count].queueCount = queue.queueCount;
                    createInfos[count].queueFamilyIndex = @bitCast(queue.familyIndice);
                    createInfos[count].pQueuePriorities = @ptrCast(&queuePriorities);
                    count += 1;
                }
            }
            break :blk .{ createInfos, count };
        };

        var createInfo = vk.VkDeviceCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
            .pNext = &feature2,
            .flags = 0,
            .queueCreateInfoCount = queueCount,
            .pQueueCreateInfos = @ptrCast(&queueCreateInfo),
            .enabledLayerCount = @truncate(layerNeeded.len),
            .ppEnabledLayerNames = @ptrCast(&layerNeeded),
            .enabledExtensionCount = @truncate(deviceExtensionNeeded.len),
            .ppEnabledExtensionNames = @ptrCast(&deviceExtensionNeeded),
            .pEnabledFeatures = null,
        };

        try checkVkResult(vk.vkCreateDevice(self.physicalDevice, @ptrCast(&createInfo), self.pAllocCallBacks, @ptrCast(&self.device)));
    }

    fn createQueue(self: *Self) void {
        const families = [3]VkQueueFamily{ self.graphicQueueFamily, self.computeQueueFamily, self.transferQueueFamily };
        const queuess = [3][]VkTheadQueue{ self.graphicQueue[0..self.graphicQueue.len], self.computeQueue[0..self.computeQueue.len], self.transferQueue[0..self.transferQueue.len] };
        const crashList = [3][]usize{ self.graphicQueueCrashList[0..self.graphicQueueCrashList.len], self.computeQueueCrashList[0..self.computeQueueCrashList.len], self.transferQueueCrashList[0..self.transferQueueCrashList.len] };
        for (families, queuess, crashList) |family, queues, list| {
            if (family.familyIndice != -1) {
                for (0..queues.len) |i_usize| {
                    const i: u32 = @truncate(i_usize);
                    if (i < family.queueCount) {
                        vk.vkGetDeviceQueue(self.device, @bitCast(family.familyIndice), i, @ptrCast(&queues[i].queue));
                        queues[i].mutex = .{};
                        // std.debug.print("a queue\n", .{});
                    } else {
                        queues[i].queue = null;
                        // std.debug.print("a empty queue\n", .{});
                    }
                    list[i] = 0;
                }
            }
        }
    }

    fn createCommandPool(self: *Self, queueFamilyIndex: u32, pCommandPool: *vk.VkCommandPool) !void {
        var createInfo = vk.VkCommandPoolCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueFamilyIndex = queueFamilyIndex,
        };

        try checkVkResult(vk.vkCreateCommandPool(self.device, @ptrCast(&createInfo), self.pAllocCallBacks, @ptrCast(pCommandPool)));
    }

    pub fn collectEntryName(self: *Self, entryName: []const u8) !*[]const u8 {
        const ptr = @as([*c]const u8, entryName[0..64]);
        const len = std.mem.len(ptr);

        if (self.entryNames.contains(entryName[0..len])) {
            return self.entryNames.getKeyPtr(entryName[0..len]).?;
        }

        const name = try self.allocator.alloc(u8, len);
        @memcpy(name, entryName[0..len]);
        const res = try self.entryNames.getOrPutValue(name, void{});
        // @breakpoint();
        return res.key_ptr;
    }

    pub fn createShaderModule(self: *Self, shaderCode: []const u8, shaderName: []const u8) !vk.VkShaderModule {
        var res = try self.shaderModules.getOrPut(shaderName);

        if (!res.found_existing) {
            var info = vk.VkShaderModuleCreateInfo{
                .sType = vk.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .codeSize = shaderCode.len,
                .pCode = @ptrCast(@alignCast(shaderCode.ptr)),
            };
            const module = try self.allocator.create(vk.VkShaderModule);

            try checkVkResult(vk.vkCreateShaderModule(
                self.device,
                @ptrCast(&info),
                self.pAllocCallBacks,
                @ptrCast(module),
            ));
            res.value_ptr = module;
        }

        return res.value_ptr.*;
    }

    pub fn clearAllShaderModule(self: *Self) void {
        var shaderCodes = self.shaderModules.valueIterator();
        while (shaderCodes.next()) |code| {
            vk.vkDestroyShaderModule(self.device, code.*, self.pAllocCallBacks);
        }

        self.shaderModules.clearAndFree();
    }

    pub fn createDescriptorSetLayout(self: *Self, createInfo: vk.VkDescriptorSetLayoutCreateInfo) !vk.VkDescriptorSetLayout {
        var res: vk.VkDescriptorSetLayout = undefined;
        try checkVkResult(vk.vkCreateDescriptorSetLayout(self.device, @ptrCast(&createInfo), self.pAllocCallBacks, @ptrCast(&res)));
        return res;
    }

    pub fn destroyDescriptorSetLayout(self: *Self, descriptorSetLayout: vk.VkDescriptorSetLayout) void {
        vk.vkDestroyDescriptorSetLayout(self.device, descriptorSetLayout, self.pAllocCallBacks);
    }

    pub fn createPipelineLayout(self: *Self, createInfo: vk.VkPipelineLayoutCreateInfo) !vk.VkPipelineLayout {
        var res: vk.VkPipelineLayout = undefined;
        try checkVkResult(vk.vkCreatePipelineLayout(self.device, @ptrCast(&createInfo), self.pAllocCallBacks, @ptrCast(&res)));
        return res;
    }

    pub fn destroyPipelineLayout(self: *Self, pipelineLayout: vk.VkPipelineLayout) void {
        vk.vkDestroyPipelineLayout(self.device, pipelineLayout, self.pAllocCallBacks);
    }

    pub fn addPipelineCreateInfo(self: *Self, info: *VulkanPipelineInfo) !void {
        if (self.graphicInfoCount > self.graphicPipelineCreateInfo.len) {
            return error.OutOfCapacity;
        }
        var tempInfo = [1]VulkanPipelineInfo{info.*};
        @memcpy(self.preGraphicInfoPtrs[self.graphicInfoCount .. self.graphicInfoCount + 1], tempInfo[0..1]);
        self.graphicPipelineCreateInfo[self.graphicInfoCount] = vk.VkGraphicsPipelineCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
            .pNext = pn: {
                if (self.preGraphicInfoPtrs[self.graphicInfoCount].hasRendering) {
                    break :pn @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].renderingInfo.info);
                }
                break :pn null;
            },
            .flags = 0,
            .basePipelineHandle = null,
            .basePipelineIndex = -1,
            .layout = self.preGraphicInfoPtrs[self.graphicInfoCount].pipelineLayout.layout,
            .pColorBlendState = @ptrCast(
                &self.preGraphicInfoPtrs[self.graphicInfoCount].colorBlendInfo.createInfo,
            ),
            .pDepthStencilState = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].depthStencilInfo),
            .pDynamicState = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].dynamicStateInfo),
            .pInputAssemblyState = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].inputAssemblyInfo),
            .pMultisampleState = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].multisampleInfo),
            .pRasterizationState = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].rasterizationInfo),
            .pStages = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].shaderStageCreateInfo),
            .pTessellationState = tn: {
                if (self.preGraphicInfoPtrs[self.graphicInfoCount].haveTessella) {
                    break :tn @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].tessellationInfo);
                } else {
                    break :tn null;
                }
            },
            .pVertexInputState = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].vertexInputInfo.createInfo),
            .pViewportState = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].viewportInfo.info),
            .stageCount = @intCast(self.preGraphicInfoPtrs[self.graphicInfoCount].shaderStageCount),
            .renderPass = null,
            .subpass = 0,
        };
        self.graphicInfoCount += 1;
    }

    pub fn createAllPipelinesAdded(self: *Self) !void {
        var temp = [_]vk.VkPipeline{null} ** 10;

        try checkVkResult(vk.vkCreateGraphicsPipelines(
            self.device,
            self.pipelineCache,
            self.graphicInfoCount,
            @ptrCast(&self.graphicPipelineCreateInfo),
            self.pAllocCallBacks,
            @ptrCast(&temp),
        ));

        var pp: Pipeline = undefined;
        for (0..self.graphicInfoCount) |i| {
            pp = Pipeline{
                .descriptorSetLayouts = self.preGraphicInfoPtrs[i].descriptorSetLayouts.setLayouts,
                .setCount = self.preGraphicInfoPtrs[i].descriptorSetLayouts.setLayoutCount,
                .pipelineLayout = self.preGraphicInfoPtrs[i].pipelineLayout.layout,
                .pipeline = temp[i],
            };
            try self.pipelines.put(&self.preGraphicInfoPtrs[i].name, pp);
        }
        self.graphicInfoCount = 0;
    }

    pub fn destroyPipeline(self: *Self, name: []const u8) !void {
        const kv = self.pipelines.fetchRemove(name);
        if (kv) |val| {
            try checkVkResult(vk.vkDestroyPipeline(self.device, val.value.pipeline, self.pAllocCallBacks));
            try checkVkResult(vk.vkDestroyPipelineLayout(self.device, val.value.pipelineLayout, self.pAllocCallBacks));
            for (0..val.value.setCount) |i| {
                try checkVkResult(vk.vkDestroyDescriptorSetLayout(
                    self.device,
                    val.value.descriptorSetLayouts[i],
                    self.pAllocCallBacks,
                ));
            }
        }
    }
};
