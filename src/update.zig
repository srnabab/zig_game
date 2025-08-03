const std = @import("std");
const ECS = @import("ECS");
const process = @import("processRender.zig");
const global = @import("global.zig");

const DrawableC = ECS.CompentPool(process.Drawable);

pub fn update_thread_func(gpa: std.mem.Allocator, thread_count: usize) !void {
    std.log.info("info", .{});

    var DrawablePool = DrawableC.init(gpa);
    defer DrawablePool.deinit();

    var entites: [100]ECS.Entity = undefined;
    for (0..10) |i| {
        entites[i] = ECS.Entity.createEntity();
        if (i % 2 == 0) {
            try DrawablePool.register(entites[i], .{ .draw = false, .time = 0 });
        } else {
            try DrawablePool.register(entites[i], .{ .draw = true, .time = 0 });
        }
    }

    try process.init(gpa);
    defer process.deinit();

    // std.time.sleep(std.time.ns_per_s * 2);
    std.log.info("start", .{});
    while (true) {
        for (0..100) |_| {
            for (0..10) |i| {
                DrawablePool.dense_array.items[i].time = std.time.nanoTimestamp();
            }
            try process.addProcesses(DrawablePool.dense_array.items);
            process.processStart();
            // std.time.sleep(10);
        }
        if (global.down) {
            break;
        }
    }
    // std.log.info("process add end", .{});

    _ = thread_count;
    std.time.sleep(3000000000);
    std.log.info("update end", .{});
}
