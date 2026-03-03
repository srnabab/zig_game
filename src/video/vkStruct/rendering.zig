const std = @import("std");

const global = @import("global");

const tracy = @import("tracy");

const vk = @import("vulkan").vulkan;
const Handles = @import("handle");
const Handle = Handles.Handle;
const getIndex = @import("handle").getIndex;

const assert = std.debug.assert;

const RenderingInfo = struct {
    start: bool = false,
    // name: [32]u8,
    flags: vk.VkRenderingFlags,
    renderArea: vk.VkRect2D,
    layerCount: u32,
    viewMask: u32,
    pColorAttachments: ?[]vk.VkRenderingAttachmentInfo,
    depthAttachment: ?[]vk.VkRenderingAttachmentInfo,
    stencilAttachment: ?[]vk.VkRenderingAttachmentInfo,
};

const Self = @This();

pub const RenderingInfo_t = Handle;

allocator: std.mem.Allocator,

array: std.array_list.Managed(RenderingInfo),
handles: *global.HandlesType,
mutex: std.Thread.Mutex = .{},

pub fn init(allocator: std.mem.Allocator, handles: *global.HandlesType) Self {
    return .{
        .allocator = allocator,
        .array = .init(allocator),
        .handles = handles,
    };
}

pub fn deinit(self: *Self) void {
    for (0..self.array.items.len) |i| {
        if (self.array.items[i].pColorAttachments != null or self.array.items[i].depthAttachment != null or self.array.items[i].stencilAttachment != null)
            self.allocator.free(self.constructSlice(@intCast(i)));
    }
    self.array.deinit();
}

pub fn createRenderingInfo(
    self: *Self,
    flags: vk.VkRenderingFlags,
    renderArea: vk.VkRect2D,
    layerCount: u32,
    viewMask: u32,
    pColorAttachments: ?[]vk.VkRenderingAttachmentInfo,
    depthAttachment: ?[]vk.VkRenderingAttachmentInfo,
    stencilAttachment: ?[]vk.VkRenderingAttachmentInfo,
) !RenderingInfo_t {
    const ptr = try self.array.addOne();

    const index = self.array.items.len - 1;

    const count = blk: {
        var s: u32 = 0;
        if (pColorAttachments) |v| s += @intCast(v.len);

        if (depthAttachment) |v| {
            assert(v.len == 1);
            s += 1;
        }

        if (stencilAttachment) |v| {
            assert(v.len == 1);
            s += 1;
        }
        break :blk s;
    };

    var attachments = try self.allocator.alloc(vk.VkRenderingAttachmentInfo, count);
    errdefer self.allocator.free(attachments);

    var depth: u32 = 0;
    var stencil: u32 = 0;
    if (pColorAttachments) |v| {
        @memcpy(attachments[0..v.len], v);
        depth = @intCast(v.len);
        stencil = @intCast(v.len);
    }

    if (depthAttachment) |v| {
        attachments[depth] = v[0];
        stencil += 1;
    }

    if (stencilAttachment) |v| {
        attachments[stencil] = v[0];
    }

    ptr.* = RenderingInfo{
        .flags = flags,
        .renderArea = renderArea,
        .layerCount = layerCount,
        .viewMask = viewMask,
        .pColorAttachments = if (pColorAttachments) |v| attachments[0..v.len] else null,
        .depthAttachment = if (depthAttachment) |_| attachments[depth..(depth + 1)] else null,
        .stencilAttachment = if (stencilAttachment) |_| attachments[stencil..(stencil + 1)] else null,
    };

    return self.handles.createHandle(@intCast(index));
}

pub fn destroyRenderingInfo(self: *Self, renderingInfo: RenderingInfo_t) void {
    const index = getIndex(renderingInfo);
    self.handles.destroyHandle(index);

    const slice = self.constructSlice(index);
    self.allocator.free(slice);

    self.array.items[index].pColorAttachments = null;
    self.array.items[index].depthAttachment = null;
    self.array.items[index].stencilAttachment = null;
}

fn constructSlice(self: *Self, index: u32) []const vk.VkRenderingAttachmentInfo {
    const slice = bk: {
        var count: u32 = 0;
        var ptr: ?[*]vk.VkRenderingAttachmentInfo = null;
        if (self.array.items[index].pColorAttachments) |v| {
            count += @intCast(v.len);
            if (ptr == null) {
                ptr = v.ptr;
            }
        }

        if (self.array.items[index].depthAttachment) |v| {
            count += @intCast(v.len);
            if (ptr == null) {
                ptr = v.ptr;
            }
        }

        if (self.array.items[index].stencilAttachment) |v| {
            count += @intCast(v.len);
            if (ptr == null) {
                ptr = v.ptr;
            }
        }

        break :bk ptr.?[0..count];
    };

    return slice;
}

pub fn renderingStarted(self: *Self, rendering: RenderingInfo_t) bool {
    const index = Handles.getIndex(rendering);

    self.mutex.lock();
    defer self.mutex.unlock();

    return self.array.items[index].start;
}

pub fn getRenderingInfo(self: *Self, rendering: RenderingInfo_t) RenderingInfo {
    self.mutex.lock();
    defer self.mutex.unlock();

    const index = Handles.getIndex(rendering);

    return self.array.items[index];
}

pub fn updateRenderingInfo(self: *Self, args: anytype, texture: RenderingInfo_t) void {
    const zone = tracy.initZone(@src(), .{ .name = "update texture" });
    defer zone.deinit();

    const args_type = @TypeOf(args);
    const args_info = @typeInfo(args_type);

    // std.log.debug("{s}", .{@typeName(args_type)});

    if (args_info != .@"struct") {
        @compileError("argument must be a struct");
    }

    self.mutex.lock();
    defer self.mutex.unlock();

    const index = Handles.getIndex(texture);
    const temp = &self.array.items[index];

    inline for (args_info.@"struct".fields) |field| {
        if (!@hasField(RenderingInfo, field.name)) {
            @compileError("struct has no field named '" ++ field.name ++ "'");
        }

        @field(temp, field.name) = @field(args, field.name);
    }
}
