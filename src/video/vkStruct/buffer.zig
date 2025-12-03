const std = @import("std");
const builtin = @import("builtin");
const vk = @import("vulkan").vulkan;
const vmaStruct = @import("vma.zig");
const vma = vmaStruct.vma;
const QueueType = @import("queueType.zig").QueueType;
const VkResultToError = @import("resultToError");
const vulkanType = VkResultToError.vulkanType;
const VkError = vulkanType.VkError;
const Usage = @import("processRender").drawC.BufferUsage;
const FixedIndexArray = @import("fixedIndexArray").FixedIndexArray;
const Handles = @import("handle");
const Handle = Handles.Handle;
const getIndex = @import("handle").getIndex;
const global = @import("global");
const tracy = @import("tracy");
const math = @import("math");

pub const Buffer = struct {
    vkBuffer: vk.VkBuffer,
    allocation: vma.VmaAllocation,
    // info: vma.VmaAllocationInfo,
    size: vk.VkDeviceSize,
    pMappedData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    queueIndex: QueueType = .init,
    usage: Usage = .none,

    pub fn changeQueueIndex(self: *Buffer, queueType: QueueType) void {
        self.queueIndex = queueType;
    }
};

pub const Buffer_t = Handle;

const Self = @This();

const BufferAlign = 16;
const bufferRatio: f32 = 0.5 / 11;

buffers: FixedIndexArray(Buffer),

pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .buffers = .init(allocator),
    };
}

pub fn deinit(self: *Self) void {
    self.buffers.deinit();
}

fn inferUsage(usage: vk.VkBufferUsageFlags) Usage {
    if (usage & vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT != 0) {
        return .index;
    } else if (usage & vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT != 0) {
        return .vertex;
    } else if (usage & vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT != 0) {
        return .uniform;
    } else if (usage & vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT != 0) {
        return .storage;
    } else if (usage & vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT != 0) {
        return .staging;
    } else {
        return .none;
    }
}

pub fn _createBuffer(
    self: *Self,
    vmaa: *vmaStruct,
    flags: u32,
    pNext: ?*anyopaque,
    sharingMode: vk.VkSharingMode,
    bufferSize: vk.VkDeviceSize,
    usage: vk.VkBufferUsageFlags,
    vmaFlags: u32,
    vmaUsage: vma.VmaMemoryUsage,
    handles: *global.HandlesType,
) !Buffer_t {
    const zone = tracy.initZone(@src(), .{ .name = "create buffer" });
    defer zone.deinit();

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

    try vmaa._createBuffer(@ptrCast(&bufferCreateInfo), @ptrCast(&allocationCreateInfo), @ptrCast(&pBuffer), @ptrCast(&pAllocation), @ptrCast(&allocationInfo));

    const pack = try self.buffers.addOne();
    pack.ptr.* = Buffer{
        .vkBuffer = pBuffer,
        .allocation = pAllocation,
        // .info = allocationInfo,
        .size = allocationInfo.size,
        .pMappedData = allocationInfo.pMappedData,
        .queueIndex = .init,
        .usage = inferUsage(usage),
    };

    const handle = handles.createHandle(@intCast(pack.index));

    return handle;
}

pub fn destroyBuffer(
    self: *Self,
    vmaa: *vmaStruct,
    buffer: Buffer_t,
    handles: *global.HandlesType,
) void {
    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);

    vmaa.destroyBuffer(ptr.vkBuffer, ptr.allocation);

    self.buffers.remove(index);
    handles.destroyHandle(buffer);
}

pub fn createStagingBuffer(
    self: *Self,
    vmaa: *vmaStruct,
    bufferSize: vk.VkDeviceSize,
    handles: *global.HandlesType,
) !Buffer_t {
    return self._createBuffer(
        vmaa,
        0,
        null,
        vk.VK_SHARING_MODE_EXCLUSIVE,
        @intCast(math.round(BufferAlign, @intCast(bufferSize))),
        vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        vma.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | vma.VMA_ALLOCATION_CREATE_MAPPED_BIT,
        vma.VMA_MEMORY_USAGE_CPU_TO_GPU,
        handles,
    );
}

pub fn createVertexBuffer(
    self: *Self,
    vmaa: *vmaStruct,
    bufferSize: vk.VkDeviceSize,
    handles: *global.HandlesType,
) !Buffer_t {
    return self._createBuffer(
        vmaa,
        0,
        null,
        vk.VK_SHARING_MODE_EXCLUSIVE,
        @intCast(math.round(BufferAlign, bufferSize)),
        vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT,
        vma.VMA_ALLOCATION_CREATE_HOST_ACCESS_RANDOM_BIT,
        vma.VMA_MEMORY_USAGE_GPU_ONLY,
        handles,
    );
}

pub fn createIndexBuffer(
    self: *Self,
    vmaa: *vmaStruct,
    size: vk.VkDeviceSize,
    handles: *global.HandlesType,
) !Buffer_t {
    return self._createBuffer(
        vmaa,
        0,
        null,
        vk.VK_SHARING_MODE_EXCLUSIVE,
        @intCast(math.round(BufferAlign, size)),
        vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT | vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT,
        vma.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT,
        vma.VMA_MEMORY_USAGE_GPU_ONLY,
        handles,
    );
}

pub fn copyDataToMapped(self: *Self, buffer: Buffer_t, srcType: type, src: []const srcType) void {
    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);

    @memcpy(@as([*c]srcType, @ptrCast(@alignCast(ptr.pMappedData))), src);
}

pub fn getBufferQueueType(self: *Self, buffer: Buffer_t) QueueType {
    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);
    return ptr.queueIndex;
}

pub fn changeQueueType(self: *Self, buffer: Buffer_t, queueType: QueueType) void {
    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);

    ptr.queueIndex = queueType;
}

// pub fn changeUsage(self: *Self, buffer: Buffer_t, usage: Usage) void {
//     const index = getIndex(buffer);
//     const ptr = self.buffers.get(index);

//     ptr.lastUsage = usage;
// }

pub fn getBufferSize(self: *Self, buffer: Buffer_t) vk.VkDeviceSize {
    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);

    return ptr.size;
}

pub fn getVkBuffer(self: *Self, buffer: Buffer_t) vk.VkBuffer {
    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);

    return ptr.vkBuffer;
}

pub fn getBufferUsage(self: *Self, buffer: Buffer_t) Usage {
    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);

    return ptr.usage;
}
