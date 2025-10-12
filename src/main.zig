const std = @import("std");
const process = std.process;

const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const SDL_CheckResult = @import("sdlError").SDL_CheckResult;

const Thread = std.Thread;
const builtin = @import("builtin");
const output = @import("output");
const log = std.log;
const ECS = @import("ECS");
const steam = @import("steam");
const steamInner = steam.steamInner;
const textureSet = @import("textureSet");

const update = @import("update.zig");
const render = @import("render.zig");
const VkStruct = @import("video");
const OneTimeCommand = @import("processRender").oneTimeCommand;

const file = @import("fileSystem");

const tracy = @import("tracy");

const gpaType = @TypeOf(std.heap.GeneralPurposeAllocator(.{}).init);
const Allocator = std.mem.Allocator;

const global = @import("global");
const assert = std.debug.assert;

const StackMemorySize = 512 * 1024;

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
    global.gpa = &taa;

    tracy.startupProfiler();
    defer tracy.shutdownProfiler();

    tracy.setThreadName("main");
    defer tracy.message("main thread exit");

    const mainZone = tracy.initZone(@src(), .{ .name = "main" });
    defer mainZone.deinit();

    var stackMemory = [_]u8{0} ** StackMemorySize;
    var stackAllocator = std.heap.FixedBufferAllocator.init(stackMemory[0..]);
    const sma = stackAllocator.allocator();

    output.init();

    const args = try process.argsAlloc(global.gpa.*);
    defer process.argsFree(global.gpa.*, args);

    for (args) |arg| {
        // try output.out.print("arg: {s}\n", .{arg});
        std.log.info("arg: {s}", .{arg});
    }

    {
        const zone = tracy.initZone(@src(), .{ .name = "set cwd" });
        defer zone.deinit();

        const index = std.mem.lastIndexOf(u8, args[0], "\\").?;
        global.cwd = try std.fs.openDirAbsolute(args[0][0..index], .{});
        try global.cwd.setAsCwd();
    }

    file.init();
    defer file.deinit();

    {
        const zone = tracy.initZone(@src(), .{ .name = "init SDL" });
        defer zone.deinit();

        try SDL_CheckResult(sdl.SDL_Init(sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_AUDIO | sdl.SDL_INIT_GAMEPAD));
    }
    defer sdl.SDL_Quit();

    var vulkan = VkStruct.init(global.gpa.*);
    try vulkan.initVulkan();
    defer vulkan.deinit();

    global.vulkan = &vulkan;
    var graphic = OneTimeCommand.init(global.gpa.*, sma);
    global.graphic = &graphic;
    defer global.graphic.deinit();

    var textureSett = textureSet.init(global.gpa.*);
    global.textureSet = &textureSett;
    defer global.textureSet.deinit();

    try global.graphic.startCommand();
    _ = global.textureSet.createImageTexture(comptime file.comptimeGetID("circle.png")) catch pi: {
        break :pi try global.textureSet.createImageTexture(comptime file.comptimeGetID("non_exist.png"));
    };
    try global.graphic.addCommandEnd();
    try global.graphic.executeCommands();

    try vulkan.readPipelineFileAndAdd(comptime file.comptimeGetID("model3d.pipeb"));
    try vulkan.readPipelineFileAndAdd(comptime file.comptimeGetID("flat2d.pipeb"));

    try vulkan.createAllPipelinesAdded();

    const renderStart = std.time.milliTimestamp();
    while (true) {
        if (std.time.milliTimestamp() - renderStart > 2000) {
            break;
        }
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

    var update_t = try Thread.spawn(.{}, update.update_thread_func, .{update_thread});
    defer update_t.join();

    var render_t = try Thread.spawn(.{}, render.render_thread_func, .{render_thread});
    defer render_t.join();

    global.down = true;
}
