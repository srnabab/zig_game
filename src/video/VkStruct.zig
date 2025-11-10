const vk = @import("vulkan").vulkan;
const sdl = @import("sdl").sdl;
const SDL_CheckResult = @import("sdlError").SDL_CheckResult;
const std = @import("std");
const builtin = @import("builtin");
const Mutex = std.Thread.Mutex;
const Thread = std.Thread;
const output = @import("output");
const Allocator = std.mem.Allocator;
const vulkanType = @import("vulkanType.zig");
pub const VkError = vulkanType.VkError;
const VkResult = vulkanType.VkResult;
const VkPhysicalType = vulkanType.VkPhysicalDeviceType;
const VkResultToError = @import("resultToError.zig");
const VulkanPipelineInfo = @import("translate").VulkanPipelineInfo;
const textureSet = @import("textureSet");
const vma = @import("vma").vma;
const tracy = @import("tracy");
const file = @import("fileSystem");
const translate = @import("translate");
const samplerRead = @import("sampler");
const math = @import("math");

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
    "descriptorBindingUniformBufferUpdateAfterBind",
    "descriptorBindingSampledImageUpdateAfterBind",
    "descriptorBindingPartiallyBound",
    "runtimeDescriptorArray",
};
const featureTimelineSemaphoreNeed = [_][]const u8{"timelineSemaphore"};
const featureDynamicRenderingNeed = [_][]const u8{"dynamicRendering"};

const DefaultWindowWidth = 800;
const DefaultWindowHeight = 600;

const BufferAlign = 16;

const DefaultSurfaceFormat = vk.VkSurfaceFormatKHR{
    .colorSpace = vk.VK_COLOR_SPACE_SRGB_NONLINEAR_KHR,
    .format = vk.VK_FORMAT_R8G8B8A8_SRGB,
};

const globalDescriptorPoolSizes = [_]vk.VkDescriptorPoolSize{
    .{ .type = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, .descriptorCount = 2048 },
    .{ .type = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, .descriptorCount = 100 },
};
const globalDescriptorMaxSets = 10;

const descriptorSetLayoutCreateInfo = struct {
    flag: vk.VkDescriptorSetLayoutCreateFlags,
    bindingCount: u32,
    bindings: [5]vk.VkDescriptorSetLayoutBinding,
    bindingFlags: [5]vk.VkDescriptorBindingFlags,
};
const set0SetLayoutCreateInfos = descriptorSetLayoutCreateInfo{
    .flag = 0,
    .bindingCount = 1,
    .bindings = [5]vk.VkDescriptorSetLayoutBinding{
        .{
            .binding = 0,
            .stageFlags = vk.VK_SHADER_STAGE_VERTEX_BIT,
            .descriptorType = vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
            .descriptorCount = 1,
        },
        .{},
        .{},
        .{},
        .{},
    },
    .bindingFlags = [5]vk.VkDescriptorBindingFlags{
        0,
        0,
        0,
        0,
        0,
    },
};
const set1SetLayoutCreateInfos = descriptorSetLayoutCreateInfo{
    .flag = vk.VK_DESCRIPTOR_SET_LAYOUT_CREATE_UPDATE_AFTER_BIND_POOL_BIT,
    .bindingCount = 1,
    .bindings = [5]vk.VkDescriptorSetLayoutBinding{
        .{
            .binding = 0,
            .stageFlags = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
            .descriptorType = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
            .descriptorCount = 1024,
        },
        .{},
        .{},
        .{},
        .{},
    },
    .bindingFlags = [5]vk.VkDescriptorBindingFlags{
        vk.VK_DESCRIPTOR_BINDING_PARTIALLY_BOUND_BIT | vk.VK_DESCRIPTOR_BINDING_UPDATE_AFTER_BIND_BIT,
        0,
        0,
        0,
        0,
    },
};
const globalTextureBinding = 0;

const VkQueueFamily = struct {
    familyIndice: i32 = -1,
    queueCount: u32 = 0,
};
const VkTheadQueue = struct { queue: vk.VkQueue = null, mutex: Mutex = .{} };

const setLayoutLimit = @import("translate").setLayoutLimit;
pub const Pipeline = struct {
    // descriptorSetLayouts: [setLayoutLimit]vk.VkDescriptorSetLayout,
    setCount: u32,
    vertexBindingCount: u32,
    pipelineLayout: vk.VkPipelineLayout,
    pipeline: vk.VkPipeline,
};

pub const Buffer = struct {
    vkBuffer: vk.VkBuffer,
    allocation: vma.VmaAllocation,
    // info: vma.VmaAllocationInfo,
    size: vk.VkDeviceSize,
    pMappedData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    queueIndex: CommandPoolType = .init,

    pub fn changeQueueIndex(self: *Buffer, queueType: CommandPoolType) void {
        self.queueIndex = queueType;
    }
};
pub const Image = struct {
    vkImage: vk.VkImage,
    allocation: vma.VmaAllocation,
    queueIndex: i32 = -1,
};

const CommandPool = struct {
    commandPool: vk.VkCommandPool = null,
    queueFamilyIndex: i32 = -1,
};

const InitLayout = enum {
    VK_IMAGE_LAYOUT_UNDEFINED,
    VK_IMAGE_LAYOUT_PREINITIALIZED,
};

const AllocationCount = struct {
    const Count = @This();

    const mode = if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) true else false;
    const returnType = if (mode) u64 else void;

    count: if (mode) std.atomic.Value(u64) else void =
        if (mode) .init(0) else void{},

    pub fn fetchAdd(self: *Count, operand: u64, comptime order: std.builtin.AtomicOrder) returnType {
        if (mode) return self.count.fetchAdd(operand, order);
    }

    pub fn fetchSub(self: *Count, operand: u64, comptime order: std.builtin.AtomicOrder) returnType {
        if (mode) return self.count.fetchSub(operand, order);
    }

    pub fn load(sefl: *Count, comptime order: std.builtin.AtomicOrder) returnType {
        if (mode) return sefl.count.load(order);
    }
};
const Self = @This();

const bufferRatio: f32 = 0.5 / 11;

pub const SamplerType = enum {
    pixel2d,
};

pixel2dSampler: vk.VkSampler = null,

currentFrame: std.atomic.Value(u32) = .init(0),

allocator: Allocator,
allocCallBacks: vk.VkAllocationCallbacks = undefined,
pAllocCallBacks: [*c]vk.VkAllocationCallbacks = null,

window: *sdl.SDL_Window = undefined,
windowWidth: u32 = 0,
windowsHeight: u32 = 0,

instance: vk.VkInstance = null,
surface: vk.VkSurfaceKHR = null,

surfaceFormat: vk.VkSurfaceFormatKHR = .{},
presentMode: vk.VkPresentModeKHR = 0,

physicalDeviceMemoryCount: u64 = 0,
physicalDevice: vk.VkPhysicalDevice = null,
device: vk.VkDevice = null,

swapchain: vk.VkSwapchainKHR = null,

vmaAllocator: vma.VmaAllocator = null,

graphicQueueFamily: VkQueueFamily = .{},
graphicQueue: VkTheadQueue = .{},
computeQueueFamily: VkQueueFamily = .{},
computeQueue: VkTheadQueue = .{},
transferQueueFamily: VkQueueFamily = .{},
transferQueue: VkTheadQueue = .{},

shaderModules: std.StringHashMap(vk.VkShaderModule),
entryNames: std.StringHashMap(void),

pipelineCache: vk.VkPipelineCache = null,

graphicPipelineCreateInfo: [10]vk.VkGraphicsPipelineCreateInfo = undefined,
preGraphicInfoPtrs: [10]VulkanPipelineInfo = undefined,
graphicInfoCount: u32 = 0,

pipelines: std.StringHashMap(Pipeline),

/// binary semaphore
imageAvailableSemaphore: [2]vk.VkSemaphore = undefined,
/// binary semaphore
renderFinishSemaphore: [2]vk.VkSemaphore = undefined,
globalTimelineSemaphore: vk.VkSemaphore = null,
globalTimelineValue: std.atomic.Value(u64) = .init(0),

textureSets: textureSet,

vmaBufferAllocations: AllocationCount = .{},
vmaImageAllocations: AllocationCount = .{},

globalDescriptorPool: vk.VkDescriptorPool = null,

descriptorSetLayout: [2]vk.VkDescriptorSetLayout = undefined,

globalFixed2dMVPMatrixDescriptorSet: vk.VkDescriptorSet = null,
global2dMVPMatrixDescriptorSet: vk.VkDescriptorSet = null,
global3dMVPMatrixDescriptorSet: vk.VkDescriptorSet = null,
globalTextureDescriptorSet: vk.VkDescriptorSet = null,

vertexBuffer2d: Buffer = undefined,
vertexBuffer3d: Buffer = undefined,

indexBuffer2d: Buffer = undefined,
indexBuffer3d: Buffer = undefined,

writeDescriptorSets: std.array_list.Managed(vk.VkWriteDescriptorSet) = undefined,
descriptorImageInfos: std.array_list.Managed(vk.VkDescriptorImageInfo) = undefined,
descriptorBufferInfos: std.array_list.Managed(vk.VkDescriptorBufferInfo) = undefined,
descriptorBufferViewInfos: std.array_list.Managed(vk.VkBufferView) = undefined,

pub fn init(allocator: Allocator) Self {
    return Self{
        .allocator = allocator,
        .shaderModules = .init(allocator),
        .entryNames = .init(allocator),
        .pipelines = .init(allocator),
        .textureSets = .init(allocator),
        .writeDescriptorSets = .init(allocator),
        .descriptorImageInfos = .init(allocator),
        .descriptorBufferInfos = .init(allocator),
        .descriptorBufferViewInfos = .init(allocator),
    };
}

pub fn initVulkan(self: *Self) !void {
    const zone = tracy.initZone(@src(), .{ .name = "init vulkan resources" });
    defer zone.deinit();

    try self.*.createWindow();
    const version = try getVulkanVersion();
    printVersion(version);
    try self.createInstance();
    try self.createSurface();
    try self.pickPhysicalDevice();
    try self.setQueueFamilies();
    try self.createDevice();
    self.createQueue();
    try self.createVmaAllocator();

    var semaphores: [4]vk.VkSemaphore = undefined;
    try self.createBinarySemaphore(0, &semaphores);
    self.imageAvailableSemaphore[0] = semaphores[0];
    self.imageAvailableSemaphore[1] = semaphores[1];
    self.renderFinishSemaphore[0] = semaphores[2];
    self.renderFinishSemaphore[1] = semaphores[3];
    var semaphores2: [1]vk.VkSemaphore = undefined;
    try self.createTimelineSemaphore(0, &semaphores2, 0);
    self.globalTimelineSemaphore = semaphores2[0];

    self.surfaceFormat = try self.getSurfaceFormat();
    self.presentMode = try self.getPresentMode();
    self.swapchain = try self.createSwapchain();

    self.globalDescriptorPool = try self._createDescriptorPool(vk.VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT, @constCast(&globalDescriptorPoolSizes), globalDescriptorMaxSets);

    self.descriptorSetLayout[0] = try self.createDescriptorSetLayout(null, set0SetLayoutCreateInfos.flag, set0SetLayoutCreateInfos.bindingCount, @constCast(&set0SetLayoutCreateInfos.bindings));
    var bindingFlagsInfo = vk.VkDescriptorSetLayoutBindingFlagsCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO,
        .pNext = null,
        .bindingCount = set1SetLayoutCreateInfos.bindingCount,
        .pBindingFlags = &set1SetLayoutCreateInfos.bindingFlags,
    };
    self.descriptorSetLayout[1] = try self.createDescriptorSetLayout(&bindingFlagsInfo, set1SetLayoutCreateInfos.flag, set1SetLayoutCreateInfos.bindingCount, @constCast(&set1SetLayoutCreateInfos.bindings));

    var set0Sets: [3]vk.VkDescriptorSet = undefined;
    var set0Setlayout = [_]vk.VkDescriptorSetLayout{ self.descriptorSetLayout[0], self.descriptorSetLayout[0], self.descriptorSetLayout[0] };
    try self.allocateDescriptorSets(self.globalDescriptorPool, &set0Setlayout, &set0Sets);

    self.globalFixed2dMVPMatrixDescriptorSet = set0Sets[0];
    self.global2dMVPMatrixDescriptorSet = set0Sets[1];
    self.global3dMVPMatrixDescriptorSet = set0Sets[2];

    var set1Sets: [1]vk.VkDescriptorSet = undefined;
    var set1Setlayout = [_]vk.VkDescriptorSetLayout{self.descriptorSetLayout[1]};
    try self.allocateDescriptorSets(self.globalDescriptorPool, &set1Setlayout, &set1Sets);

    self.globalTextureDescriptorSet = set1Sets[0];

    try self.initSamplers();
}

pub fn deinit(self: *Self) void {
    self.waitDevice() catch |err| {
        std.log.err("wait device error {s}\n", .{@errorName(err)});
    };

    // self.vmaStatistics();

    const zone = tracy.initZone(@src(), .{ .name = "deinit vulkan resources" });
    defer zone.deinit();

    self.destroySamplers();

    self.writeDescriptorSets.deinit();
    self.descriptorImageInfos.deinit();
    self.descriptorBufferInfos.deinit();
    self.descriptorBufferViewInfos.deinit();

    for (self.descriptorSetLayout) |value| {
        self.destroyDescriptorSetLayout(value);
    }

    self.destroyDescriptorPool(self.globalDescriptorPool);

    var pipelines = self.pipelines.iterator();
    while (pipelines.next()) |val| {
        vk.vkDestroyPipeline(self.device, val.value_ptr.pipeline, self.pAllocCallBacks);
        vk.vkDestroyPipelineLayout(self.device, val.value_ptr.pipelineLayout, self.pAllocCallBacks);
        self.allocator.free(val.key_ptr.*);
        // for (0..val.setCount) |i| {
        //     vk.vkDestroyDescriptorSetLayout(
        //         self.device,
        //         val.descriptorSetLayouts[i],
        //         self.pAllocCallBacks,
        //     );
        // }
    }
    self.pipelines.deinit();

    var entryNames = self.entryNames.iterator();
    while (entryNames.next()) |name| {
        self.allocator.free(name.key_ptr.*);
    }
    self.entryNames.deinit();

    var shaderCodes = self.shaderModules.iterator();
    while (shaderCodes.next()) |code| {
        // std.log.debug("module ptr {*}", .{code.value_ptr});
        vk.vkDestroyShaderModule(self.device, code.value_ptr.*, self.pAllocCallBacks);
    }
    self.shaderModules.deinit();

    self.destroySwapchain(self.swapchain);

    for (self.renderFinishSemaphore) |value| {
        self.destroySemaphore(value);
    }
    for (self.imageAvailableSemaphore) |value| {
        self.destroySemaphore(value);
    }
    self.destroySemaphore(self.globalTimelineSemaphore);

    std.log.debug("vma buffer allocation residue count: {d}", .{self.vmaBufferAllocations.load(.seq_cst)});
    std.log.debug("vma image allocation residue count: {d}", .{self.vmaImageAllocations.load(.seq_cst)});
    vma.vmaDestroyAllocator(self.vmaAllocator);

    vk.vkDestroyDevice(self.device, self.pAllocCallBacks);
    sdl.SDL_Vulkan_DestroySurface(@ptrCast(self.*.instance), @ptrCast(self.*.surface), @ptrCast(self.*.pAllocCallBacks));
    vk.vkDestroyInstance(self.*.instance, self.*.pAllocCallBacks);
    sdl.SDL_DestroyWindow(self.*.window);
}

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

fn createWindow(self: *Self) !void {
    const zone = tracy.initZone(@src(), .{ .name = "create window" });
    defer zone.deinit();

    const width = w: {
        if (self.windowWidth == 0) self.windowWidth = DefaultWindowWidth;
        break :w self.windowWidth;
    };

    const height = h: {
        if (self.windowsHeight == 0) self.windowsHeight = DefaultWindowHeight;
        break :h self.windowsHeight;
    };
    const temp = sdl.SDL_CreateWindow("window", @intCast(width), @intCast(height), sdl.SDL_WINDOW_VULKAN);
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
    const zone = tracy.initZone(@src(), .{ .name = "get vulkan version" });
    defer zone.deinit();

    var apiVersion: c_uint = 0;
    try checkVkResult(vk.vkEnumerateInstanceVersion(&apiVersion));

    return apiVersion;
}

fn printVersion(apiVersion: u32) void {
    const major = vk.VK_VERSION_MAJOR(apiVersion);
    const minor = vk.VK_VERSION_MINOR(apiVersion);
    const patch = vk.VK_VERSION_PATCH(apiVersion);

    std.log.debug("Vulkan API Version: {d}.{d}.{d}", .{ major, minor, patch });
}

fn createInstance(self: *Self) VkError!void {
    const zone = tracy.initZone(@src(), .{ .name = "create instance" });
    defer zone.deinit();

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
    const zone = tracy.initZone(@src(), .{ .name = "create surface" });
    defer zone.deinit();

    try SDL_CheckResult(sdl.SDL_Vulkan_CreateSurface(self.*.window, @ptrCast(self.*.instance), @ptrCast(self.*.pAllocCallBacks), @ptrCast(&self.*.surface)));
}

fn pickPhysicalDevice(self: *Self) !void {
    const zone = tracy.initZone(@src(), .{ .name = "pick physical device" });
    defer zone.deinit();

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
    std.log.debug("device count: {d}", .{deviceCount});
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

                        std.log.debug("device: choosed {s}", .{@tagName(@as(VkPhysicalType, @enumFromInt(deviceProperty.deviceType)))});
                    },
                    vk.VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU => {
                        if (self.*.physicalDevice == null) {
                            self.*.physicalDevice = devicee;
                            biggestMemory = @max(biggestMemory, memoryCount);

                            std.log.debug("device: choosed {s}", .{@tagName(@as(VkPhysicalType, @enumFromInt(deviceProperty.deviceType)))});
                        }
                    },
                    else => {
                        // TODO add warn message box
                        return VkError.VK_ERROR_UNKNOWN;
                    },
                }
            } else {}
        } else {}
    }

    self.physicalDeviceMemoryCount = biggestMemory;
    std.log.debug("gpu memory: {d} GB", .{@as(f64, @floatFromInt(self.physicalDeviceMemoryCount)) / (1024 * 1024 * 1024)});
}

fn setQueueFamilies(self: *Self) !void {
    const zone = tracy.initZone(@src(), .{ .name = "set queue families" });
    defer zone.deinit();

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
    const zone = tracy.initZone(@src(), .{ .name = "create logical device" });
    defer zone.deinit();

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

fn createVmaAllocator(self: *Self) !void {
    const zone = tracy.initZone(@src(), .{ .name = "create vma allocator" });
    defer zone.deinit();

    var allocatorCreateInfo = vma.VmaAllocatorCreateInfo{
        .flags = 0,
        .physicalDevice = @ptrCast(self.physicalDevice),
        .device = @ptrCast(self.device),
        .pAllocationCallbacks = @ptrCast(self.pAllocCallBacks),
        .instance = @ptrCast(self.instance),
        .vulkanApiVersion = vk.VK_API_VERSION_1_4,
    };

    try checkVkResult(vma.vmaCreateAllocator(@ptrCast(&allocatorCreateInfo), @ptrCast(&self.vmaAllocator)));
}

fn _createBuffer(
    self: *Self,
    flags: u32,
    pNext: ?*anyopaque,
    sharingMode: vk.VkSharingMode,
    bufferSize: vk.VkDeviceSize,
    usage: vk.VkBufferUsageFlags,
    vmaFlags: u32,
    vmaUsage: vma.VmaMemoryUsage,
) VkError!Buffer {
    var bufferCreateInfo = vk.VkBufferCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .flags = flags,
        .pNext = pNext,
        .sharingMode = sharingMode,
        .size = bufferSize,
        .usage = usage,
    };

    var allocationCreateInfo = vma.VmaAllocationCreateInfo{
        .flags = vmaFlags,
        .usage = vmaUsage,
    };

    var pBuffer: vk.VkBuffer = null;
    var pAllocation: vma.VmaAllocation = null;
    var allocationInfo = vma.VmaAllocationInfo{};

    try checkVkResult(vma.vmaCreateBuffer(self.vmaAllocator, @ptrCast(&bufferCreateInfo), @ptrCast(&allocationCreateInfo), @ptrCast(&pBuffer), @ptrCast(&pAllocation), @ptrCast(&allocationInfo)));

    _ = self.vmaBufferAllocations.fetchAdd(1, .seq_cst);

    return Buffer{
        .vkBuffer = pBuffer,
        .allocation = pAllocation,
        // .info = allocationInfo,
        .size = allocationInfo.size,
        .pMappedData = allocationInfo.pMappedData,
        .queueIndex = .init,
    };
}

pub fn destroyBuffer(self: *Self, buffer: Buffer) void {
    const zone = tracy.initZone(@src(), .{ .name = "destroy buffer" });
    defer zone.deinit();

    _ = self.vmaBufferAllocations.fetchSub(1, .seq_cst);

    vma.vmaDestroyBuffer(self.vmaAllocator, @ptrCast(buffer.vkBuffer), buffer.allocation);
}

pub fn createStagingBuffer(self: *Self, bufferSize: vk.VkDeviceSize) VkError!Buffer {
    const zone = tracy.initZone(@src(), .{ .name = "create staging buffer" });
    defer zone.deinit();

    return self._createBuffer(
        0,
        null,
        vk.VK_SHARING_MODE_EXCLUSIVE,
        @intCast(math.round(BufferAlign, @intCast(bufferSize))),
        vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        vma.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | vma.VMA_ALLOCATION_CREATE_MAPPED_BIT,
        vma.VMA_MEMORY_USAGE_CPU_TO_GPU,
    );
}

pub fn createVertexBuffer(self: *Self, bufferSize: vk.VkDeviceSize) VkError!Buffer {
    const zone = tracy.initZone(@src(), .{ .name = "create vertex buffer" });
    defer zone.deinit();

    return self._createBuffer(
        0,
        null,
        vk.VK_SHARING_MODE_EXCLUSIVE,
        @intCast(math.round(BufferAlign, bufferSize)),
        vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT,
        vma.VMA_ALLOCATION_CREATE_HOST_ACCESS_RANDOM_BIT,
        vma.VMA_MEMORY_USAGE_GPU_ONLY,
    );
}

fn createQueue(self: *Self) void {
    const zone = tracy.initZone(@src(), .{ .name = "create queues" });
    defer zone.deinit();

    const families = [3]*VkQueueFamily{ &self.graphicQueueFamily, &self.computeQueueFamily, &self.transferQueueFamily };
    const queuess = [3]*VkTheadQueue{ &self.graphicQueue, &self.computeQueue, &self.transferQueue };
    for (families, queuess) |family, queues| {
        if (family.familyIndice != -1) {
            vk.vkGetDeviceQueue(self.device, @bitCast(family.familyIndice), @intCast(family.familyIndice), @ptrCast(&queues.queue));
        } else {
            family.familyIndice = families[0].familyIndice;
        }
    }
}

pub const CommandPoolType = enum {
    graphic,
    compute,
    transfer,
    init,
};
pub fn _createCommandPool(self: *Self, pNext: ?*anyopaque, cpType: CommandPoolType, flags: u32, pCommandPool: *vk.VkCommandPool) !void {
    var createInfo = vk.VkCommandPoolCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .pNext = pNext,
        .flags = flags,
        .queueFamilyIndex = @intCast(
            switch (cpType) {
                .graphic => self.graphicQueueFamily.familyIndice,
                .compute => self.computeQueueFamily.familyIndice,
                .transfer => self.transferQueueFamily.familyIndice,
                .init => unreachable,
            },
        ),
    };

    try checkVkResult(vk.vkCreateCommandPool(self.device, @ptrCast(&createInfo), self.pAllocCallBacks, @ptrCast(pCommandPool)));
}

pub fn destroyCommandPool(self: *Self, commandPool: vk.VkCommandPool) void {
    vk.vkDestroyCommandPool(self.device, commandPool, self.pAllocCallBacks);
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
    // std.log.debug("entry name {s}", .{res.key_ptr.*});
    // @breakpoint();
    return res.key_ptr;
}

pub fn createShaderModule(self: *Self, shaderCode: []const u8, shaderName: []const u8) !vk.VkShaderModule {
    const res = try self.shaderModules.getOrPut(shaderName);

    if (!res.found_existing) {
        var info = vk.VkShaderModuleCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .codeSize = shaderCode.len,
            .pCode = @ptrCast(@alignCast(shaderCode.ptr)),
        };

        try checkVkResult(vk.vkCreateShaderModule(
            self.device,
            @ptrCast(&info),
            self.pAllocCallBacks,
            @ptrCast(res.value_ptr),
        ));
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

pub fn createDescriptorSetLayout(self: *Self, pNext: ?*anyopaque, flags: vk.VkDescriptorSetLayoutCreateFlags, bindingCount: u32, pBindings: [*]vk.VkDescriptorSetLayoutBinding) !vk.VkDescriptorSetLayout {
    var setLayoutCreateInfo = vk.VkDescriptorSetLayoutCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO,
        .pNext = pNext,
        .flags = flags,
        .bindingCount = bindingCount,
        .pBindings = @ptrCast(pBindings),
    };
    var res: vk.VkDescriptorSetLayout = undefined;
    try checkVkResult(vk.vkCreateDescriptorSetLayout(self.device, @ptrCast(&setLayoutCreateInfo), self.pAllocCallBacks, @ptrCast(&res)));
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
    const zone = tracy.initZone(@src(), .{ .name = "add pipeline create info" });
    defer zone.deinit();

    if (self.graphicInfoCount > self.graphicPipelineCreateInfo.len) {
        return error.OutOfCapacity;
    }
    var tempInfo = [1]VulkanPipelineInfo{info.*};
    @memcpy(self.preGraphicInfoPtrs[self.graphicInfoCount .. self.graphicInfoCount + 1], tempInfo[0..1]);

    self.preGraphicInfoPtrs[self.graphicInfoCount].vertexInputInfo.createInfo.pVertexAttributeDescriptions = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].vertexInputInfo.attributes);
    self.preGraphicInfoPtrs[self.graphicInfoCount].vertexInputInfo.createInfo.pVertexBindingDescriptions = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].vertexInputInfo.bindings);

    self.preGraphicInfoPtrs[self.graphicInfoCount].viewportInfo.info.pScissors = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].viewportInfo.scissors);
    self.preGraphicInfoPtrs[self.graphicInfoCount].viewportInfo.info.pViewports = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].viewportInfo.viewports);

    self.preGraphicInfoPtrs[self.graphicInfoCount].colorBlendInfo.createInfo.pAttachments = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].colorBlendInfo.attachments);

    self.preGraphicInfoPtrs[self.graphicInfoCount].dynamicStateInfo.createInfo.pDynamicStates = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].dynamicStateInfo.states);

    if (self.preGraphicInfoPtrs[self.graphicInfoCount].hasRendering) {
        self.preGraphicInfoPtrs[self.graphicInfoCount].renderingInfo.info.pColorAttachmentFormats = @ptrCast(&self.preGraphicInfoPtrs[self.graphicInfoCount].renderingInfo.colorAttachment);
    }

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
    const zone = tracy.initZone(@src(), .{ .name = "create pipelines" });
    defer zone.deinit();

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
            .vertexBindingCount = self.preGraphicInfoPtrs[i].vertexInputInfo.bindingCount,
            .setCount = self.preGraphicInfoPtrs[i].pipelineCreateInfoInfo.setLayoutCount,
            .pipelineLayout = self.preGraphicInfoPtrs[i].pipelineLayout.layout,
            .pipeline = temp[i],
        };
        const len = std.mem.len(@as([*c]u8, @ptrCast(&self.preGraphicInfoPtrs[i].name)));
        const name = try self.allocator.alloc(u8, len);
        @memcpy(name, self.preGraphicInfoPtrs[i].name[0..len]);

        try self.pipelines.put(name, pp);
        std.log.debug("{s}", .{self.preGraphicInfoPtrs[i].name});
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

fn findMemoryType(self: *Self, typeFilter: u32, properties: vk.VkMemoryPropertyFlags) i32 {
    var memProperties = vk.VkPhysicalDeviceMemoryProperties{0};
    vk.vkGetPhysicalDeviceMemoryProperties(self.physicalDevice, @ptrCast(&memProperties));
    for (0..memProperties.memoryTypeCount) |i| {
        if ((typeFilter & (i << i)) and (memProperties.memoryTypes[i].propertyFlags & properties))
            return i;
    }

    return -1;
}
fn _createVkImage(
    self: *Self,
    pNext: ?*anyopaque,
    flags: vk.VkImageCreateFlags,
    imageType: vk.VkImageType,
    format: vk.VkFormat,
    extent: vk.VkExtent3D,
    mipLevels: u32,
    arrayLayers: u32,
    samples: vk.VkSampleCountFlagBits,
    tiling: vk.VkImageTiling,
    usage: vk.VkImageUsageFlags,
    sharingMode: vk.VkSharingMode,
    queueFamilyIndexCount: u32,
    pQueueFamilyIndices: [*c]u32,
    initialLayout: InitLayout,
) VkError!Image {
    const zone = tracy.initZone(@src(), .{ .name = "create Vkimage from vma" });
    defer zone.deinit();

    // std.log.debug("vma alloc", .{});
    var imageInfo = vk.VkImageCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .pNext = pNext,
        .flags = flags,
        .imageType = imageType,
        .format = format,
        .extent = extent,
        .mipLevels = mipLevels,
        .arrayLayers = arrayLayers,
        .samples = samples,
        .tiling = tiling,
        .usage = usage,
        .sharingMode = sharingMode,
        .queueFamilyIndexCount = queueFamilyIndexCount,
        .pQueueFamilyIndices = pQueueFamilyIndices,
        .initialLayout = switch (initialLayout) {
            .VK_IMAGE_LAYOUT_UNDEFINED => vk.VK_IMAGE_LAYOUT_UNDEFINED,
            .VK_IMAGE_LAYOUT_PREINITIALIZED => vk.VK_IMAGE_LAYOUT_PREINITIALIZED,
        },
    };

    var allocationInfo = vma.VmaAllocationCreateInfo{
        .usage = vma.VMA_MEMORY_USAGE_GPU_ONLY,
    };

    var img: vk.VkImage = null;
    var allocation: vma.VmaAllocation = null;
    try checkVkResult(vma.vmaCreateImage(self.vmaAllocator, @ptrCast(&imageInfo), @ptrCast(&allocationInfo), @ptrCast(&img), @ptrCast(&allocation), null));

    _ = self.vmaImageAllocations.fetchAdd(1, .seq_cst);

    return Image{
        .vkImage = img,
        .allocation = allocation,
        .queueIndex = -1,
    };
}

pub fn createImage2D(
    self: *Self,
    width: u32,
    height: u32,
    format: vk.VkFormat,
    tiling: vk.VkImageTiling,
    usage: vk.VkImageUsageFlags,
) VkError!Image {
    return self._createVkImage(
        null,
        0,
        vk.VK_IMAGE_TYPE_2D,
        format,
        vk.VkExtent3D{ .width = width, .height = height, .depth = 1 },
        1,
        1,
        vk.VK_SAMPLE_COUNT_1_BIT,
        tiling,
        usage,
        vk.VK_SHARING_MODE_EXCLUSIVE,
        0,
        null,
        .VK_IMAGE_LAYOUT_UNDEFINED,
    );
}

pub fn _createCommandBuffers(
    self: *Self,
    pNext: ?*anyopaque,
    commandPool: vk.VkCommandPool,
    level: vk.VkCommandBufferLevel,
    commandBufferCount: u32,
    pCommandBuffers: [*c]vk.VkCommandBuffer,
) !void {
    const zone = tracy.initZone(@src(), .{ .name = "create command buffer" });
    defer zone.deinit();

    var allocateInfo = vk.VkCommandBufferAllocateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .pNext = pNext,
        .commandPool = commandPool,
        .level = level,
        .commandBufferCount = commandBufferCount,
    };

    try checkVkResult(vk.vkAllocateCommandBuffers(self.device, @ptrCast(&allocateInfo), @ptrCast(pCommandBuffers)));
}

pub fn _beginCommandBuffer(commandBuffer: vk.VkCommandBuffer, pNext: ?*anyopaque, flags: vk.VkCommandBufferUsageFlags, pInheritanceInfo: ?*vk.VkCommandBufferInheritanceInfo) !void {
    const zone = tracy.initZone(@src(), .{ .name = "begin command buffer" });
    defer zone.deinit();

    var beginInfo = vk.VkCommandBufferBeginInfo{
        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .pNext = pNext,
        .flags = flags,
        .pInheritanceInfo = @ptrCast(pInheritanceInfo),
    };

    try checkVkResult(vk.vkBeginCommandBuffer(commandBuffer, &beginInfo));
}

pub fn endCommandBuffer(commandBuffer: vk.VkCommandBuffer) !void {
    const zone = tracy.initZone(@src(), .{ .name = "end command buffer" });
    defer zone.deinit();

    try checkVkResult(vk.vkEndCommandBuffer(commandBuffer));
}

pub fn createBinarySemaphore(self: *Self, flags: vk.VkSemaphoreCreateFlags, pSemaphore: []vk.VkSemaphore) !void {
    const zone = tracy.initZone(@src(), .{ .name = "create semaphores" });
    defer zone.deinit();

    try self._createSemaphore(null, flags, pSemaphore);
}

pub fn createTimelineSemaphore(self: *Self, flags: vk.VkSemaphoreCreateFlags, pSemaphore: []vk.VkSemaphore, initialValue: u64) !void {
    const zone = tracy.initZone(@src(), .{ .name = "create semaphores" });
    defer zone.deinit();

    var createInfo = vk.VkSemaphoreTypeCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_TYPE_CREATE_INFO,
        .pNext = null,
        .semaphoreType = vk.VK_SEMAPHORE_TYPE_TIMELINE,
        .initialValue = initialValue,
    };

    try self._createSemaphore(&createInfo, flags, pSemaphore);
}

pub fn _createSemaphore(self: *Self, pNext: ?*anyopaque, flags: vk.VkSamplerCreateFlags, pSemaphore: []vk.VkSemaphore) !void {
    var createInfo = vk.VkSemaphoreCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO,
        .pNext = pNext,
        .flags = flags,
    };

    for (0..pSemaphore.len) |i|
        try checkVkResult(vk.vkCreateSemaphore(self.device, @ptrCast(&createInfo), self.pAllocCallBacks, @ptrCast(&pSemaphore[i])));
}

pub fn acquireNextImage(self: *Self, pIndex: *u32) !void {
    const zone = tracy.initZone(@src(), .{ .name = "acquire next image" });
    defer zone.deinit();

    try checkVkResult(vk.vkAcquireNextImageKHR(self.device, self.swapchain, std.math.maxInt(u64), self.imageAvailableSemaphore[self.currentFrame.load(.seq_cst)], null, @ptrCast(pIndex)));
}

pub fn nextFrame(self: *Self) void {
    var val = self.currentFrame.load(.seq_cst);
    val = (val + 1) % 2;
    self.currentFrame.store(val, .seq_cst);
}

pub fn getSurfaceFormat(self: *Self) !vk.VkSurfaceFormatKHR {
    const zone = tracy.initZone(@src(), .{ .name = "get surface format" });
    defer zone.deinit();

    if (self.surfaceFormat.colorSpace != 0 and self.surfaceFormat.format != 0) {
        return self.surfaceFormat;
    }

    var formatCount: u32 = 0;
    try checkVkResult(vk.vkGetPhysicalDeviceSurfaceFormatsKHR(self.physicalDevice, self.surface, @ptrCast(&formatCount), null));

    if (formatCount == 0) return error.NoSurfaceFormat;

    var formats = [_]vk.VkSurfaceFormatKHR{.{}} ** 24;
    try checkVkResult(vk.vkGetPhysicalDeviceSurfaceFormatsKHR(self.physicalDevice, self.surface, @ptrCast(&formatCount), @ptrCast(&formats)));

    for (0..formatCount) |i| {
        if (formats[i].colorSpace == DefaultSurfaceFormat.colorSpace and formats[i].format == DefaultSurfaceFormat.format) {
            return formats[i];
        }
    }

    return formats[0];
}

pub fn getPresentMode(self: *Self) !vk.VkPresentModeKHR {
    const zone = tracy.initZone(@src(), .{ .name = "get present mode" });
    defer zone.deinit();

    if (self.presentMode != 0) {
        return self.presentMode;
    }

    var modeCount: u32 = 0;
    try checkVkResult(vk.vkGetPhysicalDeviceSurfacePresentModesKHR(self.physicalDevice, self.surface, @ptrCast(&modeCount), null));

    if (modeCount == 0) return error.NoPresentMode;

    var modes = [_]vk.VkPresentModeKHR{0} ** 16;
    try checkVkResult(vk.vkGetPhysicalDeviceSurfacePresentModesKHR(self.physicalDevice, self.surface, @ptrCast(&modeCount), @ptrCast(&modes)));

    var MAILBOX: vk.VkPresentModeKHR = 0;
    var FIFO: vk.VkPresentModeKHR = 0;
    var IMMEDIATE: vk.VkPresentModeKHR = 0;

    for (0..modeCount) |i| {
        if (modes[i] == vk.VK_PRESENT_MODE_FIFO_KHR) {
            FIFO = vk.VK_PRESENT_MODE_FIFO_KHR;
        } else if (modes[i] == vk.VK_PRESENT_MODE_MAILBOX_KHR) {
            MAILBOX = vk.VK_PRESENT_MODE_FIFO_KHR;
        } else if (modes[i] == vk.VK_PRESENT_MODE_IMMEDIATE_KHR) {
            IMMEDIATE = vk.VK_PRESENT_MODE_IMMEDIATE_KHR;
        }
    }

    if (MAILBOX > 0) return MAILBOX;
    if (FIFO > 0) return FIFO;
    if (IMMEDIATE > 0) return IMMEDIATE;

    return vk.VK_PRESENT_MODE_IMMEDIATE_KHR;
}

pub fn createSwapchain(self: *Self) !vk.VkSwapchainKHR {
    const zone = tracy.initZone(@src(), .{ .name = "create swapchain" });
    defer zone.deinit();

    var surfaceCapabilities: vk.VkSurfaceCapabilitiesKHR = .{};
    try checkVkResult(vk.vkGetPhysicalDeviceSurfaceCapabilitiesKHR(self.physicalDevice, self.surface, @ptrCast(&surfaceCapabilities)));

    var swapchain: vk.VkSwapchainKHR = null;
    const imageCount: u32 = @max(surfaceCapabilities.minImageCount + 1, surfaceCapabilities.maxImageCount);

    var createInfo = vk.VkSwapchainCreateInfoKHR{
        .sType = vk.VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
        .pNext = null,
        .flags = 0,
        .surface = self.surface,
        .minImageCount = imageCount,
        .imageFormat = self.surfaceFormat.format,
        .imageColorSpace = self.surfaceFormat.colorSpace,
        .imageExtent = vk.VkExtent2D{
            .width = self.windowWidth,
            .height = self.windowsHeight,
        },
        .imageArrayLayers = 1,
        .imageUsage = vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .preTransform = surfaceCapabilities.currentTransform,
        .compositeAlpha = vk.VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
        .presentMode = self.presentMode,
        .clipped = vk.VK_TRUE,
        .oldSwapchain = self.swapchain,
        .imageSharingMode = vk.VK_SHARING_MODE_EXCLUSIVE,
        .queueFamilyIndexCount = 0,
        .pQueueFamilyIndices = null,
    };

    try checkVkResult(vk.vkCreateSwapchainKHR(self.device, @ptrCast(&createInfo), self.pAllocCallBacks, @ptrCast(&swapchain)));

    return swapchain;
}

pub fn createSwapchainImages(self: *Self) !void {
    var count: u32 = 0;
    try checkVkResult(vk.vkGetSwapchainImagesKHR(self.device, self.swapchain, @ptrCast(&count), null));
}

pub fn queueSubmit(self: *Self, kind: CommandPoolType, submitCount: u32, pSubmits: *vk.VkSubmitInfo, fence: vk.VkFence) VkError!void {
    const zone = tracy.initZone(@src(), .{ .name = "queue submit" });
    defer zone.deinit();

    var queue =
        switch (kind) {
            .graphic => self.graphicQueue,
            .compute => self.computeQueue,
            .transfer => self.transferQueue,
            .init => unreachable,
        };

    queue.mutex.lock();
    defer queue.mutex.unlock();

    try checkVkResult(vk.vkQueueSubmit(queue.queue, submitCount, @ptrCast(pSubmits), fence));
}

pub fn presentSubmit(self: *Self, pPresentInfo: [*c]vk.VkPresentInfoKHR) !void {
    const zone = tracy.initZone(@src(), .{ .name = "present" });
    defer zone.deinit();

    self.graphicQueue.mutex.lock();
    defer self.graphicQueue.mutex.unlock();

    try checkVkResult(vk.vkQueuePresentKHR(self.graphicQueue.queue, pPresentInfo));
}

pub fn _createFence(self: *Self, pNext: ?*anyopaque, flags: vk.VkFenceCreateFlags, pFence: [*]vk.VkFence, count: u32) !void {
    var createInfo = vk.VkFenceCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
        .pNext = pNext,
        .flags = flags,
    };

    for (0..count) |i|
        try checkVkResult(vk.vkCreateFence(self.device, @ptrCast(&createInfo), self.pAllocCallBacks, @ptrCast(&pFence[i])));
}

pub fn waitForFence(self: *Self, fenceCount: u32, fences: *vk.VkFence, waitAll: vk.VKBool32) !void {
    try checkVkResult(vk.vkWaitForFences(self.device, fenceCount, @ptrCast(fences), waitAll, std.math.maxInt(u64)));
}

pub fn resetFence(self: *Self, fenceCount: u32, fences: *vk.VkFence) !void {
    try checkVkResult(vk.vkResetFences(self.device, fenceCount, @ptrCast(fences)));
}

pub fn resetCommandBuffer(commandBuffer: vk.VkCommandBuffer) !void {
    try checkVkResult(vk.vkResetCommandBuffer(commandBuffer, 0));
}

pub fn waitSemaphore(self: *Self, semaphoreCount: u32, pSemaphores: *vk.VkSemaphore, pValues: *u64) !void {
    const zone = tracy.initZone(@src(), .{ .name = " wait semaphore" });
    defer zone.deinit();

    var semaphoreWaitInfo = vk.VkSemaphoreWaitInfo{
        .sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_WAIT_INFO,
        .pNext = null,
        .flags = 0,
        .semaphoreCount = semaphoreCount,
        .pSemaphores = @ptrCast(pSemaphores),
        .pValues = @ptrCast(pValues),
    };

    try checkVkResult(vk.vkWaitSemaphores(self.device, @ptrCast(&semaphoreWaitInfo), std.math.maxInt(u64)));
}

pub fn getSemaphoreCounterValue(self: *Self, semaphore: vk.VkSemaphore) !u64 {
    const zone = tracy.initZone(@src(), .{ .name = "get semaphore value" });
    defer zone.deinit();

    var value: u64 = 0;
    try checkVkResult(vk.vkGetSemaphoreCounterValue(self.device, semaphore, @ptrCast(&value)));
    return value;
}

pub fn destroySemaphore(self: *Self, semaphore: vk.VkSemaphore) void {
    vk.vkDestroySemaphore(self.device, semaphore, self.pAllocCallBacks);
}

pub fn destroySwapchain(self: *Self, swapchain: vk.VkSwapchainKHR) void {
    vk.vkDestroySwapchainKHR(self.device, swapchain, self.pAllocCallBacks);
}

pub fn waitDevice(self: *Self) !void {
    try checkVkResult(vk.vkDeviceWaitIdle(self.device));
}

pub fn destroyImage(self: *Self, image: Image) void {
    const zone = tracy.initZone(@src(), .{ .name = "destroy image" });
    defer zone.deinit();

    vma.vmaDestroyImage(self.vmaAllocator, @ptrCast(image.vkImage), image.allocation);

    _ = self.vmaImageAllocations.fetchSub(1, .seq_cst);
}

pub fn readPipelineFileAndAdd(self: *Self, fileID: i32) !void {
    const zone = tracy.initZone(@src(), .{ .name = "read pipeline file and add" });
    defer zone.deinit();

    const zone2 = tracy.initZone(@src(), .{ .name = "read file in read pipeline file and add" });
    var pFile = try file.getFile(fileID);
    defer pFile.close();
    const fileSize = (try pFile.stat()).size;
    var fileContent = try self.allocator.alloc(u8, fileSize);
    defer self.allocator.free(fileContent);
    _ = try pFile.readAll(fileContent);
    zone2.deinit();

    var shaderCodes: [5][]u8 = undefined;
    var pos: u64 = 0;

    const zone3 = tracy.initZone(@src(), .{ .name = "split file content" });
    const pipelineInfo: *translate.VulkanPipelineInfo = @alignCast(std.mem.bytesAsValue(
        translate.VulkanPipelineInfo,
        fileContent[0..@sizeOf(translate.VulkanPipelineInfo)],
    ));
    pos += @sizeOf(translate.VulkanPipelineInfo);
    for (0..5) |i| {
        if (pos >= fileSize) break;

        const len = std.mem.bytesToValue(usize, fileContent[pos .. pos + 8]);
        pos += 8;
        shaderCodes[i] = fileContent[pos .. pos + len];
        pos += len;
    }
    zone3.deinit();

    try translate.toVulkan(pipelineInfo, shaderCodes, @constCast(&self.descriptorSetLayout));

    try self.addPipelineCreateInfo(pipelineInfo);
}

pub fn _createDescriptorPool(self: *Self, flag: vk.VkDescriptorPoolCreateFlags, poolSizes: []vk.VkDescriptorPoolSize, maxSets: u32) VkError!vk.VkDescriptorPool {
    var createInfo = vk.VkDescriptorPoolCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO,
        .pNext = null,
        .flags = flag,
        .pPoolSizes = @ptrCast(poolSizes.ptr),
        .poolSizeCount = @intCast(poolSizes.len),
        .maxSets = maxSets,
    };
    var pool: vk.VkDescriptorPool = null;

    try checkVkResult(vk.vkCreateDescriptorPool(self.device, &createInfo, self.pAllocCallBacks, &pool));

    return pool;
}

pub fn destroyDescriptorPool(self: *Self, pool: vk.VkDescriptorPool) void {
    vk.vkDestroyDescriptorPool(self.device, pool, self.pAllocCallBacks);
}

pub fn allocateDescriptorSets(self: *Self, pool: vk.VkDescriptorPool, setLayouts: []vk.VkDescriptorSetLayout, descriptorSets: [*]vk.VkDescriptorSet) !void {
    var allocaInfo = vk.VkDescriptorSetAllocateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO,
        .pNext = null,
        .descriptorPool = pool,
        .descriptorSetCount = @intCast(setLayouts.len),
        .pSetLayouts = @ptrCast(setLayouts.ptr),
    };

    try checkVkResult(vk.vkAllocateDescriptorSets(self.device, @ptrCast(&allocaInfo), @ptrCast(descriptorSets)));
}

pub fn vmaStatistics(self: *Self) void {
    const zone = tracy.initZone(@src(), .{ .name = "vma statistics" });
    defer zone.deinit();

    var stat: vma.VmaTotalStatistics = .{};

    vma.vmaCalculateStatistics(self.vmaAllocator, @ptrCast(&stat));

    for (stat.memoryHeap) |value| {
        if (value.statistics.blockCount == 0) continue;

        std.log.debug("{}", .{value});
    }
    for (stat.memoryType) |value| {
        if (value.statistics.blockCount == 0) continue;

        std.log.debug("{}", .{value});
    }
    std.log.debug("{}", .{stat.total});
}

pub fn addWriteDescriptorSetImage(self: *Self, dstArrayElement: u32, imageView: vk.VkImageView, sampler: vk.VkSampler) !void {
    const zone = tracy.initZone(@src(), .{ .name = "add descriptor write sets" });
    defer zone.deinit();

    const imagePtr = try self.descriptorImageInfos.addOne();
    errdefer _ = self.descriptorImageInfos.pop();
    imagePtr.* = vk.VkDescriptorImageInfo{
        .imageView = imageView,
        .sampler = sampler,
        .imageLayout = vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
    };

    const writePtr = try self.writeDescriptorSets.addOne();
    writePtr.* = vk.VkWriteDescriptorSet{
        .sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        .pNext = null,
        .dstSet = self.globalTextureDescriptorSet,
        .dstBinding = globalTextureBinding,
        .dstArrayElement = dstArrayElement,
        .descriptorCount = 1,
        .descriptorType = vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
        .pImageInfo = @ptrCast(imagePtr),
        .pBufferInfo = null,
        .pTexelBufferView = null,
    };
}

pub fn writeCachedDescriptorSetResources(self: *Self) void {
    const zone = tracy.initZone(@src(), .{ .name = "update descriptor wrote sets" });
    defer zone.deinit();

    vk.vkUpdateDescriptorSets(
        self.device,
        @intCast(self.writeDescriptorSets.items.len),
        @ptrCast(self.writeDescriptorSets.items.ptr),
        0,
        null,
    );

    self.writeDescriptorSets.clearRetainingCapacity();
    self.descriptorImageInfos.clearRetainingCapacity();
    self.descriptorBufferInfos.clearRetainingCapacity();
    self.descriptorBufferViewInfos.clearRetainingCapacity();
}

pub fn _createImageView(
    self: *Self,
    pNext: ?*anyopaque,
    flags: vk.VkImageViewCreateFlags,
    image: vk.VkImage,
    viewType: vk.VkImageViewType,
    format: vk.VkFormat,
    components: vk.VkComponentMapping,
    aspectFlags: vk.VkImageAspectFlags,
    baseMipLevel: u32,
    levelCount: u32,
    baseArrayLayer: u32,
    layerCount: u32,
) VkError!vk.VkImageView {
    var createInfo = vk.VkImageViewCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        .pNext = pNext,
        .flags = flags,
        .image = image,
        .viewType = viewType,
        .format = format,
        .components = components,
        .subresourceRange = vk.VkImageSubresourceRange{
            .aspectMask = aspectFlags,
            .baseMipLevel = baseMipLevel,
            .levelCount = levelCount,
            .baseArrayLayer = baseArrayLayer,
            .layerCount = layerCount,
        },
    };

    var imageView: vk.VkImageView = null;
    try checkVkResult(vk.vkCreateImageView(self.device, @ptrCast(&createInfo), self.pAllocCallBacks, @ptrCast(&imageView)));

    return imageView;
}

pub fn createImageView2D(self: *Self, image: vk.VkImage, format: vk.VkFormat) VkError!vk.VkImageView {
    return self._createImageView(
        null,
        0,
        image,
        vk.VK_IMAGE_VIEW_TYPE_2D,
        format,
        vk.VkComponentMapping{
            .r = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
            .g = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
            .b = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
            .a = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
        },
        vk.VK_IMAGE_ASPECT_COLOR_BIT,
        0,
        1,
        0,
        1,
    );
}

pub fn _createSampler(self: *Self, ID: u32, anisotropy: f32) !vk.VkSampler {
    var info = try samplerRead.readSampler(ID, self.allocator);
    info.maxAnisotropy = anisotropy;

    var sampler: vk.VkSampler = null;

    try checkVkResult(vk.vkCreateSampler(self.device, @ptrCast(&info), self.pAllocCallBacks, @ptrCast(&sampler)));

    return sampler;
}

pub fn destroyImageView(self: *Self, imageView: vk.VkImageView) void {
    vk.vkDestroyImageView(self.device, imageView, self.pAllocCallBacks);
}

pub fn initSamplers(self: *Self) !void {
    self.pixel2dSampler = try self._createSampler(comptime file.comptimeGetID("pixel2dSampler.sampler"), 1.0);
}

pub fn destroySamplers(self: *Self) void {
    vk.vkDestroySampler(self.device, self.pixel2dSampler, self.pAllocCallBacks);
}

pub fn getDefaultSampler(self: *Self, samplerType: SamplerType) vk.VkSampler {
    return switch (samplerType) {
        .pixel2d => self.pixel2dSampler,
    };
}

pub fn getPipeline(self: *Self, pipelineName: []const u8) ?Pipeline {
    return self.pipelines.get(pipelineName);
}

pub fn createIndexBuffer(self: *Self, size: vk.VkDeviceSize) VkError!Buffer {
    return self._createBuffer(
        0,
        null,
        vk.VK_SHARING_MODE_EXCLUSIVE,
        @intCast(math.round(BufferAlign, size)),
        vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT | vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT,
        vma.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT,
        vma.VMA_MEMORY_USAGE_GPU_ONLY,
    );
}
