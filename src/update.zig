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

const inputProcessInterval = std.time.ns_per_ms * 5;
const expiredTime = std.time.ns_per_ms * 40;
var debug_allocator: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;
pub fn update_thread_func(thread_count: usize, pInput: *input) !void {
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

    tracy.setThreadName("update");
    defer tracy.message("update exit");

    const zone = tracy.initZone(@src(), .{ .name = "update" });
    defer zone.deinit();

    var inputFunc1 = inputFunc.init(allocator_t.*);
    defer inputFunc1.deinit();

    var inputTrigger1 = try inputFunc1.createInputTrigger();
    defer inputTrigger1.deinit();

    const exit = try inputFunc1.registerAction(
        inputTrigger1,
        "exit",
        sdl.SDLK_ESCAPE,
        null,
        null,
        true,
    );

    var inputs: []input.Input = &.{};
    var lastTimestamp = sdl.SDL_GetTicksNS();

    var accumulateTime: u64 = 0;

    out: while (true) {
        if (accumulateTime > inputProcessInterval) {
            inputs = try pInput.getCurrentInput();
            defer {
                pInput.releaseCurrentInput(inputs);
                inputs = &.{};
            }

            if (inputs.len != 0)
                std.log.debug("input len {d}", .{inputs.len});
            for (inputs) |*value| {
                // std.log.debug("{}", .{value});

                inputTrigger1.set(value);
                std.log.debug("{}, {}, {d}", .{ exit.down, exit.pre, exit.timestamp });

                switch (value.*) {
                    .key => |key| {
                        input.logKey(@constCast(&key));

                        if (sdl.SDL_GetTicksNS() - key.timestamp > expiredTime) {
                            std.log.debug("exipred", .{});
                            continue;
                        }
                    },
                    else => {},
                }

                // if (value == .key) {
                //     if (value.key.key == sdl.SDLK_ESCAPE) {
                //         endGame();
                //     }
                // }
            }

            accumulateTime -= inputProcessInterval;
        }

        accumulateTime += sdl.SDL_GetTicksNS() - lastTimestamp;

        lastTimestamp = sdl.SDL_GetTicksNS();

        if (exit.preIsTrue()) {
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
