const std = @import("std");
const process = std.process;

const assert = std.debug.assert;

const mstd = @import("ms_std");
const Queue = mstd.Queue;

const sdl = @import("sdl").sdl;
const SDL_EventType = @import("sdl").SDL_EventType;
const SDL_CheckResult = @import("sdl").SDL_CheckResult;

const Thread = std.Thread;
const builtin = @import("builtin");
const log = std.log;
// const ECS = @import("ECS");
const steam = @import("steam");
const steamInner = steam.steamInner;

const windowInfo = @import("windowInfo");
const Window = @import("window.zig");
const update = @import("update.zig");
const render = @import("render.zig");

const mesh = @import("mesh");

const tracy = @import("tracy");

const Allocator = std.mem.Allocator;

const global = @import("global");

const input = @import("input");

const VkStruct = @import("video");
const VulkanCapability = VkStruct.VulkanCapability;
const textureSet = @import("textureSet");
const resource = @import("resource");
const file = @import("fileSystem");
const pass = @import("pass");
const renderFlow = @import("renderFlow");
const setUbo = @import("setUbo");
const setPass = @import("setPass");
const ExternalCommands = @import("processRender").externalCommands;

const resourceProcess = @import("resourceProcess");
const u8pack = @import("u8pack");
const toStr = u8pack.toStr;

// const cgltf = @import("cgltf");

var handles: global.HandlesType = undefined;

var thread_count: usize = 0;
var update_thread: usize = 0;
var render_thread: usize = 0;

var debug_allocator: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;
pub fn main(init: std.process.Init) !void {
    // const gpa = init.gpa;
    const io = init.io;

    var tracyAllocator = tracy.TracingAllocator.initNamed("pool", init.gpa);
    defer tracyAllocator.deinit();

    var taa = tracyAllocator.allocator();
    const allocator_t = &taa;

    tracy.startupProfiler();
    defer tracy.shutdownProfiler();

    tracy.setThreadName("main");
    defer tracy.message("main thread exit");

    const mainZone = tracy.initZone(@src(), .{ .name = "main" });
    defer mainZone.deinit();

    const args = try init.minimal.args.toSlice(init.arena.allocator());

    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    const index = std.mem.lastIndexOf(u8, args[0], "\\").?;
    const temp = try std.Io.Dir.openDirAbsolute(init.io, args[0][0..index], .{});
    try std.process.setCurrentDir(init.io, temp);

    handles = try .init(allocator_t.*);
    defer handles.deinit(allocator_t.*);

    assert(sdl.SDL_SetHint(sdl.SDL_HINT_WINDOWS_RAW_KEYBOARD, "1"));
    try SDL_CheckResult(sdl.SDL_Init(sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_AUDIO | sdl.SDL_INIT_GAMEPAD));

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

    // if (steamInner.SteamAPI_RestartAppIfNecessary_C(@as(u32, steamInner.k_uAppIdInvalid_C))) {
    //     return error.SteamError;
    // }
    // if (!steamInner.SteamAPI_Init_C()) {
    //     return error.SteamError;
    // }
    // defer steamInner.SteamAPI_Shutdown_C();

    // var achievements = steam.Achievement{
    //     .pUserStats = steamInner.SteamUserStats_C().?,
    //     .StoreStats = false,
    // };
    // achievements.UnlockAchievement(@ptrCast(&steam.g_rgAchievements[1]));
    // achievements.StoreStatsIfNecessary();

    var stateBuffering: global.StateBufferingType = .init(allocator_t.*);
    defer stateBuffering.deinit();

    var updateEventQueue: global.UpdateEventQueueType = try .init(allocator_t.*, io);
    defer updateEventQueue.deinit();

    var renderEventQueue: global.RenderEventQueueType = try .init(allocator_t.*, io);
    defer renderEventQueue.deinit();

    var endSemaphore: std.Io.Semaphore = .{};

    var width: u32 = 0;
    var height: u32 = 0;
    const window = try Window.createWindow(&width, &height);
    defer Window.destroyWindow(window);

    var input1 = try input.init(allocator_t.*, window);
    defer input1.deinit();
    // assert(sdl.SDL_SetWindowRelativeMouseMode(window, true));

    var pTextureSet = textureSet.init(init.io, allocator_t.*, &handles);
    var vulkan = VkStruct.init(
        init.io,
        allocator_t.*,
        &handles,
        window,
        width,
        height,
    );
    {
        var tempDb: ?*file.sqlite.sqlite3 = null;
        file.init(init.io, &tempDb);
        defer file.deinit(tempDb);
        try vulkan.initVulkan(init.io, tempDb);
    }
    defer vulkan.deinit();
    errdefer pTextureSet.deinit(&vulkan);

    renderFlow.init(allocator_t.*, VulkanCapability.minUniformBufferOffsetAlignment);
    defer renderFlow.deinit();

    try setUbo.setUbo(null);
    try renderFlow.createUboBuffer(null);
    try setPass.setting(null);

    var externalCommands = ExternalCommands.init(io, allocator_t.*);
    defer externalCommands.deinit();

    try pTextureSet.createMissingTexture(
        &vulkan,
        &externalCommands,
    );

    var passes: pass = undefined;
    var passArena = std.heap.ArenaAllocator.init(allocator_t.*);
    defer passArena.deinit();
    const passAllocator = passArena.allocator();
    {
        var tempDb: ?*file.sqlite.sqlite3 = null;
        file.init(init.io, &tempDb);
        defer file.deinit(tempDb);

        passes = try pass.initFromRenderFlow(init.io, passAllocator, &vulkan, tempDb);
    }
    defer passes.deinit(passAllocator);

    for (passes.passes) |*value| {
        try value.init(&vulkan, &externalCommands, passAllocator);
    }

    {
        const ubo_ui = vulkan.buffers.getBuffer(toStr("ubo_ui"));
        const ubo_2d = vulkan.buffers.getBuffer(toStr("ubo_2d"));
        const ubo_3d = vulkan.buffers.getBuffer(toStr("ubo_3d"));

        if (ubo_ui) |b| {
            const ptr = vulkan.buffers.getBufferContent(b).pMappedData;
            const size = vulkan.buffers.getBufferSize(b);

            vulkan.uboPack[0] = .{
                .pMappedData = ptr,
                .totalSize = size,
            };
        }

        if (ubo_2d) |b| {
            const ptr = vulkan.buffers.getBufferContent(b).pMappedData;
            const size = vulkan.buffers.getBufferSize(b);

            vulkan.uboPack[1] = .{
                .pMappedData = ptr,
                .totalSize = size,
            };
        }

        if (ubo_3d) |b| {
            const ptr = vulkan.buffers.getBufferContent(b).pMappedData;
            const size = vulkan.buffers.getBufferSize(b);

            vulkan.uboPack[2] = .{
                .pMappedData = ptr,
                .totalSize = size,
            };
        }
    }

    // for (vulkan.uboDynamicOffsets) |value| {
    //     std.log.debug("offset {d}", .{value});
    // }
    const uctx = try allocator_t.create(resourceProcess.UserContext);
    defer allocator_t.destroy(uctx);

    uctx.* = try resourceProcess.UserContext.initUserContext(io, allocator_t.*, &vulkan, &handles, &passes, &externalCommands);
    defer uctx.deinitUserContext(allocator_t.*);

    uctx.pTextureSet = pTextureSet;
    defer uctx.pTextureSet.deinit(&vulkan);

    pTextureSet = undefined;

    var renderQueue = try resource.ReaderQueue.init(allocator_t.*, io);
    defer renderQueue.deinit();

    var updateQueue = try resource.ReaderQueue.init(allocator_t.*, io);
    defer updateQueue.deinit();

    var render_t = try Thread.spawn(
        .{},
        render.render_thread_func,
        .{render.Args{
            .io = init.io,
            .gpa = allocator_t.*,
            .thread_count = render_thread,
            .endSemaphore = &endSemaphore,
            .handles = &handles,
            .window = window,
            .width = width,
            .height = height,
            .stateBuffering = &stateBuffering,
            .vulkan = &vulkan,
            .passes = &passes,
            .uctx = uctx,
            .externalCommands = &externalCommands,
            .renderQueue = &renderQueue,
            .renderEventQueue = &renderEventQueue,
            .updateEventQueue = &updateEventQueue,
        }},
    );
    defer render_t.join();

    global.game_end.store(0, .seq_cst);

    var update_t = try Thread.spawn(
        .{},
        update.update_thread_func,
        .{update.Args{
            .io = init.io,
            .gpa = allocator_t.*,
            .thread_count = update_thread,
            .pInput = &input1,
            .stateBuffering = &stateBuffering,
            .handles = &handles,
            .vulkan = &vulkan,
            .uctx = uctx,
            .commands = &externalCommands,
            .passes = &passes,
            .renderQueue = &renderQueue,
            .updateQueue = &updateQueue,
            .renderEventQueue = &renderEventQueue,
            .updateEventQueue = &updateEventQueue,
        }},
    );
    defer update_t.join();

    while (true) {
        var e: sdl.SDL_Event = undefined;
        while (sdl.SDL_Event.SDL_PollEvent(&e)) {
            const eventType: SDL_EventType = @enumFromInt(e.type);

            switch (eventType) {
                // be careful with there, should be sync with setInput
                .SDL_EVENT_KEY_DOWN, .SDL_EVENT_KEY_UP, .SDL_EVENT_MOUSE_MOTION, .SDL_EVENT_MOUSE_BUTTON_DOWN, .SDL_EVENT_MOUSE_BUTTON_UP => {
                    try input1.setInput(io, &e);
                },
                .SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED => {
                    windowInfo.setWidth(@intCast(e.window.data1));
                    windowInfo.setHeight(@intCast(e.window.data2));

                    global.pause.store(1, .release);
                    global.render.store(0, .release);

                    std.log.info("SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED occured {d}", .{e.window.timestamp});
                },
                .SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED => {
                    std.log.info("SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED occured {d}", .{e.window.timestamp});
                },
                .SDL_EVENT_WINDOW_SHOWN => {
                    std.log.info("SDL_EVENT_WINDOW_SHOWN occured {d}", .{e.window.timestamp});
                },
                .SDL_EVENT_WINDOW_FOCUS_GAINED => {
                    std.log.info("SDL_EVENT_WINDOW_FOCUS_GAINED occured {d}", .{e.window.timestamp});
                },
                .SDL_EVENT_WINDOW_FOCUS_LOST => {
                    std.log.info("SDL_EVENT_WINDOW_FOCUS_LOST occured {d}", .{e.window.timestamp});
                },
                .SDL_EVENT_WINDOW_EXPOSED => {
                    std.log.info("SDL_EVENT_WINDOW_EXPOSED occured {d}", .{e.window.timestamp});
                },
                .SDL_EVENT_WINDOW_MOUSE_ENTER => {
                    std.log.info("SDL_EVENT_WINDOW_MOUSE_ENTER occured {d}", .{e.window.timestamp});
                },
                .SDL_EVENT_WINDOW_MOUSE_LEAVE => {
                    std.log.info("SDL_EVENT_WINDOW_MOUSE_LEAVE occured {d}", .{e.window.timestamp});
                },
                .SDL_EVENT_WINDOW_MINIMIZED => {
                    std.log.info("SDL_EVENT_WINDOW_MINIMIZED occured {d}", .{e.adevice.timestamp});
                },
                .SDL_EVENT_WINDOW_RESTORED => {
                    std.log.info("SDL_EVENT_WINDOW_RESTORED occured {d}", .{e.adevice.timestamp});
                },
                .SDL_EVENT_WINDOW_MOVED => {
                    std.log.info("SDL_EVENT_WINDOW_MOVED occured {d}", .{e.adevice.timestamp});
                },
                .SDL_EVENT_WINDOW_CLOSE_REQUESTED => {
                    std.log.info("SDL_EVENT_WINDOW_CLOSE_REQUESTED occured {d}", .{e.adevice.timestamp});
                },
                .SDL_EVENT_QUIT => {
                    // std.log.info("SDL_EVENT_QUIT occured {d}", .{e.adevice.timestamp});
                    global.game_end.store(1, .monotonic);
                },
                .SDL_EVENT_CLIPBOARD_UPDATE => {
                    std.log.info("SDL_EVENT_CLIPBOARD_UPDATE occured {d}", .{e.clipboard.timestamp});
                },
                .SDL_EVENT_AUDIO_DEVICE_ADDED => {
                    std.log.info("SDL_EVENT_AUDIO_DEVICE_ADDED occured {d}", .{e.adevice.timestamp});
                },
                inline else => |t| {
                    std.log.info("unsupported sdl event {s}", .{@tagName(t)});
                },
            }
        }

        if (global.game_end.load(.seq_cst) == 1) break;
    }

    endSemaphore.post(init.io);
}

// fn processInput(io: std.Io, in: *input) !void {}
