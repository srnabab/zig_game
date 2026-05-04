const std = @import("std");
const builtin = @import("builtin");

const ECS = @import("ECS");
const process = @import("processRender");
const global = @import("global");
const tracy = @import("tracy");
const sdl = @import("sdl").sdl;

const input = @import("input");
const inputFunc = @import("input/inputFunc.zig");

const textureSet = @import("textureSet");

const DrawableC = ECS.CompentPool(process.Drawable);

pub const Args = struct {
    io: std.Io,
    gpa: std.mem.Allocator,
    thread_count: usize,
    pInput: *input,
};

const inputProcessInterval = std.time.ns_per_ms * 5;

pub fn update_thread_func(args: Args) !void {
    const io = args.io;
    const gpa = args.gpa;
    const thread_count = args.thread_count;
    const pInput = args.pInput;

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

    var sceneChanged = true;

    var lastMouseX: f32 = 0;
    var lastMouseY: f32 = 0;

    var inputs: []input.Input = &.{};
    var lastTimestamp = sdl.SDL_GetTicksNS();

    var accumulateTime: u64 = 0;

    out: while (true) {
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

        if (sceneChanged) {
            sceneChanged = false;
        }

        accumulateTime += sdl.SDL_GetTicksNS() - lastTimestamp;

        lastTimestamp = sdl.SDL_GetTicksNS();

        if (exit.down) {
            endGame();
        }

        if (global.game_end.load(.seq_cst) == 1) {
            break :out;
        }
    }

    _ = thread_count;
}

fn endGame() void {
    global.game_end.store(1, .seq_cst);
}
