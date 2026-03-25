const std = @import("std");
const process = std.process;

const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const SDL_CheckResult = @import("sdl").SDL_CheckResult;

const Thread = std.Thread;
const builtin = @import("builtin");
const output = @import("output");
const log = std.log;
const ECS = @import("ECS");
const steam = @import("steam");
const steamInner = steam.steamInner;

const Window = @import("window.zig");
const update = @import("update.zig");
const render = @import("render.zig");
const math = @import("math");

const file = @import("fileSystem");

const tracy = @import("tracy");

const Allocator = std.mem.Allocator;

const global = @import("global");

var handles: global.HandlesType = undefined;

var thread_count: usize = 0;
var update_thread: usize = 0;
var render_thread: usize = 0;

var debug_allocator: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;
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
    var tracyAllocator = tracy.TracingAllocator.initNamed("pool", gpa);
    defer tracyAllocator.deinit();
    var taa = tracyAllocator.allocator();
    const allocator_t = &taa;

    tracy.startupProfiler();
    defer tracy.shutdownProfiler();

    tracy.setThreadName("main");
    defer tracy.message("main thread exit");

    const mainZone = tracy.initZone(@src(), .{ .name = "main" });
    defer mainZone.deinit();

    output.init();

    const args = try process.argsAlloc(allocator_t.*);
    defer process.argsFree(allocator_t.*, args);

    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    const index = std.mem.lastIndexOf(u8, args[0], "\\").?;
    var temp = try std.fs.openDirAbsolute(args[0][0..index], .{});
    try temp.setAsCwd();

    handles = try .init(gpa);
    defer handles.deinit(gpa);

    file.init();
    defer file.deinit();

    {
        const zone = tracy.initZone(@src(), .{ .name = "init SDL" });
        defer zone.deinit();

        try SDL_CheckResult(sdl.SDL_Init(sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_AUDIO | sdl.SDL_INIT_GAMEPAD));
    }
    defer sdl.SDL_Quit();
    std.log.debug("SDL Version: {d}.{d}.{d}", .{
        sdl.SDL_MAJOR_VERSION,
        sdl.SDL_MINOR_VERSION,
        sdl.SDL_MICRO_VERSION,
    });

    thread_count = try Thread.getCpuCount();
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
    std.log.info("cache line {d}", .{std.atomic.cache_line});

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
    achievements.UnlockAchievement(@ptrCast(&steam.g_rgAchievements[1]));
    achievements.StoreStatsIfNecessary();

    var endSemaphore: std.Thread.Semaphore = .{};

    var update_t = try Thread.spawn(.{}, update.update_thread_func, .{update_thread});
    defer update_t.join();

    var width: u32 = 0;
    var height: u32 = 0;
    const window = try Window.createWindow(&width, &height);
    defer Window.destroyWindow(window);

    var render_t = try Thread.spawn(
        .{},
        render.render_thread_func,
        .{
            render_thread,
            &endSemaphore,
            &handles,
            window,
            width,
            height,
        },
    );
    defer render_t.join();

    endSemaphore.post();
}
