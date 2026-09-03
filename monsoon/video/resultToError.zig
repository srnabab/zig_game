const std = @import("std");
const renderDebug = @import("renderDebug");

const vk = @import("vulkan");
const VkError = @import("vulkanType").VkError;
pub const vulkanType = @import("vulkanType");
const VkResult = vulkanType.VkResult;
pub fn VkResultToError(result: vk.VkResult) VkError!void {
    if (result < 0) {
        return VkError.VkError;
    }
}
pub fn checkVkResult(result: vk.VkResult) VkError!void {
    switch (result) {
        else => {
            VkResultToError(result) catch |err| {
                std.log.err("error: {s}", .{@tagName(@as(VkResult, @enumFromInt(result)))});
                renderDebug.printToDot();
                // renderDebug.printAllInfoToTxt();
                std.debug.dumpCurrentStackTrace(.{});
                @breakpoint();
                return err;
            };
        },
    }
}
