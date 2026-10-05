const std = @import("std");
const builtin = @import("builtin");

const loadmap = @import("loadmap");

const ECS = @import("ECS");
const process = @import("processRender");
const global = @import("global");
const tracy = @import("tracy");
const sdl = @import("sdl").sdl;

const u8pack = @import("u8pack");
const toStr = u8pack.toStr;

const input = @import("input");
const inputRouter = @import("inputRouter");
const inputUser = @import("inputUser");

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
const Io = std.Io;
const Allocator = std.mem.Allocator;

const NameQueue = resource.NameQueue;
const DataBaseHandleArrayType = resource.DataBaseHandleArrayType;

const ResourceThreadArgs = resource.ResourceThreadArgs;

const resourceProcess = @import("resourceProcess");
const updateProcess = @import("updateProcess");

pub const Args = struct {
    io: std.Io,
    gpa: std.mem.Allocator,
    thread_count: usize,
    pInputRouter: *inputRouter,
    pInput: *input,
    stateBuffering: *global.StateBufferingType,
    handles: *global.HandlesType,
    vulkan: *VkStruct,
    commands: *process.externalCommands,
    uctx: *resourceProcess.UserContext,
    passes: *pass,
    renderQueue: *resource.ReaderQueue,
    updateQueue: *resource.ReaderQueue,
    updateEventQueue: *global.UpdateEventQueueType,
    renderEventQueue: *global.RenderEventQueueType,
};

const inputProcessInterval = std.time.ns_per_ms * 5;

pub fn update_thread_func(args: Args) !void {
    const io = args.io;
    const gpa = args.gpa;
    const thread_count = args.thread_count;
    const stateBuffering = args.stateBuffering;
    const handles = args.handles;

    const eventQueue = args.updateEventQueue;

    var tracyAllocator = tracy.TracingAllocator.initNamed("pool", gpa);
    defer tracyAllocator.deinit();
    var taa = tracyAllocator.allocator();
    const allocator_t = &taa;
    _ = allocator_t;

    tracy.setThreadName("update");
    defer tracy.message("update exit");

    const zone = tracy.initZone(@src(), .{ .name = "update" });
    defer zone.deinit();

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

    // const rng_impl: std.Random.IoSource = .{ .io = io };
    // const rng = rng_impl.interface();

    // var testBoxPng: ?Handle = null;

    var inputUsers = inputUser{
        .pInput = args.pInput,
    };

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
            if (global.pause.load(.monotonic) == 1) {
                std.atomic.spinLoopHint();
                continue;
            }

            inputUsers.update();

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
                            // const fInfo = @typeInfo(field);
                            // comptime {
                            //     var valid = false;
                            //     for (fInfo.@"struct".decls) |value| {
                            //         valid |= resource.validLoadName(value.name);
                            //     }
                            //     if (!valid) @compileError(std.fmt.comptimePrint("please check load function name in {s}", .{@typeName(field)}));
                            // }

                            args.handles.setIndex(v.handle, Handles.WaitFill);
                        }
                    },
                }
            }

            var u_it = args.renderEventQueue.iterateC();
            while (u_it.next()) |event| {
                switch (event.ptr.*) {
                    inline else => |c| {
                        c.process(io, gpa, args.handles, args.uctx) catch {
                            continue;
                        };
                    },
                }
                args.renderEventQueue.removeAt(event.index);
            }
            args.renderEventQueue.swap();

            const infos = stateBuffering.getWriteBuffer();
            defer stateBuffering.returnWriteBuffer(infos);

            if (inputUsers.getSingleUser().using(args.pInputRouter.getAction(toStr("Add"))).wasTriggered(0.1)) {
                if (!added) {
                    added = true;
                    pos = vec2{ 100, 100 };
                    testHandle = handles.createHandle(Handles.Invalid, .others);
                    try eventQueue.appendP(.{ .createTest2d = .{
                        .rdata = u8pack.toStr("sprite"),
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

            if (inputUsers.getSingleUser().using(args.pInputRouter.getAction(toStr("press_Q"))).wasTriggered(0.1)) {
                stateBufferValue -= 1;
            }

            if (inputUsers.getSingleUser().using(args.pInputRouter.getAction(toStr("press_E"))).wasTriggered(0.1)) {
                // global.stopNodeDagPrint = false;
                global.nodeChildrenAppendBreakPoint = true;
                // global.printDagToDot = true;
                stateBufferValue += 1;
            }

            try infos.append(.{ ._u32 = stateBufferValue });
            try updateProcess.process(&resourceCtx, args.uctx, eventQueue, infos);

            // const user = inputUsers.getSingleUser();

            // const test_A = args.pInputRouter.getAction(toStr("test_A"));

            // if (user.using(test_A).wasTriggered(0.05)) {
            //     // std.log.debug("a down", .{});
            //     inputUsers.setWindowRelativeMouseMode(true);
            // }
            // if (user.using(test_A).getHoldDuration()) |time| {
            //     // std.log.debug("a hold {d}s", .{time});

            //     if (time > 2.0) {
            //         // user.using(test_A).consume();
            //     }
            // }

            // ----------------------------------------------------------------------------------------------------------------------------------------

            deltaTime = sdl.SDL_GetTicksNS() - lastTimestamp;
            accumulateTime += deltaTime;

            lastTimestamp = sdl.SDL_GetTicksNS();

            if (inputUsers.getSingleUser().using(args.pInputRouter.getAction(toStr("exit"))).getHoldDuration()) |t| {
                if (t > 0.3)
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
