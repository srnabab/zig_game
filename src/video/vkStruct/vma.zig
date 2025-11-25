const std = @import("std");
const builtin = @import("builtin");

pub const vma = @import("vma").vma;

const VkResultToError = @import("resultToError");
const vulkanType = VkResultToError.vulkanType;
const VkError = vulkanType.VkError;
const checkVkResult = VkResultToError.checkVkResult;

const vk = @import("vulkan").vulkan;

const tracy = @import("tracy");

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

    pub fn load(self: *Count, comptime order: std.builtin.AtomicOrder) returnType {
        if (mode) return self.count.load(order);
    }
};

const Self = @This();

vmaAllocator: vma.VmaAllocator = null,

vmaBufferAllocations: AllocationCount = .{},
vmaImageAllocations: AllocationCount = .{},

pub fn createVmaAllocator(physicalDevice: vk.VkPhysicalDevice, device: vk.VkDevice, instance: vk.VkInstance, pAllocCallBacks: [*c]vk.VkAllocationCallbacks) !Self {
    const zone = tracy.initZone(@src(), .{ .name = "create vma allocator" });
    defer zone.deinit();

    var allocator: vma.VmaAllocator = null;

    var allocatorCreateInfo = vma.VmaAllocatorCreateInfo{
        .flags = 0,
        .physicalDevice = @ptrCast(@alignCast(physicalDevice)),
        .device = @ptrCast(device),
        .pAllocationCallbacks = @ptrCast(pAllocCallBacks),
        .instance = @ptrCast(instance),
        .vulkanApiVersion = vk.VK_API_VERSION_1_4,
    };

    try checkVkResult(vma.vmaCreateAllocator(@ptrCast(&allocatorCreateInfo), @ptrCast(&allocator)));
    return Self{ .vmaAllocator = allocator };
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

pub fn _createBuffer(
    self: *Self,
    pBufferCreateInfo: [*c]const vma.VkBufferCreateInfo,
    pAllocationCreateInfo: [*c]const vma.VmaAllocationCreateInfo,
    pBuffer: [*c]vk.VkBuffer,
    pAllocation: [*c]vma.VmaAllocation,
    pAllocationInfo: [*c]vma.VmaAllocationInfo,
) VkError!void {
    try checkVkResult(vma.vmaCreateBuffer(
        self.vmaAllocator,
        pBufferCreateInfo,
        pAllocationCreateInfo,
        pBuffer,
        pAllocation,
        pAllocationInfo,
    ));
    _ = self.vmaBufferAllocations.fetchAdd(1, .seq_cst);
}

pub fn destroyBuffer(
    self: *Self,
    buffer: vk.VkBuffer,
    allocation: vma.VmaAllocation,
) void {
    _ = self.vmaBufferAllocations.fetchSub(1, .seq_cst);
    vma.vmaDestroyBuffer(self.vmaAllocator, @ptrCast(buffer), allocation);
}

pub fn destroyVmaAllocator(self: *Self) void {
    vma.vmaDestroyAllocator(self.vmaAllocator);
}

pub fn _createImage(
    self: *Self,
    pImageCreateInfo: [*c]const vma.VkImageCreateInfo,
    pAllocationCreateInfo: [*c]const vma.VmaAllocationCreateInfo,
    pImage: [*c]vk.VkImage,
    pAllocation: [*c]vma.VmaAllocation,
    pAllocationInfo: [*c]vma.VmaAllocationInfo,
) VkError!void {
    try checkVkResult(vma.vmaCreateImage(
        self.vmaAllocator,
        pImageCreateInfo,
        pAllocationCreateInfo,
        pImage,
        pAllocation,
        pAllocationInfo,
    ));
    _ = self.vmaImageAllocations.fetchAdd(1, .seq_cst);
}

pub fn destroyImage(self: *Self, image: vk.VkImage, allocation: vma.VmaAllocation) void {
    _ = self.vmaImageAllocations.fetchSub(1, .seq_cst);
    vma.vmaDestroyImage(self.vmaAllocator, @ptrCast(image), allocation);
}
