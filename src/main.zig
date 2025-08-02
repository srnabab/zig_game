const std = @import("std");
const process = std.process;

const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const SDL_CheckResult = @import("sdlError.zig").SDL_CheckResult;

const Thread = std.Thread;
const builtin = @import("builtin");
const output = @import("output");
const log = std.log;
const ECS = @import("ECS");
const steam = @import("steam_C//SteamC.zig");
const steamInner = steam.steamInner;

const update = @import("update.zig");
const render = @import("render.zig");

const gpaType = @TypeOf(std.heap.GeneralPurposeAllocator(.{}).init);
const Allocator = std.mem.Allocator;

var thread_count: usize = 0;
var update_thread: usize = 0;
var render_thread: usize = 0;

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

    thread_count = try Thread.getCpuCount();
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
    update_thread = thread_used_count / 2;
    render_thread = thread_used_count - update_thread;
    log.info("logical core count: {d}", .{thread_count});
    log.info("core will be used count: {d}", .{thread_used_count});
    log.info("update thread count {d}", .{update_thread});
    log.info("render thread count {d}", .{render_thread});

    try SDL_CheckResult(sdl.SDL_Init(sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_AUDIO | sdl.SDL_INIT_GAMEPAD));

    if (steamInner.SteamAPI_RestartAppIfNecessary_C(@as(u32, steamInner.k_uAppIdInvalid_C))) {
        return error.SteamError;
    }
    if (!steamInner.SteamAPI_Init_C()) {
        return error.SteamError;
    }
    defer steamInner.SteamAPI_Shutdown_C();

    var achievements = steam.Achievement{
        .pUserStats = steamInner.SteamUserStats_C().?,
        .StoreStats = false,
    };
    // achievements.UnlockAchievement(@ptrCast(&steam.g_rgAchievements[1]));
    achievements.StoreStatsIfNecessary();

    var update_t = try Thread.spawn(.{ .allocator = gpa }, update.update_thread_func, .{ gpa, update_thread });
    defer update_t.join();

    var render_t = try Thread.spawn(.{ .allocator = gpa }, render.render_thread_func, .{ gpa, render_thread });
    defer render_t.join();
}
