const std = @import("std");
const video = @import("video");
const process = @import("video/processRender.zig");
const global = @import("global");
const drawCommandProcess = @import("video/drawCommandProcess.zig");

pub fn render_thread_func(gpa: std.mem.Allocator, thread_count: usize) !void {
    var vulkan = video.VkStruct.init(gpa);
    try vulkan.initVulkan();
    defer vulkan.deinit();

    global.vulkan = vulkan;

    while (true) {
        if (global.down) {
            break;
        }
    }

    _ = thread_count;
    std.log.info("render end", .{});
}

pub fn process_thread_func() !void {
    drawCommandProcess.init(global.gpa);
    defer drawCommandProcess.deinit();

    while (true) {
        try process.process();
        if (global.down) {
            break;
        }
    }
    std.log.info("render process end", .{});
}
