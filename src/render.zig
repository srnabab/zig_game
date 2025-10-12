const std = @import("std");
const video = @import("video");
const process = @import("processRender");
const global = @import("global");
const tracy = @import("tracy");

// const drawCommandProcess = @import("video/drawCommandProcess.zig");

pub fn render_thread_func(thread_count: usize) !void {
    tracy.setThreadName("render");
    defer tracy.message("render exit");

    const zone = tracy.initZone(@src(), .{ .name = "render" });
    defer zone.deinit();

    // var vulkan = video.VkStruct.init(gpa);
    // try vulkan.initVulkan();
    // defer vulkan.deinit();

    // global.vulkan = vulkan;

    while (true) {
        if (global.down) {
            break;
        }
    }

    _ = thread_count;
}
