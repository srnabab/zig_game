const std = @import("std");
const process = @import("std").process;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const vk = @cImport(@cInclude("vulkan/vulkan.h"));
const video = @import("video/initVulkan.zig");
const Thread = @import("std").Thread;
const builtin = @import("builtin");
const output = @import("output");
const log = @import("std").log;
const ECS = @import("ECS");

const gpaType = @TypeOf(std.heap.GeneralPurposeAllocator(.{}).init);
const Allocator = @import("std").mem.Allocator;

const position = struct { x: i32, y: i32 };
const PositionPool = ECS.CompentPool(position);

var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const gpa, const is_debug = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    output.init();

    const args = try process.argsAlloc(gpa);
    defer process.argsFree(gpa, args);

    for (args) |arg| {
        try output.out.print("arg: {s}\n", .{arg});
    }

    var testPool = PositionPool.init(gpa);
    defer testPool.deinit();
    const testEntity1 = ECS.Entity.createEntity();
    const testEntity2 = ECS.Entity.createEntity();
    try testPool.register(testEntity1, position{ .x = 100, .y = 200 });
    const testData = try testPool.getData(testEntity1);

    std.debug.print("1: {d}, 2:{d}\n", .{ testEntity1.id, testEntity2.id });
    std.debug.print("x: {d}, y:{d}\n", .{ testData.x, testData.y });
    std.debug.print("{d}\n", .{testPool.sparse_array.items.len});
    std.debug.print("{d}\n", .{testPool.dense_array.items.len});
    std.debug.print("{d}\n", .{testPool.dense_entity_array.items.len});

    var vulkan = video.VkStruct.init(gpa);
    try vulkan.initVulkan();
    defer vulkan.deinit();
}
