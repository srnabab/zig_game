const std = @import("std");
const builtin = @import("builtin");

const loadmap = @import("loadmap");

const ECS = @import("ECS");
const process = @import("processRender");
const global = @import("global");
const tracy = @import("tracy");
const sdl = @import("sdl").sdl;

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
    resourceArrays: *global.ResourceArrayType,
    stateBuffering: *global.StateBufferingType,
    handles: *global.HandlesType,
    vulkan: *VkStruct,
    commands: *process.externalCommands,
    uctx: *resourceProcess.UserContext,
};

const inputProcessInterval = std.time.ns_per_ms * 5;

pub fn update_thread_func(args: Args) !void {
    const io = args.io;
    const gpa = args.gpa;
    const thread_count = args.thread_count;
    const pInput = args.pInput;
    const resourceArrays = args.resourceArrays;
    const stateBuffering = args.stateBuffering;
    const handles = args.handles;
    // const vulkan = args.vulkan;
    const meshes = &args.uctx.meshes;

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

    // const test_A = try inputFunc1.registerAction(
    //     inputTrigger1,
    //     "test_A",
    //     sdl.SDL_SCANCODE_A,
    //     null,
    //     null,
    //     false,
    // );

    const test_B = try inputFunc1.registerAction(
        inputTrigger1,
        "test_B",
        sdl.SDL_SCANCODE_B,
        null,
        null,
        false,
    );

    const test_C = try inputFunc1.registerAction(
        inputTrigger1,
        "test_C",
        sdl.SDL_SCANCODE_C,
        null,
        null,
        false,
    );

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

    var resourceArray: ResourcesQueue = .init(gpa);
    defer resourceArray.deinit();

    var nameArray: NameQueue = .init(gpa);
    defer nameArray.deinit();

    const resourceCtx = resource.ResourceCtx{
        .io = io,
        .gpa = gpa,
        .handles = handles,
        .nameArray = &nameArray,
        .mainSqlite = mainRoSqlite,
    };

    const resourceArg = ResourceThreadArgs{
        .ctx = &resourceCtx,

        .group = &resourceGroup,
        .handleArray = &databaseHandleArray,
        .handleMutex = &handleMutex,
        .vulkan = args.vulkan,
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

    var sceneChanged = true;

    var lastMouseX: f32 = 0;
    var lastMouseY: f32 = 0;

    // const rng_impl: std.Random.IoSource = .{ .io = io };
    // const rng = rng_impl.interface();

    // var testBoxPng: ?Handle = null;

    var inputs: []input.Input = &.{};
    var lastTimestamp = sdl.SDL_GetTicksNS();

    var accumulateTime: u64 = 0;
    var testHandle: Handle = undefined;

    _ = try resource.readResource(&resourceCtx, &.{}, "test.lMap");
    try Io.sleep(io, .fromMilliseconds(100), .real);

    out: while (true) {
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

            // if (test_A.downIsTrue()) {
            //     // sceneChanged = true;

            //     resourceArray.mutex.lockUncancelable(io);
            //     defer resourceArray.mutex.unlock(io);
            //     const ptr = try resourceArray.array.addOne();
            //     ptr.* = .{ .position2D = .{
            //         .x = @floatFromInt(rng.intRangeAtMost(i32, -400, 400)),
            //         .y = @floatFromInt(rng.intRangeAtMost(i32, -300, 300)),
            //         .width = 48,
            //         .height = 32,
            //         .depth = 0.1,
            //         .texture = @ptrCast(testBoxPng),
            //     } };
            // }

            if (test_B.downIsTrue()) {
                resourceArray.mutex.lockUncancelable(io);
                defer resourceArray.mutex.unlock(io);
                const ptr = try resourceArray.array.addOne();
                ptr.* = .{ .instance = .{
                    .texture = null,
                    .pos = vec3{ 0, 0, 0 },
                    .scale = vec3{ 1, 1, 1 },
                    .rotation = vec3{ 0, 0, 0 },
                    .sampler = null,
                    .handle = handles.createHandle(Handles.WaitFill, .instance),
                } };
                testHandle = ptr.instance.handle;
            }

            if (test_C.downIsTrue()) a: {
                std.log.debug("x", .{});
                resourceArray.mutex.lockUncancelable(io);
                defer resourceArray.mutex.unlock(io);

                std.log.debug("c", .{});
                if (!Handles.handleIsValid(testHandle)) break :a;

                std.log.debug("cc", .{});
                const ptr = try resourceArray.array.addOne();
                const m = meshes.getMesh(@intCast(file.getID("Plane.001_0.vtx"))) catch {
                    _ = resourceArray.array.pop();
                    break :a;
                };
                ptr.* = .{ .meshInstance = .{
                    .instance = @ptrCast(testHandle),
                    .mesh = m,
                    .passName = "ic_task",
                } };
                // @breakpoint();
                std.log.debug("ccc", .{});
            }

            // if (test_D.downIsTrue()) {
            //     _ = try resource.readResource(
            //         &resourceCtx,
            //         &.{},
            //         "Plane.001_0.vtx",
            //     );
            //     _ = try resource.readResource(
            //         &resourceCtx,
            //         &.{},
            //         "feather_lut.ktx2",
            //     );
            // }
            try args.uctx.loadmaps.load(&resourceCtx, 0, vec2{ 0, 0 });

            if (sceneChanged) {
                sceneChanged = false;

                // std.log.debug("update: idx {d}", .{resourceArrayIndex});
                // testBoxPng = try resource.readResource(
                //     &resourceCtx,
                //     &.{},
                //     "box.png",
                // );
                // std.log.debug("box {any}", .{testBoxPng});

                resourceArray.mutex.lockUncancelable(io);
                defer resourceArray.mutex.unlock(io);
                const ptr = try resourceArray.array.addOne();
                ptr.* = .{ .position2D = .{
                    .x = 0,
                    .y = 0,
                    .width = 48,
                    .height = 32,
                    .depth = 0.1,
                    .texture = @ptrCast(resource.getResourceHandle(file.getID("box.png")) orelse unreachable),
                } };

                // resourceValue += 1;
            }

            {
                resourceArray.mutex.lockUncancelable(io);
                defer resourceArray.mutex.unlock(io);
                if (resourceArray.array.items.len > 0) {
                    const array = resourceArrays.getEmpty();

                    if (array) |a| {
                        try a.appendSlice(resourceArray.array.items);
                        resourceArrays.pushReady(a);
                        resourceArray.array.clearRetainingCapacity();
                    }
                }
            }

            const infos = stateBuffering.getWriteBuffer();
            defer stateBuffering.returnWriteBuffer(infos);

            // stateBufferValue += 1;

            if (test_Q.downIsTrue()) {
                stateBufferValue -= 1;
            }

            if (test_E.downIsTrue()) {
                stateBufferValue += 1;
            }

            try infos.append(stateBufferValue);

            accumulateTime += sdl.SDL_GetTicksNS() - lastTimestamp;

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
