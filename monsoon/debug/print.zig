const std = @import("std");
const builtin = @import("builtin");

const vk = @import("vulkan");

const VkResultToError = @import("resultToError");
const vulkanType = VkResultToError.vulkanType;

const VkFormat = vulkanType.VkFormat;
const VkColorSpaceKHR = vulkanType.VkColorSpaceKHR;

pub fn printVkSurfaceFormatKHR(surfaceFormat: vk.VkSurfaceFormatKHR) void {
    const format: VkFormat = @fromBackingInt(@intCast(surfaceFormat.format));
    const colorSpace: VkColorSpaceKHR = @fromBackingInt(@intCast(surfaceFormat.colorSpace));

    switch (builtin.mode) {
        .debug, .ReleaseSafe => std.log.debug("format: {s}, colorSpace: {s}", .{ @tagName(format), @tagName(colorSpace) }),
        else => {},
    }
}
