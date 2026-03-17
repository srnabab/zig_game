const std = @import("std");

const global = @import("global");

const vk = @import("vulkan").vulkan;

const Handles = @import("handle");
const Handle = Handles.Handle;

array: std.array_list.Managed(vk.VkViewport),
pHandle: *global.HandlesType,
allocator: std.mem.Allocator,

mutex: std.Thread.Mutex = .{},

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

pub fn createViewport(self: *Self, viewport: vk.VkViewport) !Viewport_t {
    self.mutex.lock();
    defer self.mutex.unlock();

    const index = self.array.items.len;

    try self.array.append(viewport);

    return self.pHandle.createHandle(@intCast(index));
}

pub fn destroyViewport(self: *Self, viewport: Viewport_t) void {
    self.mutex.lock();
    defer self.mutex.unlock();

    // const index = Handles.getIndex(viewport);

    self.pHandle.destroyHandle(viewport);
}

pub fn getViewportContent(self: *Self, viewport: Viewport_t) vk.VkViewport {
    self.mutex.lock();
    defer self.mutex.unlock();

    return self.array.items[Handles.getIndex(viewport)];
}
