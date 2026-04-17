const std = @import("std");
const vk = @import("vulkan");
const VkError = @import("vulkanType.zig").VkError;
pub const vulkanType = @import("vulkanType.zig");
const VkResult = vulkanType.VkResult;
pub fn VkResultToError(result: vk.VkResult) VkError!void {
    if (result < 0) {
        return VkError.VkError;
    }
}
pub fn checkVkResult(result: vk.VkResult) VkError!void {
    VkResultToError(result) catch |err| {
        std.debug.dumpCurrentStackTrace(.{});
        std.log.err("error: {s}", .{@tagName(@as(VkResult, @enumFromInt(result)))});
        return err;
    };
}
