const std = @import("std");

const global = @import("global");

const vk = @import("vulkan").vulkan;

const Handles = @import("handle");
const Handle = Handles.Handle;

array: std.array_list.Managed(vk.VkRect2D),
pHandle: *global.HandlesType,
allocator: std.mem.Allocator,

mutex: std.Thread.Mutex = .{},

const Self = @This();

pub const Scissor_t = Handle;

pub fn init(allocator: std.mem.Allocator, pHandle: *global.HandlesType) Self {
    return .{
        .array = .init(allocator),
        .pHandle = pHandle,
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    self.array.deinit();
}

pub fn createScissor(self: *Self, scissor: vk.VkRect2D) !Scissor_t {
    self.mutex.lock();
    defer self.mutex.unlock();

    const index = self.array.items.len;

    try self.array.append(scissor);

    return self.pHandle.createHandle(@intCast(index));
}

pub fn destroyScissor(self: *Self, scissor: Scissor_t) void {
    self.mutex.lock();
    defer self.mutex.unlock();

    // const index = Handles.getIndex(viewport);

    self.pHandle.destroyHandle(scissor);
}

pub fn getScissorContent(self: *Self, scissor: Scissor_t) vk.VkRect2D {
    self.mutex.lock();
    defer self.mutex.unlock();

    return self.array.items[Handles.getIndex(scissor)];
}
