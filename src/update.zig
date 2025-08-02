const std = @import("std");
const ECS = @import("ECS");
const process = @import("processRender.zig");

const DrawableC = ECS.CompentPool(process.Drawable);

pub fn update_thread_func(gpa: std.mem.Allocator, thread_count: usize) !void {
    std.log.info("info", .{});

    var DrawablePool = DrawableC.init(gpa);
    defer DrawablePool.deinit();

    var entites: [100]ECS.Entity = undefined;
    for (0..100) |i| {
        entites[i] = ECS.Entity.createEntity();
        if (i % 2 == 0) {
            try DrawablePool.register(entites[i], .{ .draw = false });
        } else {
            try DrawablePool.register(entites[i], .{ .draw = true });
        }
    }

    try process.init(gpa);
    defer process.deinit();

    process.processStart();
    std.log.debug("process start", .{});
    for (DrawablePool.dense_array.items) |com| {
        if (com.draw) {
            try process.addProcess(com);
        }
    }
    process.processEnd();
    std.log.debug("process end", .{});

    _ = thread_count;
    std.time.sleep(1000000000);
}
