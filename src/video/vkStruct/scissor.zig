const std = @import("std");

const global = @import("global");

const vk = @import("vulkan");

const Handles = @import("handle");
const Handle = Handles.Handle;

array: std.array_list.Managed(vk.VkRect2D),
pHandle: *global.HandlesType,
allocator: std.mem.Allocator,

mutex: std.Io.Mutex = .init,

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

pub fn createScissor(self: *Self, io: std.Io, scissor: vk.VkRect2D) !Scissor_t {
    self.mutex.lock(io) catch unreachable;
    defer self.mutex.unlock(io);

    const index = self.array.items.len;

    try self.array.append(scissor);

    return self.pHandle.createHandle(@intCast(index));
}

pub fn destroyScissor(self: *Self, io: std.Io, scissor: Scissor_t) void {
    self.mutex.lock(io) catch unreachable;
    defer self.mutex.unlock(io);

    // const index = Handles.getIndex(viewport);

    self.pHandle.destroyHandle(scissor);
}

pub fn getScissorContent(self: *Self, io: std.Io, scissor: Scissor_t) vk.VkRect2D {
    self.mutex.lock(io) catch unreachable;
    defer self.mutex.unlock(io);

    return self.array.items[Handles.getIndex(scissor)];
}
