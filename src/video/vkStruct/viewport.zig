const std = @import("std");

const global = @import("global");

const vk = @import("vulkan");

const Handles = @import("handle");
const Handle = Handles.Handle;

array: std.array_list.Managed(vk.VkViewport),
pHandle: *global.HandlesType,
allocator: std.mem.Allocator,

mutex: std.Io.Mutex = .init,

const Self = @This();

pub const Viewport_t = Handle;

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

pub fn createViewport(self: *Self, io: std.Io, viewport: vk.VkViewport) !Viewport_t {
    self.mutex.lock(io) catch unreachable;
    defer self.mutex.unlock(io);

    const index = self.array.items.len;

    try self.array.append(viewport);

    return self.pHandle.createHandle(@intCast(index));
}

pub fn destroyViewport(self: *Self, io: std.Io, viewport: Viewport_t) void {
    self.mutex.lock(io) catch unreachable;
    defer self.mutex.unlock(io);

    // const index = Handles.getIndex(viewport);

    self.pHandle.destroyHandle(viewport);
}

pub fn getViewportContent(self: *Self, io: std.Io, viewport: Viewport_t) vk.VkViewport {
    self.mutex.lock(io) catch unreachable;
    defer self.mutex.unlock(io);

    return self.array.items[Handles.getIndex(viewport)];
}
