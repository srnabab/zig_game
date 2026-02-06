const std = @import("std");

const global = @import("global");

const vk = @import("vulkan").vulkan;
const Handle = @import("handle").Handle;
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

pub fn init(allocator: std.mem.Allocator, handles: *global.HandlesType) Self {
    return .{
        .allocator = allocator,
        .array = .init(allocator),
        .handles = handles,
    };
}

pub fn deinit(self: *Self) void {
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
        if (pColorAttachments) |v| s += v.len;

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
        depth = v.len;
        stencil = v.len;
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

    return self.handles.createHandle(index);
}

pub fn destroyRenderingInfo(self: *Self, renderingInfo: RenderingInfo_t) void {
    const index = getIndex(renderingInfo);
    self.handles.destroyHandle(index);
}
