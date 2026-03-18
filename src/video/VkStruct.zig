const vk = @import("vulkan").vulkan;
const sdl = @import("sdl").sdl;
const SDL_CheckResult = @import("sdl").SDL_CheckResult;
const std = @import("std");
const builtin = @import("builtin");
const Mutex = std.Thread.Mutex;
const Thread = std.Thread;
const output = @import("output");
const Allocator = std.mem.Allocator;
const VkResultToError = @import("resultToError");
pub const vulkanType = VkResultToError.vulkanType;
pub const VkError = vulkanType.VkError;
const VkResult = vulkanType.VkResult;
const VkPhysicalType = vulkanType.VkPhysicalDeviceType;
const checkVkResult = VkResultToError.checkVkResult;
const VulkanPipelineInfo = @import("translate").VulkanPipelineInfo;
const textureSet = @import("textureSet");
const tracy = @import("tracy");
const file = @import("fileSystem");
const translate = @import("translate");
const math = @import("math");
pub const Samplers = @import("vkStruct/sampler.zig");
const vmaStruct = @import("vkStruct/vma.zig");
const vma = vmaStruct.vma;
const global = @import("global");
const Window = @import("vkStruct/window.zig");
const Queue = @import("vkStruct/queue.zig");
const InstanceDevice = @import("vkStruct/instance_device.zig");
const Semaphore = @import("vkStruct/semaphore.zig");
const Swapchain = @import("vkStruct/swapchain.zig");
const Debug = @import("debug");
const Types = @import("types");
const Descriptor = @import("vkStruct/descriptor.zig");
const viewportStruct = @import("vkStruct/viewport.zig");
const scissorStruct = @import("vkStruct/scissor.zig");
const Handles = @import("handle");
const Handle = Handles.Handle;

const bufferStruct = @import("vkStruct/buffer.zig");
pub const Buffer_t = bufferStruct.Buffer_t;
pub const Pipeline_t = Handle;
pub const Viewport_t = viewportStruct.Viewport_t;
pub const Scissor_t = scissorStruct.Scissor_t;

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

pub const Out = struct {
    location: u32,
    var_type: vk.VkFormat,
};

pub const Pipeline = struct {
    setCount: u32,
    vertexBindingCount: u32,
    pipelineLayout: vk.VkPipelineLayout,
    pipeline: vk.VkPipeline,
    outputs: []Out,
};

pub const Image = struct {
    vkImage: vk.VkImage,
    allocation: vma.VmaAllocation,
    queueIndex: CommandPoolType = .init,
    // queueIndex: i32 = -1,
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

currentFrame: std.atomic.Value(u32) = .init(0),

totalFrame: std.atomic.Value(u32) = .init(0),
allocator: Allocator,
allocCallBacks: vk.VkAllocationCallbacks = undefined,
pAllocCallBacks: [*c]vk.VkAllocationCallbacks = null,
vmaS: vmaStruct = .{},

window: *sdl.SDL_Window = undefined,
windowWidth: u32 = 0,
windowsHeight: u32 = 0,

instance: vk.VkInstance = null,
surface: vk.VkSurfaceKHR = null,

surfaceFormats: Types.SurfaceFormats = undefined,
presentModes: Types.PresentModes = undefined,

physicalDeviceMemoryCount: u64 = 0,
physicalDevice: vk.VkPhysicalDevice = null,
device: vk.VkDevice = null,

swapchain: vk.VkSwapchainKHR = null,

graphicQueueFamily: Queue.VkQueueFamily = .{},
graphicQueue: Queue.VkTheadQueue = .{},
computeQueueFamily: Queue.VkQueueFamily = .{},
computeQueue: Queue.VkTheadQueue = .{},
transferQueueFamily: Queue.VkQueueFamily = .{},
transferQueue: Queue.VkTheadQueue = .{},

shaderModules: std.StringHashMap(vk.VkShaderModule),
entryNames: std.StringHashMap(void),

pipelineCache: vk.VkPipelineCache = null,

graphicPipelineCreateInfo: [10]vk.VkGraphicsPipelineCreateInfo = undefined,
preGraphicInfoPtrs: [10]VulkanPipelineInfo = undefined,
graphicInfoCount: u32 = 0,

pipelineMap: std.StringHashMap(Pipeline_t),
pipelines: std.array_list.Managed(Pipeline),

/// binary semaphore
imageAvailableSemaphore: [2]vk.VkSemaphore = undefined,
/// binary semaphore
renderFinishSemaphore: [2]vk.VkSemaphore = undefined,
globalTimelineSemaphore: vk.VkSemaphore = null,
globalTimelineValue: std.atomic.Value(u64) = .init(0),

// textureSets: textureSet,

globalDescriptorPool: vk.VkDescriptorPool = null,

descriptorSetLayout: [2]vk.VkDescriptorSetLayout = undefined,

globalFixed2dMVPMatrixDescriptorSet: vk.VkDescriptorSet = null,
global2dMVPMatrixDescriptorSet: vk.VkDescriptorSet = null,
global3dMVPMatrixDescriptorSet: vk.VkDescriptorSet = null,
globalTextureDescriptorSet: vk.VkDescriptorSet = null,

writeDescriptorSets: std.array_list.Managed(vk.VkWriteDescriptorSet) = undefined,
descriptorImageInfos: std.array_list.Managed(vk.VkDescriptorImageInfo) = undefined,
descriptorBufferInfos: std.array_list.Managed(vk.VkDescriptorBufferInfo) = undefined,
descriptorBufferViewInfos: std.array_list.Managed(vk.VkBufferView) = undefined,

samplers: Samplers = .{},

buffers: bufferStruct,
viewports: viewportStruct,
scissors: scissorStruct,

gpuType: vk.VkPhysicalDeviceType = vk.VK_PHYSICAL_DEVICE_TYPE_OTHER,
queueTypeCount: u32 = 0,

handles: *global.HandlesType,

pub fn init(allocator: Allocator, handles: *global.HandlesType) Self {
    return Self{
        .allocator = allocator,
        .shaderModules = .init(allocator),
        .entryNames = .init(allocator),
        .pipelineMap = .init(allocator),
        .pipelines = .init(allocator),
        // .textureSets = .init(allocator, handles),
        .writeDescriptorSets = .init(allocator),
        .descriptorImageInfos = .init(allocator),
        .descriptorBufferInfos = .init(allocator),
        .descriptorBufferViewInfos = .init(allocator),
        .buffers = .init(allocator),
        .viewports = .init(allocator, handles),
        .scissors = .init(allocator, handles),
        .handles = handles,
    };
}

pub fn initVulkan(self: *Self) !void {
    const zone = tracy.initZone(@src(), .{ .name = "init vulkan resources" });
    defer zone.deinit();

    self.window = try Window.createWindow(&self.windowWidth, &self.windowsHeight);
    const version = try getVulkanVersion();
    printVersion(version);

    self.instance = try InstanceDevice.createInstance(self.pAllocCallBacks, self.allocator);

    self.surface = try Swapchain.createSurface(self.window, self.instance, self.pAllocCallBacks);

    var deviceGroup = try InstanceDevice.pickPhysicalDevice(
        self.instance,
        self.allocator,
        &self.physicalDeviceMemoryCount,
    );
    self.physicalDevice = deviceGroup.physicalDevices[0];
    self.gpuType = deviceGroup.gpuType;

    self.graphicQueueFamily, self.computeQueueFamily, self.transferQueueFamily = kl: {
        const res = try Queue.setQueueFamilies(self.physicalDevice, self.allocator, self.surface);
        break :kl .{ res.graphic, res.compute, res.transfer };
    };

    self.device = try InstanceDevice.createDevice(
        deviceGroup.count,
        &deviceGroup.physicalDevices,
        self.pAllocCallBacks,
        self.graphicQueueFamily,
        self.computeQueueFamily,
        self.transferQueueFamily,
    );

    var queueTypeArray = [_]i32{100} ** 3;
    queueTypeArray[0] = self.graphicQueueFamily.familyIndice;
    queueTypeArray[1] = self.computeQueueFamily.familyIndice;
    queueTypeArray[2] = self.transferQueueFamily.familyIndice;
    self.queueTypeCount = @intCast(queueTypeArray.len);

    for (queueTypeArray) |value| {
        if (value == -1) {
            self.queueTypeCount -= 1;
        }
    }

    std.log.debug("queue type count: {d}", .{self.queueTypeCount});

    Queue.createQueues(
        &self.graphicQueueFamily,
        &self.computeQueueFamily,
        &self.transferQueueFamily,
        &self.graphicQueue,
        &self.computeQueue,
        &self.transferQueue,
        self.device,
    );

    self.vmaS = try vmaStruct.createVmaAllocator(
        self.physicalDevice,
        self.device,
        self.instance,
        self.pAllocCallBacks,
    );

    var semaphores: [4]vk.VkSemaphore = undefined;
    try Semaphore.createBinarySemaphore(self.device, self.pAllocCallBacks, 0, &semaphores);
    self.imageAvailableSemaphore[0] = semaphores[0];
    self.imageAvailableSemaphore[1] = semaphores[1];
    self.renderFinishSemaphore[0] = semaphores[2];
    self.renderFinishSemaphore[1] = semaphores[3];

    var semaphores2: [1]vk.VkSemaphore = undefined;
    try Semaphore.createTimelineSemaphore(
        self.device,
        self.pAllocCallBacks,
        0,
        &semaphores2,
        0,
    );
    self.globalTimelineSemaphore = semaphores2[0];

    self.surfaceFormats = try Swapchain.getSurfaceFormat(self.physicalDevice, self.surface, self.allocator);
    self.presentModes = try Swapchain.getPresentMode(self.physicalDevice, self.surface, self.allocator);

    self.swapchain = try Swapchain.createSwapchain(
        self.physicalDevice,
        self.device,
        self.surface,
        self.surfaceFormats.formats[@intCast(self.surfaceFormats.sdr)],
        self.presentModes.modes[@intCast(self.presentModes.immediate)],
        self.windowWidth,
        self.windowsHeight,
        null,
        self.pAllocCallBacks,
    );

    self.globalDescriptorPool = try Descriptor._createDescriptorPool(
        self.device,
        self.pAllocCallBacks,
        vk.VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT,
        @constCast(&globalDescriptorPoolSizes),
        globalDescriptorMaxSets,
    );

    self.descriptorSetLayout[0] = try Descriptor.createDescriptorSetLayout(
        self.device,
        self.pAllocCallBacks,
        null,
        set0SetLayoutCreateInfos.flag,
        set0SetLayoutCreateInfos.bindingCount,
        @constCast(&set0SetLayoutCreateInfos.bindings),
    );
    var bindingFlagsInfo = vk.VkDescriptorSetLayoutBindingFlagsCreateInfo{
        .sType = vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO,
        .pNext = null,
        .bindingCount = set1SetLayoutCreateInfos.bindingCount,
        .pBindingFlags = &set1SetLayoutCreateInfos.bindingFlags,
    };
    self.descriptorSetLayout[1] = try Descriptor.createDescriptorSetLayout(
        self.device,
        self.pAllocCallBacks,
        &bindingFlagsInfo,
        set1SetLayoutCreateInfos.flag,
        set1SetLayoutCreateInfos.bindingCount,
        @constCast(&set1SetLayoutCreateInfos.bindings),
    );

    var set0Sets: [3]vk.VkDescriptorSet = undefined;
    var set0Setlayout = [_]vk.VkDescriptorSetLayout{ self.descriptorSetLayout[0], self.descriptorSetLayout[0], self.descriptorSetLayout[0] };
    try Descriptor.allocateDescriptorSets(
        self.device,
        self.globalDescriptorPool,
        &set0Setlayout,
        &set0Sets,
    );

    self.globalFixed2dMVPMatrixDescriptorSet = set0Sets[0];
    self.global2dMVPMatrixDescriptorSet = set0Sets[1];
    self.global3dMVPMatrixDescriptorSet = set0Sets[2];

    var set1Sets: [1]vk.VkDescriptorSet = undefined;
    var set1Setlayout = [_]vk.VkDescriptorSetLayout{self.descriptorSetLayout[1]};
    try Descriptor.allocateDescriptorSets(
        self.device,
        self.globalDescriptorPool,
        &set1Setlayout,
        &set1Sets,
    );

    self.globalTextureDescriptorSet = set1Sets[0];

    try self.samplers.initSamplers(self.device, self.pAllocCallBacks, self.allocator);
}

pub fn deinit(self: *Self) void {
    self.waitDevice() catch |err| {
        std.log.err("wait device error {s}\n", .{@errorName(err)});
    };

    self.waitDevice() catch |err| {
        std.log.err("wait device error {s}\n", .{@errorName(err)});
    };

    // self.vmaStatistics();

    const zone = tracy.initZone(@src(), .{ .name = "deinit vulkan resources" });
    defer zone.deinit();

    self.samplers.destroySamplers(self.device, self.pAllocCallBacks);
    self.buffers.deinit(&self.vmaS);
    self.viewports.deinit();
    self.scissors.deinit();

    self.writeDescriptorSets.deinit();
    self.descriptorImageInfos.deinit();
    self.descriptorBufferInfos.deinit();
    self.descriptorBufferViewInfos.deinit();

    for (self.descriptorSetLayout) |value| {
        Descriptor.destroyDescriptorSetLayout(
            self.device,
            self.pAllocCallBacks,
            value,
        );
    }

    Descriptor.destroyDescriptorPool(self.device, self.pAllocCallBacks, self.globalDescriptorPool);

    var pipelines = self.pipelineMap.iterator();
    while (pipelines.next()) |val| {
        const pipe = &self.pipelines.items[Handles.getIndex(val.value_ptr.*)];

        vk.vkDestroyPipeline(self.device, pipe.pipeline, self.pAllocCallBacks);
        vk.vkDestroyPipelineLayout(self.device, pipe.pipelineLayout, self.pAllocCallBacks);
        self.allocator.free(val.key_ptr.*);
        self.allocator.free(pipe.outputs);
        // for (0..val.setCount) |i| {
        //     vk.vkDestroyDescriptorSetLayout(
        //         self.device,
        //         val.descriptorSetLayouts[i],
        //         self.pAllocCallBacks,
        //     );
        // }
    }
    self.pipelineMap.deinit();

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

    self.allocator.free(self.surfaceFormats.formats);
    self.allocator.free(self.presentModes.modes);
    self.destroySwapchain(self.swapchain);

    for (self.renderFinishSemaphore) |value| {
        self.destroySemaphore(value);
    }
    for (self.imageAvailableSemaphore) |value| {
        self.destroySemaphore(value);
    }
    self.destroySemaphore(self.globalTimelineSemaphore);

    std.log.debug("vma buffer allocation residue count: {d}", .{self.vmaS.vmaBufferAllocations.load(.seq_cst)});
    std.log.debug("vma image allocation residue count: {d}", .{self.vmaS.vmaImageAllocations.load(.seq_cst)});
    self.vmaS.destroyVmaAllocator();

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

fn initAllocCallBacks(self: *Self) void {
    _ = self;
    // self.*.allocCallBacks.pUserData = null;
    // self.*.allocCallBacks.pfnAllocation = vkAlloc;
    // self.*.allocCallBacks.pfnReallocation = vkRealloc;
    // self.*.allocCallBacks.pfnFree = vkFree;
    // self.*.allocCallBacks.pfnInternalAllocation = null;
    // self.*.allocCallBacks.pfnInternalFree = null;
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

pub const CommandPoolType = @import("vkStruct/queueType.zig").QueueType;

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
                .present, .init => unreachable,
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

    var pp: *Pipeline = undefined;
    for (0..self.graphicInfoCount) |i| {
        pp = try self.pipelines.addOne();
        pp.* = Pipeline{
            .vertexBindingCount = self.preGraphicInfoPtrs[i].vertexInputInfo.bindingCount,
            .setCount = self.preGraphicInfoPtrs[i].pipelineCreateInfoInfo.setLayoutCount,
            .pipelineLayout = self.preGraphicInfoPtrs[i].pipelineLayout.layout,
            .pipeline = temp[i],
            .outputs = try self.allocator.alloc(Out, self.preGraphicInfoPtrs[i].outputCount),
        };
        const index = self.pipelines.items.len - 1;
        const handle = self.handles.createHandle(@intCast(index));

        const len = std.mem.len(@as([*c]u8, @ptrCast(&self.preGraphicInfoPtrs[i].name)));
        const name = try self.allocator.alloc(u8, len);
        @memcpy(name, self.preGraphicInfoPtrs[i].name[0..len]);

        for (pp.outputs, 0..) |*v, j| {
            v.location = self.preGraphicInfoPtrs[i].outputs[j].location;
            v.var_type = self.preGraphicInfoPtrs[i].outputs[j].var_type;
        }

        try self.pipelineMap.put(name, handle);
        std.log.debug("{s}", .{self.preGraphicInfoPtrs[i].name});
    }
    self.graphicInfoCount = 0;
}

pub fn destroyPipeline(self: *Self, name: []const u8) !void {
    const kv = self.pipelineMap.fetchRemove(name);
    if (kv) |val| {
        self.allocator.free(val.value.outputs);
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

pub fn getPipelineOut(self: *Self, name: []const u8) ![]const Out {
    const kv = self.pipelineMap.get(name);
    if (kv) |val| {
        return self.pipelines.items[Handles.getIndex(val)].outputs;
    }
    return error.NotFound;
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
    try self.vmaS._createImage(
        @ptrCast(&imageInfo),
        @ptrCast(&allocationInfo),
        @ptrCast(&img),
        @ptrCast(&allocation),
        null,
    );

    return Image{
        .vkImage = img,
        .allocation = allocation,
        .queueIndex = .init,
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

pub fn acquireNextImage(self: *Self, pIndex: *u32) !void {
    const zone = tracy.initZone(@src(), .{ .name = "acquire next image" });
    defer zone.deinit();

    try checkVkResult(vk.vkAcquireNextImageKHR(self.device, self.swapchain, std.math.maxInt(u64), self.imageAvailableSemaphore[self.currentFrame.load(.seq_cst)], null, @ptrCast(pIndex)));
}

pub fn nextFrame(self: *Self) void {
    var val = self.currentFrame.load(.seq_cst);
    val = (val + 1) % 2;
    self.currentFrame.store(val, .seq_cst);

    _ = self.totalFrame.fetchAdd(1, .seq_cst);
}

pub fn queueSubmit(self: *Self, kind: CommandPoolType, submitCount: u32, pSubmits: *vk.VkSubmitInfo2, fence: vk.VkFence) VkError!void {
    const zone = tracy.initZone(@src(), .{ .name = "queue submit" });
    defer zone.deinit();

    var queue =
        switch (kind) {
            .graphic => self.graphicQueue,
            .compute => self.computeQueue,
            .transfer => self.transferQueue,
            .present, .init => unreachable,
        };

    queue.mutex.lock();
    defer queue.mutex.unlock();

    try checkVkResult(vk.vkQueueSubmit2(queue.queue, submitCount, @ptrCast(pSubmits), fence));
    // checkVkResult(vk.vkQueueWaitIdle(queue.queue)) catch |err| {
    //     std.log.err("queue type {s}", .{@tagName(kind)});

    //     // @breakpoint();
    //     std.Thread.sleep(std.time.ns_per_s * 1);

    //     return err;
    // };

    // std.log.debug("submit {s}", .{@tagName(kind)});
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

    self.vmaS.destroyImage(@ptrCast(image.vkImage), image.allocation);
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

    try translate.toVulkan(pipelineInfo, shaderCodes, @constCast(&self.descriptorSetLayout), self);

    try self.addPipelineCreateInfo(pipelineInfo);
}

pub fn addWriteDescriptorSetImage(
    self: *Self,
    dstArrayElement: u32,
    imageView: vk.VkImageView,
    sampler: vk.VkSampler,
    imageLayout: vk.VkImageLayout,
    dstSet: vk.VkDescriptorSet,
    dstBinding: u32,
    descriptorType: vk.VkDescriptorType,
) !void {
    const zone = tracy.initZone(@src(), .{ .name = "add descriptor write sets" });
    defer zone.deinit();

    const imagePtr = try self.descriptorImageInfos.addOne();
    errdefer _ = self.descriptorImageInfos.pop();
    imagePtr.* = vk.VkDescriptorImageInfo{
        .imageView = imageView,
        .sampler = sampler,
        .imageLayout = imageLayout,
    };

    const writePtr = try self.writeDescriptorSets.addOne();
    writePtr.* = vk.VkWriteDescriptorSet{
        .sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        .pNext = null,
        .dstSet = dstSet,
        .dstBinding = dstBinding,
        .dstArrayElement = dstArrayElement,
        .descriptorCount = 1,
        .descriptorType = descriptorType,
        .pImageInfo = @ptrCast(imagePtr),
        .pBufferInfo = null,
        .pTexelBufferView = null,
    };
}

pub fn addWriteDescriptorSetBuffer(
    self: *Self,
    dstArrayElement: u32,
    buffer: vk.VkBuffer,
    offset: vk.VkDeviceSize,
    range: vk.VkDeviceSize,
    dstSet: vk.VkDescriptorSet,
    dstBinding: u32,
    descriptorType: vk.VkDescriptorType,
) !void {
    const zone = tracy.initZone(@src(), .{ .name = "add descriptor write sets" });
    defer zone.deinit();

    const bufferPtr = try self.descriptorBufferInfos.addOne();
    errdefer _ = self.descriptorBufferInfos.pop();
    bufferPtr.* = vk.VkDescriptorBufferInfo{
        .buffer = buffer,
        .offset = offset,
        .range = range,
    };

    const writePtr = try self.writeDescriptorSets.addOne();
    writePtr.* = vk.VkWriteDescriptorSet{
        .sType = vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
        .pNext = null,
        .dstSet = dstSet,
        .dstBinding = dstBinding,
        .dstArrayElement = dstArrayElement,
        .descriptorCount = 1,
        .descriptorType = descriptorType,
        .pImageInfo = null,
        .pBufferInfo = @ptrCast(bufferPtr),
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

pub fn getPipeline(self: *Self, pipelineName: []const u8) ?Handle {
    return self.pipelineMap.get(pipelineName);
}

pub fn getPipelineContent(self: *Self, pipeline: Pipeline_t) Pipeline {
    return self.pipelines.items[Handles.getIndex(pipeline)];
}

pub fn destroyImageView(self: *Self, imageView: vk.VkImageView) void {
    vk.vkDestroyImageView(self.device, imageView, self.pAllocCallBacks);
}

pub fn _createBuffer(
    self: *Self,
    flags: u32,
    pNext: ?*anyopaque,
    sharingMode: vk.VkSharingMode,
    bufferSize: vk.VkDeviceSize,
    usage: vk.VkBufferUsageFlags,
    vmaFlags: u32,
    vmaUsage: vma.VmaMemoryUsage,
) !Buffer_t {
    return self.buffers._createBuffer(
        &self.vmaS,
        flags,
        pNext,
        sharingMode,
        bufferSize,
        usage,
        vmaFlags,
        vmaUsage,
        self.handles,
    );
}

pub fn createStagingBuffer(self: *Self, bufferSize: vk.VkDeviceSize) !Buffer_t {
    return self.buffers.createStagingBuffer(&self.vmaS, bufferSize, self.handles);
}

pub fn createVertexBuffer(self: *Self, bufferSize: vk.VkDeviceSize, stride: vk.VkDeviceSize) !Buffer_t {
    return self.buffers.createVertexBuffer(&self.vmaS, bufferSize, stride, self.handles);
}

pub fn createIndexBuffer(self: *Self, bufferSize: vk.VkDeviceSize) !Buffer_t {
    return self.buffers.createIndexBuffer(&self.vmaS, bufferSize, self.handles);
}

pub fn createUniformBuffer(self: *Self, bufferSize: vk.VkDeviceSize) !Buffer_t {
    return self.buffers.createUniformBuffer(&self.vmaS, bufferSize, self.handles);
}

pub fn destroyBuffer(self: *Self, buffer: Buffer_t) void {
    return self.buffers.destroyBuffer(&self.vmaS, buffer, self.handles);
}

pub fn getQueueIndex(self: *Self, queueType: CommandPoolType) u32 {
    return @intCast(switch (queueType) {
        .graphic => self.graphicQueueFamily.familyIndice,
        .compute => self.computeQueueFamily.familyIndice,
        .transfer => self.transferQueueFamily.familyIndice,
        .present, .init => unreachable,
    });
}

pub fn createViewport(self: *Self, viewport: vk.VkViewport) !Viewport_t {
    return self.viewports.createViewport(viewport);
}

pub fn getViewportContent(self: *Self, viewport: Viewport_t) vk.VkViewport {
    return self.viewports.getViewportContent(viewport);
}

pub fn destroyViewport(self: *Self, viewport: Viewport_t) void {
    self.viewports.destroyViewport(viewport);
}

pub fn createScissor(self: *Self, scissor: vk.VkRect2D) !Scissor_t {
    return self.scissors.createScissor(scissor);
}

pub fn getScissorContent(self: *Self, scissor: Scissor_t) vk.VkRect2D {
    return self.scissors.getScissorContent(scissor);
}

pub fn destroyScissor(self: *Self, scissor: Scissor_t) void {
    self.scissors.destroyScissor(scissor);
}

pub fn logBufferPtr(self: *Self) void {
    for (self.buffers.buffers.items.items) |v| {
        if (v == .data) {
            std.log.debug("{*} {s}", .{ v.data.vkBuffer, @tagName(v.data.usage) });
        }
    }
}
