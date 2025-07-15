const std = @import("std");
const process = @import("std").process;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const vk = @cImport(@cInclude("vulkan/vulkan.h"));
const video = @import("video/initVulkan.zig");
const Thread = @import("std").Thread;
const builtin = @import("builtin");
const output = @import("output");
const log = @import("std").log;

const gpaType = @TypeOf(std.heap.GeneralPurposeAllocator(.{}).init);
const Allocator = @import("std").mem.Allocator;

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

    var vulkan = video.VkStruct.init(gpa);
    try vulkan.initVulkan();
    defer vulkan.deinit();
}
