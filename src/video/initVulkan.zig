const vk = @cImport(@cInclude("vulkan/vulkan.h"));
const sdl = @cImport(@cInclude("SDL3/SDL_namespace.h"));
const std = @import("std");
const output = @import("output");
const Allocator = @import("std").mem.Allocator;
const VkError = @import("vulkanType.zig").VkError;
const VkResult = @import("vulkanType.zig").VkResult;
const VkPhysicalType = @import("vulkanType.zig").VkPhysicalDeviceType;
const VkResultToError = @import("resultToError.zig");
const Mutex = std.Thread.Mutex;
const builtin = @import("builtin");

const layerNeeded = layer: {
    break :layer switch (builtin.mode) {
        .Debug, .ReleaseSafe => [_][*c]const u8{"VK_LAYER_KHRONOS_validation"},
        .ReleaseFast, .ReleaseSmall => [_][*c]const u8{},
    };
};
const extensionNeeded = [_][*c]const u8{ "VK_KHR_surface", "VK_KHR_win32_surface" };
const deviceExtensionNeeded = [_][*c]const u8{ "VK_KHR_swapchain", "VK_EXT_descriptor_indexing", "VK_KHR_maintenance3", "VK_KHR_synchronization2", "VK_KHR_timeline_semaphore", "VK_KHR_dynamic_rendering", "VK_EXT_extended_dynamic_state" };
const featureNeed = [_][]const u8{ "geometryShader", "independentBlend", "samplerAnisotropy", "logicOp", "depthClamp", "depthBiasClamp", "wideLines" };
const featureIndexingNeed = [_][]const u8{
    "shaderUniformBufferArrayNonUniformIndexing",
    "shaderStorageBufferArrayNonUniformIndexing",
    "shaderSampledImageArrayNonUniformIndexing",
    "descriptorBindingPartiallyBound",
    "runtimeDescriptorArray",
};
const featureTimelineSemaphoreNeed = [_][]const u8{"timelineSemaphore"};

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

    if (sdl.SDL_ShowSimpleMessageBox(sdl.SDL_MESSAGEBOX_ERROR, "memory alloc failed", @ptrCast(buffers.ptr), window) == false) {
        std.log.warn("show message box failed", .{});
    }
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

pub const VkStruct = struct {
    const Self = @This();

    allocator: Allocator = undefined,
    allocCallBacks: vk.VkAllocationCallbacks = undefined,
    pAllocCallBacks: [*c]vk.VkAllocationCallbacks = null,
    window: *sdl.SDL_Window = undefined,
    instance: vk.VkInstance = null,
    surface: vk.VkSurfaceKHR = null,
    physicalDevice: vk.VkPhysicalDevice = null,
    device: vk.VkDevice = null,
    graphicQueueFamily: VkQueueFamily = .{},
    graphicQueue: [16]VkTheadQueue = undefined,
    computeQueueFamily: VkQueueFamily = .{},
    computeQueue: [16]VkTheadQueue = undefined,
    transferQueueFamily: VkQueueFamily = .{},
    transferQueue: [8]VkTheadQueue = undefined,

    pub fn init(allocator: Allocator) VkStruct {
        return VkStruct{ .allocator = allocator };
    }

    pub fn initVulkan(self: *Self) VkError!void {
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

    fn chooseEnabledLayers(self: *Self, comptime fields: type, comptime field_name: []const u8, neededName: []const [*c]const u8, physicalDevice: vk.VkPhysicalDevice) VkError!std.ArrayList([*c]const u8) {
        var namesEnabled = std.ArrayList([*c]const u8).init(self.*.allocator);

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

    fn createSurface(self: *Self) VkError!void {
        if (sdl.SDL_Vulkan_CreateSurface(self.*.window, @ptrCast(self.*.instance), @ptrCast(self.*.pAllocCallBacks), @ptrCast(&self.*.surface)) == false) {
            std.debug.print("SDL error: {s}\n", .{sdl.SDL_GetError()});
            return VkError.VK_ERROR_UNKNOWN;
        }
    }

    fn pickPhysicalDevice(self: *Self) VkError!void {
        var deviceCount: u32 = 0;
        try checkVkResult(vk.vkEnumeratePhysicalDevices(self.*.instance, @ptrCast(&deviceCount), null));
        if (deviceCount == 0) {
            if (sdl.SDL_ShowSimpleMessageBox(sdl.SDL_MESSAGEBOX_ERROR, "vulkan not support", "you device is not support vulkan", self.*.window) == false) {
                std.log.err("show message box failed", .{});
            }
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
                var deviceFeatures2: vk.VkPhysicalDeviceFeatures2 = undefined;
                var indexingFeature: vk.VkPhysicalDeviceDescriptorIndexingFeatures = undefined;
                var timelineFeature: vk.VkPhysicalDeviceTimelineSemaphoreFeatures = undefined;
                timelineFeature.sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES;
                timelineFeature.pNext = null;
                indexingFeature.sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES;
                indexingFeature.pNext = &timelineFeature;
                deviceFeatures2.sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
                deviceFeatures2.pNext = &indexingFeature;

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

                if (featureSupported and featureIndexingSupported and featureTimelineSemaphoreSupported) {
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

    fn setQueueFamilies(self: *Self) VkError!void {
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
            sparse = false;
            encode = false;
            decode = false;
            if (queueFamily.queueFlags & vk.VK_QUEUE_GRAPHICS_BIT != 0) {
                graphic = true;
            }
            if (queueFamily.queueFlags & vk.VK_QUEUE_COMPUTE_BIT != 0) {
                compute = true;
            }
            if (queueFamily.queueFlags & vk.VK_QUEUE_TRANSFER_BIT != 0) {
                transfer = true;
            }
            if (queueFamily.queueFlags & vk.VK_QUEUE_SPARSE_BINDING_BIT != 0) {
                sparse = true;
            }
            if (queueFamily.queueFlags & vk.VK_QUEUE_VIDEO_ENCODE_BIT_KHR != 0) {
                encode = true;
            }
            if (queueFamily.queueFlags & vk.VK_QUEUE_VIDEO_DECODE_BIT_KHR != 0) {
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
            }

            if (compute and !graphic) {
                self.computeQueueFamily.familyIndice = i_i32;
                self.computeQueueFamily.queueCount = queueFamily.queueCount;
            }

            if (transfer and !graphic and !compute and !decode and !encode) {
                self.transferQueueFamily.familyIndice = i_i32;
            }
        }
    }
    fn createDevice(self: *Self) VkError!void {
        var timelineSemaphoreFeature = vk.VkPhysicalDeviceTimelineSemaphoreFeatures{
            .sType = vk.VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES,
            .pNext = null,
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
        if (self.graphicQueueFamily.familyIndice != -1) {
            for (0..self.graphicQueueFamily.queueCount) |i_usize| {
                const i: u32 = @truncate(i_usize);
                vk.vkGetDeviceQueue(self.device, @bitCast(self.graphicQueueFamily.familyIndice), i, @ptrCast(&self.graphicQueue[i]));
            }
        }
        if (self.computeQueueFamily.familyIndice != -1) {
            for (0..self.computeQueueFamily.queueCount) |i_usize| {
                const i: u32 = @truncate(i_usize);
                vk.vkGetDeviceQueue(self.device, @bitCast(self.computeQueueFamily.familyIndice), i, @ptrCast(&self.computeQueue[i]));
            }
        }
        if (self.transferQueueFamily.familyIndice != -1) {
            for (0..self.transferQueueFamily.queueCount) |i_usize| {
                const i: u32 = @truncate(i_usize);
                vk.vkGetDeviceQueue(self.device, @bitCast(self.transferQueueFamily.familyIndice), i, @ptrCast(&self.transferQueue[i]));
            }
        }
    }
};
