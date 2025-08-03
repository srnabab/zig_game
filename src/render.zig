const std = @import("std");
const video = @import("video/initVulkan.zig");
const process = @import("processRender.zig");
const global = @import("global.zig");

pub fn render_thread_func(gpa: std.mem.Allocator, thread_count: usize) !void {
    var vulkan = video.VkStruct.init(gpa);
    try vulkan.initVulkan();
    defer vulkan.deinit();

    while (true) {
        try process.process();
        if (global.down) {
            break;
        }
    }

    _ = thread_count;
    std.log.info("render end", .{});
}
