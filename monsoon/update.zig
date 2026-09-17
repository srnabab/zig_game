const std = @import("std");
const builtin = @import("builtin");

const loadmap = @import("loadmap");

const ECS = @import("ECS");
const process = @import("processRender");
const global = @import("global");
const tracy = @import("tracy");
const sdl = @import("sdl").sdl;

const u8pack = @import("u8pack");

const input = @import("input");
const inputFunc = @import("input/inputFunc.zig");

const textureSet = @import("textureSet");
const VkStruct = @import("video");
const ringBuffer = @import("ringBuffer");
const vertexStruct = @import("vertexStruct");
const mesh = @import("mesh");

const vec2 = vertexStruct.vec2;
const vec3 = vertexStruct.vec3;

const file = @import("fileSystem");
const resource = @import("resource");
const Handles = global.Handles;
const Handle = Handles.Handle;
const vk = VkStruct.vk;

const pass = @import("pass");
const sqlite3 = ?*file.sqlite.sqlite3;
const DrawableC = ECS.CompentPool(process.Drawable);
const Io = std.Io;
const Allocator = std.mem.Allocator;
const ResourcesQueue = resource.ResourcesQueue;

const NameQueue = resource.NameQueue;
const DataBaseHandleArrayType = resource.DataBaseHandleArrayType;

const ResourceThreadArgs = resource.ResourceThreadArgs;

const resourceProcess = @import("resourceProcess");

pub const Args = struct {
    io: std.Io,
    gpa: std.mem.Allocator,
    thread_count: usize,
    pInput: *input,
    stateBuffering: *global.StateBufferingType,
    handles: *global.HandlesType,
    vulkan: *VkStruct,
    commands: *process.externalCommands,
    uctx: *resourceProcess.UserContext,
    passes: *pass,
    renderQueue: *resource.ReaderQueue,
    updateQueue: *resource.ReaderQueue,
    updateEventQueue: *global.EventQueueType,
    renderEventQueue: *global.EventQueueType,
};

const inputProcessInterval = std.time.ns_per_ms * 5;

pub fn update_thread_func(args: Args) !void {
    const io = args.io;
    const gpa = args.gpa;
    const thread_count = args.thread_count;
    const pInput = args.pInput;
    const stateBuffering = args.stateBuffering;
    const handles = args.handles;

    const eventQueue = args.updateEventQueue;

    var tracyAllocator = tracy.TracingAllocator.initNamed("pool", gpa);
    defer tracyAllocator.deinit();
    var taa = tracyAllocator.allocator();
    const allocator_t = &taa;

    tracy.setThreadName("update");
    defer tracy.message("update exit");

    const zone = tracy.initZone(@src(), .{ .name = "update" });
    defer zone.deinit();

    var inputFunc1 = try inputFunc.init(allocator_t.*);
    defer inputFunc1.deinit();

    var inputTrigger1 = try inputFunc1.createInputTrigger();
    defer inputTrigger1.deinit();

    const exit = try inputFunc1.registerAction(
        inputTrigger1,
        "exit",
        sdl.SDL_SCANCODE_ESCAPE,
        null,
        null,
        true,
    );

    const test_A = try inputFunc1.registerAction(
        inputTrigger1,
        "test_A",
        sdl.SDL_SCANCODE_A,
        null,
        null,
        false,
    );

    // const test_B = try inputFunc1.registerAction(
    //     inputTrigger1,
    //     "test_B",
    //     sdl.SDL_SCANCODE_B,
    //     null,
    //     null,
    //     false,
    // );

    // const test_C = try inputFunc1.registerAction(
    //     inputTrigger1,
    //     "test_C",
    //     sdl.SDL_SCANCODE_C,
    //     null,
    //     null,
    //     false,
    // );

    // const test_D = try inputFunc1.registerAction(
    //     inputTrigger1,
    //     "test_D",
    //     sdl.SDL_SCANCODE_D,
    //     null,
    //     null,
    //     false,
    // );

    const test_Q = try inputFunc1.registerAction(
        inputTrigger1,
        "test_Q",
        sdl.SDL_SCANCODE_Q,
        null,
        null,
        false,
    );

    const test_E = try inputFunc1.registerAction(
        inputTrigger1,
        "test_E",
        sdl.SDL_SCANCODE_E,
        null,
        null,
        false,
    );
    // const lmap = try loadmap.loadLoadmap(gpa, &.{});
    // _ = lmap;

    var resourceGroup: Io.Group = .init;

    var rwSqlite: sqlite3 = null;
    var mainRoSqlite: sqlite3 = null;
    var handleMutex: Io.Mutex = .init;
    var databaseHandleArray: DataBaseHandleArrayType = .init();
    const dbs = try file.initManyDb(io, 8, &rwSqlite, gpa);
    defer file.deinitManyDB(rwSqlite, dbs, gpa);

    mainRoSqlite = dbs[0];
    for (dbs[1..]) |value| {
        _ = databaseHandleArray.push(value);
    }

    var nameArray: NameQueue = .init(gpa);
    defer nameArray.deinit();

    const resourceCtx = resource.ResourceCtx{
        .io = io,
        .gpa = gpa,
        .handles = handles,
        .nameArray = &nameArray,
        .mainSqlite = mainRoSqlite,
        .vulkan = args.vulkan,
        .passes = args.passes,
        .render = args.renderQueue,
        .update = args.updateQueue,
    };

    const resourceArg = ResourceThreadArgs{
        .ctx = &resourceCtx,

        .group = &resourceGroup,
        .handleArray = &databaseHandleArray,
        .handleMutex = &handleMutex,
        .externalCommands = args.commands,
        .uctx = args.uctx,
    };

    for (0..7) |_| {
        try resourceGroup.concurrent(io, resource.processResource, .{&resourceArg});
    }
    defer resourceGroup.cancel(io);

    defer resource.deinit(gpa);

    // var resourceValue: u32 = 0;

    var stateBufferValue: u32 = 0;

    var lastMouseX: f32 = 0;
    var lastMouseY: f32 = 0;

    // const rng_impl: std.Random.IoSource = .{ .io = io };
    // const rng = rng_impl.interface();

    // var testBoxPng: ?Handle = null;

    var inputs: []input.Input = &.{};
    var lastTimestamp = sdl.SDL_GetTicksNS();

    var accumulateTime: u64 = 0;
    var deltaTime: u64 = 0;
    // var testHandle: Handle = undefined;

    var added = false;
    var pos: vec2 = vec2{ 0, 0 };
    var vel: vec2 = vec2{ 0.1, 0.1 };
    var testHandle: Handle = undefined;

    _ = try resource.readResource(&resourceCtx, resourceCtx.mainSqlite, &.{}, u8pack.toStr("test.lMap"));
    try Io.sleep(io, .fromMilliseconds(200), .real);

    out: while (true) {
        const delta_time = @as(f32, @floatFromInt(deltaTime)) / std.time.ns_per_ms;
        {
            if (accumulateTime > inputProcessInterval) {
                defer accumulateTime -= inputProcessInterval;

                inputs = try pInput.getCurrentInput(io);

                for (inputs) |*value| {
                    const r = inputTrigger1.set(value);
                    if (r) continue;

                    switch (value.*) {
                        .mouse => |mouse| {
                            lastMouseX = mouse.x;
                            lastMouseY = mouse.y;
                        },
                        else => {},
                    }
                }

                try pInput.releaseCurrentInput(io, inputs);
                inputs = &.{};
            }

            while (args.updateQueue.popFirst()) |v| {
                switch (v.pointer) {
                    inline else => |pt| {
                        defer if (pt.count.fetchSub(1, .seq_cst) == 1) {
                            @TypeOf(pt.child).free(&pt.child, gpa);
                            gpa.destroy(pt);
                        };

                        const field = @TypeOf(pt.child).Parent;
                        if (@hasDecl(field, "updateLoad")) {
                            var uctx: field.Ctx = undefined;
                            const ctxInfo = @typeInfo(field.Ctx);
                            inline for (ctxInfo.@"struct".fields) |f| {
                                @field(uctx, f.name) = &@field(args.uctx, f.name);
                            }

                            const index: u32 = try field.updateLoad(io, gpa, args.vulkan, undefined, &uctx, v.handle, &pt.child);
                            args.handles.setIndex(v.handle, index);
                        } else {
                            args.handles.setIndex(v.handle, Handles.WaitFill);
                        }
                    },
                }
            }

            // ----------------------------------------------------------------------------------------------------------------------------------------
            try args.uctx.loadmaps.load(&resourceCtx, 0, vec2{ 0, 0 });

            const infos = stateBuffering.getWriteBuffer();
            defer stateBuffering.returnWriteBuffer(infos);

            if (test_A.downIsTrue()) {
                if (!added) {
                    added = true;
                    pos = vec2{ 100, 100 };
                    testHandle = handles.createHandle(Handles.Invalid, .others);
                    try eventQueue.pushLast(.{ .createTest2d = .{
                        .pos = vec3{ pos[0], pos[1], 0.1 },
                        .rotation = vec3{ 0, 0, 0 },
                        .scale = vec3{ 1.0, 1, 1 },
                        .handle = testHandle,
                    } });
                }
            }

            if (added) {
                pos[0] += vel[0] * delta_time;
                pos[1] += vel[1] * delta_time;

                if (pos[0] <= -400) {
                    pos[0] = -400.0;
                    vel[0] = -vel[0];
                } else if (pos[0] >= 400.0) {
                    pos[0] = 400.0;
                    vel[0] = -vel[0];
                }

                if (pos[1] <= -300.0) {
                    pos[1] = -300.0;
                    vel[1] = -vel[1];
                } else if (pos[1] >= 300.0) {
                    pos[1] = 300.0;
                    vel[1] = -vel[1];
                }

                try infos.append(.{ ._2d = .{ .handle = testHandle, .pos = pos } });
            }

            if (test_Q.downIsTrue()) {
                stateBufferValue -= 1;
            }

            if (test_E.downIsTrue()) {
                // global.stopNodeDagPrint = false;
                global.nodeChildrenAppendBreakPoint = true;
                // global.printDagToDot = true;
                stateBufferValue += 1;
            }

            try infos.append(.{ ._u32 = stateBufferValue });
            // ----------------------------------------------------------------------------------------------------------------------------------------

            deltaTime = sdl.SDL_GetTicksNS() - lastTimestamp;
            accumulateTime += deltaTime;

            lastTimestamp = sdl.SDL_GetTicksNS();

            if (exit.down) {
                endGame();
            }

            if (global.game_end.load(.seq_cst) == 1) {
                break :out;
            }
        }
    }

    _ = thread_count;
}

fn endGame() void {
    global.game_end.store(1, .seq_cst);
}
