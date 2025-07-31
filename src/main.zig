const std = @import("std");
const process = std.process;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const SDL_CheckResult = @import("sdlError.zig").SDL_CheckResult;
const vk = @cImport(@cInclude("vulkan/vulkan.h"));
const video = @import("video/initVulkan.zig");
const Thread = std.Thread;
const builtin = @import("builtin");
const output = @import("output");
const log = std.log;
const ECS = @import("ECS");

const gpaType = @TypeOf(std.heap.GeneralPurposeAllocator(.{}).init);
const Allocator = std.mem.Allocator;

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

    const thread_count = try Thread.getCpuCount();
    // const thread_count: u32 = 1023;
    const thread_used_count = cot: {
        var count = thread_count;
        if (thread_count < 8) {
            count = count - 1;
        } else {
            count = count - 2;
        }
        break :cot count;
    };
    const update_thread: usize = thread_used_count / 2;
    const render_thread = thread_used_count - update_thread;
    log.info("logical core count: {d}", .{thread_count});
    log.info("core will be used count: {d}", .{thread_used_count});
    log.info("update thread count {d}", .{update_thread});
    log.info("render thread count {d}", .{render_thread});

    try SDL_CheckResult(sdl.SDL_Init(sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_AUDIO | sdl.SDL_INIT_GAMEPAD));

    var vulkan = video.VkStruct.init(gpa);
    try vulkan.initVulkan();
    defer vulkan.deinit();
}
