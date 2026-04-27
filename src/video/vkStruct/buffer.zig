const std = @import("std");
const builtin = @import("builtin");
const vk = @import("vulkan");
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

const assert = std.debug.assert;

const AllocationType = enum {
    real,
    virtual,
    block,
};

pub const Allocation = union(AllocationType) {
    real: vma.VmaAllocation,
    virtual: vma.VmaVirtualAllocation,
    block: void,
};

pub const Buffer = struct {
    pMappedData: ?*anyopaque = @import("std").mem.zeroes(?*anyopaque),
    virtualBlock: vma.VmaVirtualBlock = null,
    vkBuffer: vk.VkBuffer,

    /// VmaAllocation, VmaVirtualAllocation
    allocation: Allocation,
    size: vk.VkDeviceSize,
    stride: vk.VkDeviceSize = 0,
    queueIndex: QueueType = .init,
    usage: Usage = .none,
    offset: vk.VkDeviceSize = 0,

    pub fn changeQueueIndex(self: *Buffer, queueType: QueueType) void {
        self.queueIndex = queueType;
    }
};

pub const Buffer_t = Handle;

const Self = @This();

const BufferAlign = 16;
const UniformBufferAlign = 64;
const bufferRatio: f32 = 0.5 / 11;

buffers: FixedIndexArray(Buffer),

pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .buffers = .init(allocator),
    };
}

pub fn deinit(self: *Self, vmaa: *vmaStruct) void {
    for (self.buffers.items.items) |value| {
        if (value == .data) {
            switch (value.data.allocation) {
                .block => {},
                .real => {
                    _ = vmaa.vmaBufferAllocations.fetchSub(1, .seq_cst);
                    vma.vmaDestroyBuffer(
                        vmaa.vmaAllocator,
                        @ptrCast(value.data.vkBuffer),
                        @ptrCast(value.data.allocation.real),
                    );
                },
                .virtual => {
                    vma.vmaVirtualFree(value.data.virtualBlock, value.data.allocation.virtual);
                },
            }
        }
    }

    for (self.buffers.items.items) |value| {
        if (value == .data) {
            switch (value.data.allocation) {
                .block => {
                    vma.vmaDestroyVirtualBlock(value.data.virtualBlock);
                },
                .real => {},
                .virtual => {},
            }
        }
    }
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
    stride: vk.VkDeviceSize,
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

    try vmaa._createBuffer(
        @ptrCast(&bufferCreateInfo),
        @ptrCast(&allocationCreateInfo),
        @ptrCast(&pBuffer),
        @ptrCast(&pAllocation),
        @ptrCast(&allocationInfo),
    );

    const pack = try self.buffers.addOne();
    pack.ptr.* = Buffer{
        .vkBuffer = pBuffer,
        .allocation = .{ .real = pAllocation },
        // .info = allocationInfo,
        .size = allocationInfo.size,
        .pMappedData = allocationInfo.pMappedData,
        .queueIndex = .init,
        .usage = inferUsage(usage),
        .stride = stride,
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

    assert(ptr.allocation == .real);

    vmaa.destroyBuffer(ptr.vkBuffer, ptr.allocation.real);

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
        0,
        vk.VK_BUFFER_USAGE_TRANSFER_SRC_BIT,
        vma.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT | vma.VMA_ALLOCATION_CREATE_MAPPED_BIT,
        vma.VMA_MEMORY_USAGE_AUTO,
        handles,
    );
}

pub fn createVertexBuffer(
    self: *Self,
    vmaa: *vmaStruct,
    bufferSize: vk.VkDeviceSize,
    stride: vk.VkDeviceSize,
    handles: *global.HandlesType,
) !Buffer_t {
    return self._createBuffer(
        vmaa,
        0,
        null,
        vk.VK_SHARING_MODE_EXCLUSIVE,
        @intCast(math.round(BufferAlign, bufferSize)),
        stride,
        vk.VK_BUFFER_USAGE_VERTEX_BUFFER_BIT | vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT | vk.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT,
        vma.VMA_ALLOCATION_CREATE_HOST_ACCESS_RANDOM_BIT,
        vma.VMA_MEMORY_USAGE_AUTO_PREFER_DEVICE,
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
        0,
        vk.VK_BUFFER_USAGE_INDEX_BUFFER_BIT | vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT,
        vma.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT,
        vma.VMA_MEMORY_USAGE_AUTO_PREFER_DEVICE,
        handles,
    );
}
pub fn createUniformBuffer(
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
        @intCast(math.round(UniformBufferAlign, size)),
        0,
        vk.VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT,
        vma.VMA_ALLOCATION_CREATE_HOST_ACCESS_RANDOM_BIT | vma.VMA_ALLOCATION_CREATE_MAPPED_BIT,
        vma.VMA_MEMORY_USAGE_AUTO_PREFER_HOST,
        handles,
    );
}

pub fn createStorageBuffer(
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
        0,
        vk.VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | vk.VK_BUFFER_USAGE_TRANSFER_DST_BIT,
        vma.VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT,
        vma.VMA_MEMORY_USAGE_AUTO_PREFER_DEVICE,
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

pub fn getBufferOffset(self: *Self, buffer: Buffer_t) vk.VkDeviceSize {
    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);

    return ptr.offset;
}

pub fn getBufferContent(self: *Self, buffer: Buffer_t) Buffer {
    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);

    return ptr.*;
}

pub fn createVirtualBlockBuffer(
    self: *Self,
    pAllocationCallBacks: [*c]vk.VkAllocationCallbacks,
    flags: u32,
    size: u64,
    buffer: Buffer_t,
    offset: vk.VkDeviceSize,
    stride: vk.VkDeviceSize,
    handles: *global.HandlesType,
) !Buffer_t {
    var block: vma.VmaVirtualBlock = null;

    try vmaStruct._createVirtualBlock(
        pAllocationCallBacks,
        flags,
        size,
        &block,
    );

    const pack = try self.buffers.addOne();

    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);

    pack.ptr.* = Buffer{
        .vkBuffer = ptr.vkBuffer,
        .allocation = .{ .block = void{} },
        .size = size,
        .pMappedData = ptr.pMappedData,
        .queueIndex = ptr.queueIndex,
        .usage = ptr.usage,
        .stride = stride,
        .offset = offset + ptr.offset,
        .virtualBlock = block,
    };
    std.log.debug("block offset {d}", .{offset});

    // std.log.debug("ptr {*}, {*}, index {d}", .{ pack.ptr.vkBuffer, ptr.vkBuffer, index });

    const handle = handles.createHandle(@intCast(pack.index));

    return handle;
}

pub const BufferAndOffset = struct {
    buffer: Buffer_t,
    offset: vk.VkDeviceSize,
};

pub fn createVirtualBuffer(
    self: *Self,
    blockBuffer: Buffer_t,
    flags: u32,
    size: u64,
    alignment: u64,
    handles: *global.HandlesType,
) !BufferAndOffset {
    const pack = try self.buffers.addOne();

    const index = getIndex(blockBuffer);
    const ptr = self.buffers.get(index);

    assert(ptr.virtualBlock != null);

    var allocation: vma.VmaVirtualAllocation = null;
    var offset: vk.VkDeviceSize = 0;

    try vmaStruct._virtualAlloc(
        ptr.virtualBlock,
        null,
        flags,
        size,
        alignment,
        &allocation,
        &offset,
    );

    pack.ptr.* = Buffer{
        .vkBuffer = ptr.vkBuffer,
        .allocation = .{ .virtual = allocation },
        .size = size,
        .pMappedData = ptr.pMappedData,
        .queueIndex = ptr.queueIndex,
        .usage = ptr.usage,
        .stride = ptr.stride,
        .offset = ptr.offset + offset,
        .virtualBlock = ptr.virtualBlock,
    };
    std.log.debug("2 offset {d}", .{ptr.offset});

    const handle = handles.createHandle(@intCast(pack.index));

    return .{ .buffer = handle, .offset = offset + ptr.offset };
}

pub fn destroyVirtualBlockBuffer(self: *Self, buffer: Buffer_t) void {
    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);

    assert(ptr.allocation == .block);

    vma.vmaDestroyVirtualBlock(ptr.virtualBlock);
}

pub fn destroyVirtualBuffer(self: *Self, buffer: Buffer_t) void {
    const index = getIndex(buffer);
    const ptr = self.buffers.get(index);

    assert(ptr.allocation == .virtual);

    vma.vmaVirtualFree(ptr.virtualBlock, ptr.allocation.virtual);
}
