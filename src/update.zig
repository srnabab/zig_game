const std = @import("std");
const ECS = @import("ECS");
const process = @import("processRender");
const global = @import("global");
const tracy = @import("tracy");

const textureSet = @import("textureSet");

const DrawableC = ECS.CompentPool(process.Drawable);

pub fn update_thread_func(thread_count: usize) !void {
    tracy.setThreadName("update");
    defer tracy.message("update exit");

    const zone = tracy.initZone(@src(), .{ .name = "update" });
    defer zone.deinit();

    _ = thread_count;
}
