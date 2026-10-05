const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const atomic = std.atomic;

const assert = std.debug.assert;

const builtin = @import("builtin");

const windowsInfo = @import("windowInfo");

const inputRegister = @import("inputRegister");

const input = @import("input");
const InputType = input.InputType;

const u8pack = @import("u8pack");
const Str = u8pack.Str;

const sdl = @import("sdl").sdl;
const SDL_GetTicksNS = sdl.SDL_GetTicksNS;

const u32Max = std.math.maxInt(u32);

const Key = struct {
    key: u32,
    exceptDown: bool,
};
const MouseMotion = struct {
    empty: u32 = 0,
};
const MouseButton = struct {
    button: u32,
    exceptDown: bool,
};
const GamepadAxis = struct {
    axis: u32,
    deadzone: i16,
};
const GamepadButton = struct {
    button: u32,
    exceptDown: bool,
};
const MouseWheel = struct {
    directionUp: bool,
};

const Input = union(InputType) {
    key: Key,
    mouseMotion: MouseMotion,
    mouseButton: MouseButton,
    mouseWheel: MouseWheel,
    gamepadAxis: GamepadAxis,
    gamepadButton: GamepadButton,
};

pub const InputAction = struct {
    name: Str,

    /// mouse, key | gamepad
    inputs: []Input,

    consumeCache: []*std.atomic.Value(u32),
    seqs: []u32,

    lastConsumedID: u32 = 0,

    count: u32,
    split: u32,

    startTimestamp: u64 = 0,

    strictSeq: bool,
    isPulse: bool,
    needValue: bool,
    isCamera: bool,

    canConsume: bool,
    gamepadStartTimeSeted: bool,
    mouseStartTimeSeted: bool,

    lastMouseMoveTime: u64 = 0,
    lastAxisValue: i16 = 0,

    parent: *input,

    const checkPack = struct {
        inputs: []Input,
        mappedCount: u32 = 0,
        duration: u64,
        keyboradID: u32,
        mouseID: u32,
        gamepadID: u32,
        strictSeq: bool,
        idC: *u32,
        idR: u32,
        idB: u32,
        parent: *input,
        lastMouseMoveTime: u64 = 0,
        lastAxisValue: i16 = 0,
        // checkTime: u64,
    };

    pub fn wasTriggered(
        self: *InputAction,
        duration: f32,
        keyboradID: u32,
        mouseID: u32,
        gamepadID: u32,
    ) bool {
        // const start = SDL_GetTicksNS();

        const inputs = if (gamepadID == u32Max) self.inputs[0..self.split] else self.inputs[self.split..self.count];

        if (inputs.len == 0) return false;
        // for (inputs) |value| {
        //     std.log.debug("{d}, {}", .{ value.key.key, value.key.exceptDown });
        // }
        // std.log.debug("start", .{});

        var check = checkPack{
            .inputs = inputs,
            .duration = @intFromFloat(duration * std.time.ns_per_s),
            .strictSeq = self.strictSeq,
            .keyboradID = keyboradID,
            .mouseID = mouseID,
            .gamepadID = gamepadID,
            .idC = &self.lastConsumedID,
            .idR = u32Max,
            .idB = u32Max,
            .parent = self.parent,
            .lastMouseMoveTime = self.lastMouseMoveTime,
            .lastAxisValue = self.lastAxisValue,
            // .checkTime = SDL_GetTicksNS(),
        };
        const res = self.parent.stream.traverseFromTail(&check, checkFn);

        self.lastMouseMoveTime = check.lastMouseMoveTime;
        self.lastAxisValue = check.lastAxisValue;

        // std.log.debug("cost: {d}", .{SDL_GetTicksNS() - start});
        return res;
    }

    fn checkFn(self: *checkPack, data: *const input.Input) [2]bool {
        var res: [2]bool = .{ false, false };

        // if (self.mappedCount > 0) std.log.debug("{d}", .{self.mappedCount});

        if (self.idC.* >= data.id) {
            res[0] = true;

            if (self.idR != u32Max) {
                res[1] = true;
                self.idC.* = self.idR;
            }
            return res;
        }

        const time = SDL_GetTicksNS();
        if (time - data.timestamp > self.duration) {
            // std.log.debug("{d} {d} range: {d}, need: {d}", .{ time, data.timestamp, time - data.timestamp, self.duration });
            res[0] = true;

            if (self.idR != u32Max) {
                res[1] = true;
                self.idC.* = self.idR;
            }

            return res;
        }

        const idx = if (self.strictSeq) self.inputs.len - self.mappedCount - 1 else v: while (true) {
            for (self.inputs, 0..) |value, i| {
                const b: u5 = @intCast(i);
                const a: u32 = 1;
                const bit = a << b;

                if (self.mappedCount & bit > 0) continue;

                if (std.meta.activeTag(data.input) == std.meta.activeTag(value)) {
                    std.log.debug("idx: {d}", .{i});

                    break :v i;
                }
            }

            return res;
        };

        if (std.meta.activeTag(data.input) != std.meta.activeTag(self.inputs[idx])) {
            if (self.idR != u32Max) {
                res[1] = true;
                self.idC.* = self.idR;
            }

            return res;
        }

        var canSet = false;

        a: switch (data.input) {
            .key => |k| {
                if (data.hardwareID != self.keyboradID) {
                    break :a;
                }
                if (k.key != self.inputs[idx].key.key) {
                    break :a;
                }
                if (k.down != self.inputs[idx].key.exceptDown) {
                    break :a;
                }
                if (k.repeat) {
                    break :a; // std.log.debug("{d} : {d}", .{ self.repeatCount, self.inputs.len });
                }

                canSet = true;
            },
            .gamepadButton => |g| {
                if (data.hardwareID != self.gamepadID) {
                    break :a;
                }
                if (g.button != self.inputs[idx].gamepadButton.button) {
                    break :a;
                }
                if (g.down != self.inputs[idx].gamepadButton.exceptDown) {
                    break :a;
                }

                canSet = true;
            },
            .mouseButton => |m| {
                if (data.hardwareID != self.mouseID) {
                    break :a;
                }
                if (m.button != self.inputs[idx].mouseButton.button) {
                    break :a;
                }
                if (m.down != self.inputs[idx].mouseButton.exceptDown) {
                    break :a;
                }

                canSet = true;
            },
            .mouseMotion => {
                if (data.hardwareID != self.mouseID) {
                    break :a;
                }

                if (data.timestamp <= 100 * std.time.ns_per_ms + self.lastMouseMoveTime) {
                    self.lastMouseMoveTime = @max(data.timestamp, self.lastMouseMoveTime);
                    break :a;
                }
                self.lastMouseMoveTime = data.timestamp;

                canSet = true;
            },
            // this branch will never be
            .gamepadAxis => |g| {
                if (data.hardwareID != self.gamepadID) {
                    break :a;
                }
                if (@as(u32, g.axis) != self.inputs[idx].gamepadAxis.axis) {
                    break :a;
                }
                // axis is "pressed" only when its value leaves the deadzone
                if (@abs(g.value) <= @abs(self.inputs[idx].gamepadAxis.deadzone)) {
                    self.lastAxisValue = g.value;
                    break :a;
                }

                if (@abs(self.lastAxisValue) > @abs(self.inputs[idx].gamepadAxis.deadzone)) {
                    break :a;
                }
                self.lastAxisValue = g.value;

                canSet = true;
            },
            .mouseWheel => |w| {
                if (data.hardwareID != self.mouseID) {
                    break :a;
                }

                if (self.inputs[idx].mouseWheel.directionUp) {
                    if (w.y < 0) break :a;
                } else if (w.y > 0) break :a;

                canSet = true;
            },
        }

        if (canSet) {
            if (self.strictSeq) {
                self.mappedCount += 1;
                if (self.mappedCount == 1) {
                    self.idB = data.id;
                }

                const accCount = getAccCount(
                    self.inputs[0..idx],
                    self.parent,
                    self.keyboradID,
                    self.mouseID,
                    self.gamepadID,
                    data.timestamp,
                );

                if (accCount + self.mappedCount == self.inputs.len) self.mappedCount = @intCast(self.inputs.len);

                if (self.mappedCount == self.inputs.len) {
                    // std.log.debug("find: {d}", .{SDL_GetTicksNS()});
                    self.idR = self.idB;
                    self.mappedCount = 0;
                    res[1] = true;
                }
            } else {
                // const b: u5 = @intCast(idx);
                // const a: u32 = 1;
                // const bit = a << b;

                // self.mappedCount |= bit;
                // if (@popCount(self.mappedCount) == 1) {
                //     self.idB = data.id;
                // }

                // var accCount = getAccCount(
                //     self.inputs[0..idx],
                //     self.parent,
                //     self.keyboradID,
                //     self.mouseID,
                //     self.gamepadID,
                //     data.timestamp,
                // );

                // accCount += getAccCount(
                //     self.inputs[idx + 1 ..],
                //     self.parent,
                //     self.keyboradID,
                //     self.mouseID,
                //     self.gamepadID,
                //     data.timestamp,
                // );

                // if (accCount + @popCount(self.mappedCount) == self.inputs.len) {
                //     const mask_b: u5 = @intCast(self.inputs.len);
                //     const mask = a << mask_b - 1;

                //     self.mappedCount |= mask;
                // }
                std.debug.panic("any sequence not supported", .{});
            }
        }

        if (self.idR != u32Max) {
            res[1] = true;
            self.idC.* = self.idR;
        }

        return res;
    }

    fn getAccCount(
        inputs: []Input,
        parent: *input,
        keyboradID: u32,
        mouseID: u32,
        gamepadID: u32,
        timestamp: u64,
    ) u32 {
        var accCount: u32 = 0;
        for (inputs) |in| {
            switch (in) {
                .key => |k_in| {
                    const index = parent.findHardwareIndex2(true, false, false, keyboradID) orelse break;
                    const State = &parent.keyboardState[index].keys[k_in.key];

                    const state = State.getStateAndTimestamp();

                    if (state.state == .released) break;
                    if (state.timestamp > timestamp) break;

                    accCount += 1;
                },
                .gamepadButton => |k_in| {
                    const index = parent.findHardwareIndex2(false, false, true, gamepadID) orelse break;
                    const State = &parent.gamepadState[index].gamepadButtons[k_in.button];

                    const state = State.getStateAndTimestamp();

                    if (state.state == .released) break;
                    if (state.timestamp > timestamp) break;

                    accCount += 1;
                },
                .mouseButton => |k_in| {
                    const index = parent.findHardwareIndex2(false, true, false, mouseID) orelse break;
                    const State = &parent.mouseState[index].mouseButtons[k_in.button];

                    const state = State.getStateAndTimestamp();

                    if (state.state == .released) break;
                    if (state.timestamp > timestamp) break;

                    accCount += 1;
                },
                .gamepadAxis => |k_in| {
                    const index = parent.findHardwareIndex2(false, false, true, gamepadID) orelse break;
                    const State = &parent.gamepadState[index].gamepadAxis[k_in.axis];

                    const state = State.getTimestampAndValue();

                    if (@abs(state.value) <= @abs(k_in.deadzone)) break;
                    if (state.timestamp > timestamp) break;

                    accCount += 1;
                },
                else => break,
            }
        }

        return accCount;
    }

    pub fn getHoldDuration(self: *InputAction, keyboradID: u32, mouseID: u32, gamepadID: u32) ?f32 {
        const start = if (gamepadID == u32Max) 0 else self.split;
        const end = if (gamepadID == u32Max) self.split else self.count;

        const inputs = self.inputs[start..end];

        if (inputs.len == 0) return null;

        const consumes = self.consumeCache[start..end];
        const seqs = self.seqs[start..end];

        var gamepadAxisNullCount: u8 = 0;
        var gamepadAxisCount: u8 = 0;

        var startTime: u64 = 0;

        // self.canConsume = false;

        for (inputs, consumes, seqs) |in, *co, *se| {
            switch (in) {
                .key => |k| {
                    const index = self.parent.findHardwareIndex2(true, false, false, keyboradID) orelse return null;
                    const State = &self.parent.keyboardState[index].keys[k.key];

                    const consumeID = State.consumedID.load(.acquire);
                    if (consumeID != u32Max) {
                        if (self.isPulse) {
                            if (consumeID != self.name.id) {
                                // std.log.debug("id return {d} : {f}", .{ consumeID, self.name });
                                return null;
                            }
                        } else {
                            return null;
                        }
                    }

                    var state: input.State = undefined;
                    var timestamp: u64 = 0;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        state = State.state;
                        timestamp = State.timestamp;
                        se.* = State.generation;

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    if (state != .held) return null;

                    startTime = @max(timestamp, startTime, self.startTimestamp);
                    co.* = &State.consumedID;
                    self.canConsume = false;
                },
                .gamepadButton => |g| {
                    const index = self.parent.findHardwareIndex2(false, false, true, gamepadID) orelse return null;
                    const State = &self.parent.gamepadState[index].gamepadButtons[g.button];

                    const consumeID = State.consumedID.load(.acquire);
                    if (consumeID != u32Max) {
                        if (self.isPulse) {
                            if (consumeID != self.name.id) {
                                return null;
                            }
                        } else {
                            return null;
                        }
                    }

                    var state: input.State = undefined;
                    var timestamp: u64 = 0;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        state = State.state;
                        timestamp = State.timestamp;
                        se.* = State.generation;

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    if (state != .held) return null;

                    startTime = @max(timestamp, startTime, self.startTimestamp);
                    co.* = &State.consumedID;
                    self.canConsume = false;
                },
                .mouseButton => |m| {
                    const index = self.parent.findHardwareIndex2(false, true, false, mouseID) orelse return null;
                    const State = &self.parent.mouseState[index].mouseButtons[m.button];

                    const consumeID = State.consumedID.load(.acquire);
                    if (consumeID != u32Max) {
                        if (self.isPulse) {
                            if (consumeID != self.name.id) {
                                return null;
                            }
                        } else {
                            return null;
                        }
                    }

                    var state: input.State = undefined;
                    var timestamp: u64 = 0;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        state = State.state;
                        timestamp = State.timestamp;
                        se.* = State.generation;

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    if (state != .held) return null;

                    startTime = @max(timestamp, startTime, self.startTimestamp);
                    co.* = &State.consumedID;
                    self.canConsume = false;
                },
                .gamepadAxis => |g| {
                    const index = self.parent.findHardwareIndex2(false, false, true, gamepadID) orelse return null;
                    const State = &self.parent.gamepadState[index].gamepadAxis[g.axis];

                    gamepadAxisCount += 1;

                    const res = State.getTimestampAndValue();
                    if (@abs(res.value) < @abs(g.deadzone)) {
                        // self.gamepadStartTimeSeted = false;

                        gamepadAxisNullCount += 1;
                    }
                    // if (SDL_GetTicksNS() - res.timestamp > 100 * std.time.ns_per_ms) {
                    //     self.gamepadStartTimeSeted = false;
                    //     return null;
                    // }

                    if (!self.gamepadStartTimeSeted) {
                        self.startTimestamp = @max(res.timestamp, self.startTimestamp);
                    }

                    startTime = @max(startTime, self.startTimestamp);
                },
                .mouseMotion => {
                    const index = self.parent.findHardwareIndex2(false, true, false, mouseID) orelse return null;
                    const State = &self.parent.mouseState[index].mouseMotion;

                    const timestamp = State.getTimestamp();

                    if (SDL_GetTicksNS() - timestamp > 100 * std.time.ns_per_ms) {
                        self.mouseStartTimeSeted = false;
                        return null;
                    }

                    if (!self.isPulse and !self.canConsume and self.mouseStartTimeSeted) return null;

                    if (!self.mouseStartTimeSeted) {
                        self.startTimestamp = @max(timestamp, self.startTimestamp);
                        self.mouseStartTimeSeted = true;
                    }

                    startTime = @max(startTime, self.startTimestamp);
                },
                else => std.debug.panic("not supported input {s}", .{@tagName(std.meta.activeTag(in))}),
            }
        }

        if (gamepadAxisCount != 0) {
            if (gamepadAxisCount == gamepadAxisNullCount) {
                self.gamepadStartTimeSeted = false;
                self.canConsume = false;

                return null;
            }

            if (!self.isPulse and !self.canConsume and self.gamepadStartTimeSeted) {
                return null;
            }
        }

        self.canConsume = true;
        self.gamepadStartTimeSeted = true;

        return @as(f32, @floatFromInt(SDL_GetTicksNS() - startTime)) / std.time.ns_per_s;
    }

    pub fn consume(self: *InputAction, isGamepad: bool) void {
        if (!self.canConsume) return;

        const start = if (!isGamepad) 0 else self.split;
        const end = if (!isGamepad) self.split else self.count;

        const inputs = self.inputs[start..end];

        if (inputs.len == 0) return;

        const consumes = self.consumeCache[start..end];
        const seqs = self.seqs[start..end];

        for (inputs, consumes, seqs) |in, co, se| {
            switch (in) {
                .key => {
                    const State: *input.KeyState = @alignCast(@fieldParentPtr("consumedID", co));

                    if (State.getGeneration() == se) co.store(self.name.id, .release);
                    if (self.isPulse) self.startTimestamp = SDL_GetTicksNS();
                },
                .gamepadButton => {
                    const State: *input.GamePadButtonState = @alignCast(@fieldParentPtr("consumedID", co));

                    if (State.getGeneration() == se) co.store(self.name.id, .release);
                    if (self.isPulse) self.startTimestamp = SDL_GetTicksNS();
                },
                .mouseButton => {
                    const State: *input.MouseButtonState = @alignCast(@fieldParentPtr("consumedID", co));

                    if (State.getGeneration() == se) co.store(self.name.id, .release);
                    if (self.isPulse) self.startTimestamp = SDL_GetTicksNS();
                },
                .gamepadAxis => {
                    if (self.isPulse) self.startTimestamp = SDL_GetTicksNS();
                    self.canConsume = false;
                },
                .mouseMotion => {
                    if (self.isPulse) self.startTimestamp = SDL_GetTicksNS();
                    self.canConsume = false;
                },
                else => std.debug.panic("not supported input {s}", .{@tagName(std.meta.activeTag(in))}),
            }
        }
    }

    /// for key and button, [0] +x, [1] -x, [2] +y, [3] -y;\
    /// for mouse, return motion;\
    /// for gamepad,  return axis [0] x, [1] -y;
    pub fn getValue2(
        self: *InputAction,
        keyboardID: u32,
        mouseID: u32,
        gamepadID: u32,
        isCamera: bool,
        mouseSens: f32,
        stickSens: f32,
        deltaTime: f32,
    ) [2]f32 {
        const start = if (gamepadID == u32Max) 0 else self.split;
        const end = if (gamepadID == u32Max) self.split else self.count;

        const inputs = self.inputs[start..end];

        var res = [2]f32{ 0, 0 };

        if (inputs.len == 0) return res;

        var ke: u32 = 0;
        var ga: u32 = 0;
        var gb: u32 = 0;

        if (!self.needValue) return res;
        // std.log.debug("aa", .{});

        var uniform = true;

        for (inputs) |in| {
            switch (in) {
                .key => |k| {
                    const index = self.parent.findHardwareIndex2(true, false, false, keyboardID) orelse return .{ 0, 0 };
                    const State = &self.parent.keyboardState[index].keys[k.key];

                    var state: input.State = undefined;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        state = State.state;

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    if (state == .held) {
                        if (ke == 0) {
                            res[0] += 1.0;
                            // std.log.debug("+1", .{});
                        } else if (ke == 1) {
                            res[0] -= 1.0;
                        } else if (ke == 2) {
                            res[1] += 1.0;
                        } else if (ke == 3) {
                            res[1] -= 1.0;
                        }
                    }
                    ke += 1;
                },
                .mouseMotion => {
                    const index = self.parent.findHardwareIndex2(false, true, false, mouseID) orelse return .{ 0, 0 };
                    const motion = &self.parent.mouseState[index].mouseMotion;

                    var x: f32 = 0;
                    var y: f32 = 0;

                    const isRelative = self.parent.isRelative.load(.acquire);

                    var s: u32 = 0;
                    while (true) {
                        s = motion.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        if (isRelative == 5) {
                            x = @atomicLoad(f32, &motion.x, .acquire);
                            y = @atomicLoad(f32, &motion.y, .acquire);
                        } else {
                            x = motion.x;
                            y = motion.y;
                        }

                        if (s != motion.seq.load(.acquire)) continue;

                        break;
                    }

                    uniform = false;

                    if (isRelative == 5) {
                        _ = @atomicRmw(f32, &motion.x, .Sub, x, .release);
                        _ = @atomicRmw(f32, &motion.y, .Sub, y, .release);
                    }

                    res[0] = x;
                    res[1] = y;

                    if (isRelative == 5 and isCamera) {
                        res[0] = res[0] * mouseSens;
                        res[1] = res[1] * mouseSens;
                    } else {
                        res[0] /= @as(f32, @floatFromInt(windowsInfo.getWidth()));
                        res[1] /= @as(f32, @floatFromInt(windowsInfo.getHeight()));
                    }
                },
                .gamepadAxis => |g| {
                    const index = self.parent.findHardwareIndex2(false, false, true, gamepadID) orelse return .{ 0, 0 };
                    const State = &self.parent.gamepadState[index].gamepadAxis[g.axis];

                    var value: i16 = 0;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        value = State.value;

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    var float: f32 = 0.0;
                    var v_abs = @abs(value);

                    if (v_abs > g.deadzone) {
                        const range = std.math.maxInt(i16) - g.deadzone;
                        v_abs -= @intCast(g.deadzone);

                        float = @as(f32, @floatFromInt(v_abs)) / @as(f32, @floatFromInt(range));
                        if (value < 0) float = -float;
                    }

                    if (ga == 0) {
                        res[0] = float;
                        // std.log.debug("+1", .{});
                    } else if (ga == 1) {
                        res[1] = -float;
                    }

                    if (isCamera) {
                        res[0] = res[0] * stickSens * deltaTime;
                        res[1] = res[1] * stickSens * deltaTime;
                        uniform = false;
                    }

                    ga += 1;
                },
                .gamepadButton => |g| {
                    const index = self.parent.findHardwareIndex2(false, false, true, gamepadID) orelse return .{ 0, 0 };
                    const State = &self.parent.gamepadState[index].gamepadButtons[g.button];

                    var state: input.State = undefined;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        state = State.state;

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    if (state == .held) {
                        if (gb == 0) {
                            res[0] += 1.0;
                            // std.log.debug("+1", .{});
                        } else if (gb == 1) {
                            res[0] -= 1.0;
                        } else if (gb == 2) {
                            res[1] += 1.0;
                        } else if (gb == 3) {
                            res[1] -= 1.0;
                        }
                    }
                    gb += 1;
                },
                .mouseButton => |m| {
                    const index = self.parent.findHardwareIndex2(false, true, false, mouseID) orelse return .{ 0, 0 };
                    const State = &self.parent.mouseState[index].mouseButtons[m.button];

                    var state: input.State = undefined;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        state = State.state;

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    if (state == .held) {
                        if (ke == 0) {
                            res[0] += 1.0;
                            // std.log.debug("+1", .{});
                        } else if (ke == 1) {
                            res[0] -= 1.0;
                        } else if (ke == 2) {
                            res[1] += 1.0;
                        } else if (ke == 3) {
                            res[1] -= 1.0;
                        }
                    }
                    ke += 1;
                },
                .mouseWheel => {
                    const index = self.parent.findHardwareIndex2(false, true, false, mouseID) orelse return .{ 0, 0 };
                    const State = &self.parent.mouseState[index].mouseWheel;

                    var x: f32 = 0;
                    var y: f32 = 0;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        x = State.x.load(.acquire);
                        y = State.y.load(.acquire);

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    // std.log.debug("in {d} : {d}", .{ x, y });

                    _ = State.x.fetchSub(x, .release);
                    _ = State.y.fetchSub(y, .release);

                    res[0] += x;
                    res[1] += y;
                },
            }

            if (uniform) {
                const absx = @abs(res[0]);
                const absy = @abs(res[1]);
                const d = absx * absx + absy * absy;

                if (d > 1.0) {
                    const sq = @sqrt(d);

                    res[0] /= sq;
                    res[1] /= sq;
                }
            }
        }

        return res;
    }

    pub fn getValue1(self: *InputAction, keyboardID: u32, mouseID: u32, gamepadID: u32) f32 {
        const start = if (gamepadID == u32Max) 0 else self.split;
        const end = if (gamepadID == u32Max) self.split else self.count;

        const inputs = self.inputs[start..end];

        var res: f32 = 0;

        if (inputs.len == 0) return res;

        if (!self.needValue) return res;
        // std.log.debug("aa", .{});

        for (inputs) |in| {
            switch (in) {
                .key => |k| {
                    const index = self.parent.findHardwareIndex2(true, false, false, keyboardID) orelse return 0;
                    const State = &self.parent.keyboardState[index].keys[k.key];

                    var state: input.State = undefined;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        state = State.state;

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    if (state == .held)
                        res += 1.0;
                },
                .mouseMotion => {
                    const index = self.parent.findHardwareIndex2(false, true, false, mouseID) orelse return 0;
                    const motion = &self.parent.mouseState[index].mouseMotion;

                    var x: f32 = 0;
                    var y: f32 = 0;

                    const isRelative = self.parent.isRelative.load(.acquire);

                    var s: u32 = 0;
                    while (true) {
                        s = motion.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        if (isRelative == 5) {
                            x = @atomicLoad(f32, &motion.x, .acquire);
                            y = @atomicLoad(f32, &motion.y, .acquire);
                        } else {
                            x = motion.x / @as(f32, @floatFromInt(windowsInfo.getWidth()));
                            y = motion.y / @as(f32, @floatFromInt(windowsInfo.getHeight()));
                        }

                        if (s != motion.seq.load(.acquire)) continue;

                        break;
                    }

                    if (isRelative == 5) {
                        _ = @atomicRmw(f32, &motion.x, .Sub, x, .release);
                        _ = @atomicRmw(f32, &motion.y, .Sub, y, .release);
                    }

                    res += x;
                    res += y;
                },
                .gamepadAxis => |g| {
                    const index = self.parent.findHardwareIndex2(false, false, true, gamepadID) orelse return 0;
                    const State = &self.parent.gamepadState[index].gamepadAxis[g.axis];

                    var value: i16 = 0;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        value = State.value;

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    var float: f32 = 0.0;
                    var v_abs = @abs(value);

                    if (v_abs > g.deadzone) {
                        const range = std.math.maxInt(i16) - g.deadzone;
                        v_abs -= @intCast(g.deadzone);

                        float = @as(f32, @floatFromInt(v_abs)) / @as(f32, @floatFromInt(range));
                        if (value < 0) float = -float;
                    }

                    res += float;
                },
                .gamepadButton => |g| {
                    const index = self.parent.findHardwareIndex2(false, false, true, gamepadID) orelse return 0;
                    const State = &self.parent.gamepadState[index].gamepadButtons[g.button];

                    var state: input.State = undefined;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        state = State.state;

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    if (state == .held)
                        res += 1.0;
                },
                .mouseButton => |m| {
                    const index = self.parent.findHardwareIndex2(false, true, false, mouseID) orelse return 0;
                    const State = &self.parent.mouseState[index].mouseButtons[m.button];

                    var state: input.State = undefined;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        state = State.state;

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    if (state == .held) {
                        res += 1.0;
                    }
                },
                .mouseWheel => {
                    const index = self.parent.findHardwareIndex2(false, true, false, mouseID) orelse return 0;
                    const State = &self.parent.mouseState[index].mouseWheel;

                    var x: f32 = 0;
                    var y: f32 = 0;

                    var s: u32 = 0;
                    while (true) {
                        s = State.seq.load(.acquire);

                        if (s % 2 == 1) continue;

                        x = State.x.load(.acquire);
                        y = State.y.load(.acquire);

                        if (s != State.seq.load(.acquire)) continue;

                        break;
                    }

                    // std.log.debug("in {d} : {d}", .{ x, y });

                    _ = State.x.fetchSub(x, .release);
                    _ = State.y.fetchSub(y, .release);

                    res += x;
                    res += y;
                },
            }
        }

        return res;
    }
};

const KeyBindingFile = struct {
    Using: []const u8,
    Default: ContextBinding,
    Custom: []ContextBinding,

    pub const ContextBinding = struct {
        actions: []ActionBinding,
    };
    pub const ActionBinding = struct {
        id: []const u8,
        inputs: []InputBinding,
    };

    const InputBinding = struct {
        key: ?[]const u8,
        gamepad: ?[]const u8,
        mouse: ?[]const u8,
        exceptDown: ?bool,
        deadzone: ?f32,
        wheelDirectionUp: ?bool,
    };
};

const Self = @This();

const KV = struct { []const u8, u32 };
const StringToKey = [_]KV{
    // keyboard// ----------------- 字母键 -----------------
    .{ "A", sdl.SDL_SCANCODE_A },
    .{ "B", sdl.SDL_SCANCODE_B },
    .{ "C", sdl.SDL_SCANCODE_C },
    .{ "D", sdl.SDL_SCANCODE_D },
    .{ "E", sdl.SDL_SCANCODE_E },
    .{ "F", sdl.SDL_SCANCODE_F },
    .{ "G", sdl.SDL_SCANCODE_G },
    .{ "H", sdl.SDL_SCANCODE_H },
    .{ "I", sdl.SDL_SCANCODE_I },
    .{ "J", sdl.SDL_SCANCODE_J },
    .{ "K", sdl.SDL_SCANCODE_K },
    .{ "L", sdl.SDL_SCANCODE_L },
    .{ "M", sdl.SDL_SCANCODE_M },
    .{ "N", sdl.SDL_SCANCODE_N },
    .{ "O", sdl.SDL_SCANCODE_O },
    .{ "P", sdl.SDL_SCANCODE_P },
    .{ "Q", sdl.SDL_SCANCODE_Q },
    .{ "R", sdl.SDL_SCANCODE_R },
    .{ "S", sdl.SDL_SCANCODE_S },
    .{ "T", sdl.SDL_SCANCODE_T },
    .{ "U", sdl.SDL_SCANCODE_U },
    .{ "V", sdl.SDL_SCANCODE_V },
    .{ "W", sdl.SDL_SCANCODE_W },
    .{ "X", sdl.SDL_SCANCODE_X },
    .{ "Y", sdl.SDL_SCANCODE_Y },
    .{ "Z", sdl.SDL_SCANCODE_Z },

    // ----------------- 数字键（主键盘） -----------------
    .{ "0", sdl.SDL_SCANCODE_0 },
    .{ "1", sdl.SDL_SCANCODE_1 },
    .{ "2", sdl.SDL_SCANCODE_2 },
    .{ "3", sdl.SDL_SCANCODE_3 },
    .{ "4", sdl.SDL_SCANCODE_4 },
    .{ "5", sdl.SDL_SCANCODE_5 },
    .{ "6", sdl.SDL_SCANCODE_6 },
    .{ "7", sdl.SDL_SCANCODE_7 },
    .{ "8", sdl.SDL_SCANCODE_8 },
    .{ "9", sdl.SDL_SCANCODE_9 },

    // ----------------- 功能键 (F1 - F12) -----------------
    .{ "F1", sdl.SDL_SCANCODE_F1 },
    .{ "F2", sdl.SDL_SCANCODE_F2 },
    .{ "F3", sdl.SDL_SCANCODE_F3 },
    .{ "F4", sdl.SDL_SCANCODE_F4 },
    .{ "F5", sdl.SDL_SCANCODE_F5 },
    .{ "F6", sdl.SDL_SCANCODE_F6 },
    .{ "F7", sdl.SDL_SCANCODE_F7 },
    .{ "F8", sdl.SDL_SCANCODE_F8 },
    .{ "F9", sdl.SDL_SCANCODE_F9 },
    .{ "F10", sdl.SDL_SCANCODE_F10 },
    .{ "F11", sdl.SDL_SCANCODE_F11 },
    .{ "F12", sdl.SDL_SCANCODE_F12 },

    // ----------------- 控制与编辑键 -----------------
    .{ "Escape", sdl.SDL_SCANCODE_ESCAPE },
    .{ "Return", sdl.SDL_SCANCODE_RETURN },
    .{ "Enter", sdl.SDL_SCANCODE_RETURN },
    .{ "Tab", sdl.SDL_SCANCODE_TAB },
    .{ "Space", sdl.SDL_SCANCODE_SPACE },
    .{ "Backspace", sdl.SDL_SCANCODE_BACKSPACE },
    .{ "Delete", sdl.SDL_SCANCODE_DELETE },
    .{ "Insert", sdl.SDL_SCANCODE_INSERT },
    .{ "Home", sdl.SDL_SCANCODE_HOME },
    .{ "End", sdl.SDL_SCANCODE_END },
    .{ "PageUp", sdl.SDL_SCANCODE_PAGEUP },
    .{ "PageDown", sdl.SDL_SCANCODE_PAGEDOWN },
    .{ "CapsLock", sdl.SDL_SCANCODE_CAPSLOCK },

    // ----------------- 方向键 -----------------
    .{ "Up", sdl.SDL_SCANCODE_UP },
    .{ "Down", sdl.SDL_SCANCODE_DOWN },
    .{ "Left", sdl.SDL_SCANCODE_LEFT },
    .{ "Right", sdl.SDL_SCANCODE_RIGHT },

    // ----------------- 修饰键 -----------------
    .{ "LShift", sdl.SDL_SCANCODE_LSHIFT },
    .{ "RShift", sdl.SDL_SCANCODE_RSHIFT },
    .{ "LCtrl", sdl.SDL_SCANCODE_LCTRL },
    .{ "RCtrl", sdl.SDL_SCANCODE_RCTRL },
    .{ "LAlt", sdl.SDL_SCANCODE_LALT },
    .{ "RAlt", sdl.SDL_SCANCODE_RALT },
    .{ "LGui", sdl.SDL_SCANCODE_LGUI }, // Windows/Command 键
    .{ "RGui", sdl.SDL_SCANCODE_RGUI },

    // ----------------- 标点与符号 -----------------
    .{ "Minus", sdl.SDL_SCANCODE_MINUS }, // -
    .{ "Equals", sdl.SDL_SCANCODE_EQUALS }, // =
    .{ "LeftBracket", sdl.SDL_SCANCODE_LEFTBRACKET }, // [
    .{ "RightBracket", sdl.SDL_SCANCODE_RIGHTBRACKET }, // ]
    .{ "Backslash", sdl.SDL_SCANCODE_BACKSLASH }, // \
    .{ "Semicolon", sdl.SDL_SCANCODE_SEMICOLON }, // ;
    .{ "Apostrophe", sdl.SDL_SCANCODE_APOSTROPHE }, // '
    .{ "Grave", sdl.SDL_SCANCODE_GRAVE }, // ` (反引号/波浪键)
    .{ "Comma", sdl.SDL_SCANCODE_COMMA }, // ,
    .{ "Period", sdl.SDL_SCANCODE_PERIOD }, // .
    .{ "Slash", sdl.SDL_SCANCODE_SLASH }, // /

    // ----------------- 小键盘 (Keypad) -----------------
    .{ "Kp0", sdl.SDL_SCANCODE_KP_0 },
    .{ "Kp1", sdl.SDL_SCANCODE_KP_1 },
    .{ "Kp2", sdl.SDL_SCANCODE_KP_2 },
    .{ "Kp3", sdl.SDL_SCANCODE_KP_3 },
    .{ "Kp4", sdl.SDL_SCANCODE_KP_4 },
    .{ "Kp5", sdl.SDL_SCANCODE_KP_5 },
    .{ "Kp6", sdl.SDL_SCANCODE_KP_6 },
    .{ "Kp7", sdl.SDL_SCANCODE_KP_7 },
    .{ "Kp8", sdl.SDL_SCANCODE_KP_8 },
    .{ "Kp9", sdl.SDL_SCANCODE_KP_9 },
    .{ "KpEnter", sdl.SDL_SCANCODE_KP_ENTER },
    .{ "KpPlus", sdl.SDL_SCANCODE_KP_PLUS },
    .{ "KpMinus", sdl.SDL_SCANCODE_KP_MINUS },
    .{ "KpMultiply", sdl.SDL_SCANCODE_KP_MULTIPLY },
    .{ "KpDivide", sdl.SDL_SCANCODE_KP_DIVIDE },
    .{ "KpPeriod", sdl.SDL_SCANCODE_KP_PERIOD },
    .{ "NumLock", sdl.SDL_SCANCODE_NUMLOCKCLEAR },

    // ----------------- 其他系统常用键 -----------------
    .{ "PrintScreen", sdl.SDL_SCANCODE_PRINTSCREEN },
    .{ "ScrollLock", sdl.SDL_SCANCODE_SCROLLLOCK },
    .{ "Pause", sdl.SDL_SCANCODE_PAUSE },

    // gamepad
    .{ "GB_S", sdl.SDL_GAMEPAD_BUTTON_SOUTH },
    .{ "GB_N", sdl.SDL_GAMEPAD_BUTTON_NORTH },
    .{ "GB_W", sdl.SDL_GAMEPAD_BUTTON_WEST },
    .{ "GB_E", sdl.SDL_GAMEPAD_BUTTON_EAST },
    .{ "GB_U", sdl.SDL_GAMEPAD_BUTTON_DPAD_UP },
    .{ "GB_D", sdl.SDL_GAMEPAD_BUTTON_DPAD_DOWN },
    .{ "GB_L", sdl.SDL_GAMEPAD_BUTTON_DPAD_LEFT },
    .{ "GB_R", sdl.SDL_GAMEPAD_BUTTON_DPAD_RIGHT },
    .{ "GB_SL", sdl.SDL_GAMEPAD_BUTTON_LEFT_SHOULDER },
    .{ "GB_SR", sdl.SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER },
    .{ "GB_LS", sdl.SDL_GAMEPAD_BUTTON_LEFT_STICK },
    .{ "GB_RS", sdl.SDL_GAMEPAD_BUTTON_RIGHT_STICK },
    .{ "GB_BACK", sdl.SDL_GAMEPAD_BUTTON_BACK },
    .{ "GB_GUIDE", sdl.SDL_GAMEPAD_BUTTON_GUIDE },
    .{ "GB_START", sdl.SDL_GAMEPAD_BUTTON_START },
    .{ "GB_M1", sdl.SDL_GAMEPAD_BUTTON_MISC1 },
    .{ "GB_RP1", sdl.SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1 },
    .{ "GB_LP1", sdl.SDL_GAMEPAD_BUTTON_LEFT_PADDLE1 },
    .{ "GB_RP2", sdl.SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2 },
    .{ "GB_LP2", sdl.SDL_GAMEPAD_BUTTON_LEFT_PADDLE2 },
    .{ "GB_T", sdl.SDL_GAMEPAD_BUTTON_TOUCHPAD },
    .{ "GB_M2", sdl.SDL_GAMEPAD_BUTTON_MISC2 },
    .{ "GB_M3", sdl.SDL_GAMEPAD_BUTTON_MISC3 },
    .{ "GB_M4", sdl.SDL_GAMEPAD_BUTTON_MISC4 },
    .{ "GB_M5", sdl.SDL_GAMEPAD_BUTTON_MISC5 },
    .{ "GB_M6", sdl.SDL_GAMEPAD_BUTTON_MISC6 },

    .{ "GA_RX", sdl.SDL_GAMEPAD_AXIS_RIGHTX },
    .{ "GA_RY", sdl.SDL_GAMEPAD_AXIS_RIGHTY },
    .{ "GA_LX", sdl.SDL_GAMEPAD_AXIS_LEFTX },
    .{ "GA_LY", sdl.SDL_GAMEPAD_AXIS_LEFTY },
    .{ "GA_LT", sdl.SDL_GAMEPAD_AXIS_LEFT_TRIGGER },
    .{ "GA_RT", sdl.SDL_GAMEPAD_AXIS_RIGHT_TRIGGER },

    // mouse
    .{ "M_M", sdl.SDL_EVENT_MOUSE_MOTION },
    .{ "M_W", sdl.SDL_EVENT_MOUSE_WHEEL },
    .{ "M_L", sdl.SDL_BUTTON_LEFT },
    .{ "M_C", sdl.SDL_BUTTON_MIDDLE },
    .{ "M_R", sdl.SDL_BUTTON_RIGHT },
    .{ "M_S1", sdl.SDL_BUTTON_X1 },
    .{ "M_S2", sdl.SDL_BUTTON_X2 },
};
const StringToKeyMap = std.static_string_map.StaticStringMap(u32).initComptime(StringToKey);

mem: []u8,
inputActions: []InputAction,

pub fn initFromRegister(io: Io, gpa: Allocator, inputs: *input) !Self {
    const file = try Io.Dir.cwd().readFileAlloc(io, "keybindings.json", gpa, .unlimited);
    defer gpa.free(file);

    var parsed = try std.json.parseFromSlice(KeyBindingFile, gpa, file, .{
        .ignore_unknown_fields = false,
    });
    defer parsed.deinit();

    const profile = if (std.mem.eql(u8, parsed.value.Using, "Default")) &parsed.value.Default else a: {
        const i = try std.fmt.parseInt(u32, parsed.value.Using, 10);

        break :a &parsed.value.Custom[i];
    };

    std.mem.sort(KeyBindingFile.ActionBinding, profile.actions, {}, struct {
        fn lessThan(_: void, a: KeyBindingFile.ActionBinding, b: KeyBindingFile.ActionBinding) bool {
            return std.mem.order(u8, a.id, b.id) == .lt;
        }
    }.lessThan);

    const actionCount = inputRegister.getActionCount();

    var id_idxMap = std.AutoHashMap(u32, u32).init(gpa);
    defer id_idxMap.deinit();

    // 第一遍：遍历 register 中所有 action，统计所需总内存
    var totalSize: usize = @sizeOf(InputAction) * actionCount + (@alignOf(InputAction) - 1);
    for (0..actionCount) |i| {
        const ctx = inputRegister.getAction(@intCast(i));

        try id_idxMap.put(ctx.name.id, @intCast(i));

        totalSize += @sizeOf(*atomic.Value(u32)) * ctx.maxInputCount * 2;
        totalSize += @sizeOf(Input) * ctx.maxInputCount * 2;
        totalSize += @sizeOf(u32) * ctx.maxInputCount * 2;
        // 每个 action 有 3 次独立分配，预留对齐填充
        totalSize += 3 * (@alignOf(InputAction) - 1);
    }

    const mem = try gpa.alloc(u8, totalSize);
    errdefer gpa.free(mem);

    var fixedBufferAllocator = std.heap.FixedBufferAllocator.init(mem);
    const fba = fixedBufferAllocator.allocator();

    const actions = try fba.alloc(InputAction, actionCount);

    std.log.debug("{d}, total {d}", .{ @sizeOf(InputAction) * actionCount * 2, totalSize });
    // std.log.debug("{*}, {*}", .{ actions.ptr, mem.ptr });
    assert(@intFromPtr(actions.ptr) == @intFromPtr(mem.ptr));

    for (0..actionCount, actions) |i, *a| {
        // const ctx = inputRegister.getAction(@intCast(i));
        const ctx = inputRegister.getAction(id_idxMap.get(@intCast(i)).?);

        std.log.debug("{d}, {d}", .{ ctx.name.id, i });
        // assert(ctx.name.id == i);

        a.* = .{
            .name = ctx.name,
            .parent = inputs,
            .consumeCache = try fba.alloc(*atomic.Value(u32), ctx.maxInputCount * 2),
            .inputs = try fba.alloc(Input, ctx.maxInputCount * 2),
            .seqs = try fba.alloc(u32, ctx.maxInputCount * 2),
            .count = 0,
            .split = 0,
            .strictSeq = ctx.strictSeq,
            .isPulse = ctx.isPulse,
            .needValue = ctx.needValue,
            .isCamera = ctx.isCamera,
            .gamepadStartTimeSeted = false,
            .mouseStartTimeSeted = false,
            .canConsume = false,
        };

        if (builtin.mode == .Debug) {
            assert(std.mem.eql(u8, ctx.name.name, profile.actions[i].id));
        }

        const s_inputs = profile.actions[i].inputs;
        const min_len = @min(s_inputs.len, a.inputs.len);

        if (s_inputs.len > a.inputs.len)
            std.log.warn("file inputs len {d} > maxCount {d}", .{ s_inputs.len, a.inputs.len });

        var split: u32 = 0;
        var spEnd = false;

        // split logic need update, after gamepad and mouse added to here
        for (s_inputs[0..min_len], a.inputs[0..min_len]) |inB, *in| {
            a.count += 1;

            if (inB.key) |key| {
                if (!isKey(key)) std.debug.panic("not key {s}", .{key});

                in.* = .{ .key = .{
                    .key = StringToKeyMap.get(key) orelse std.debug.panic("unknown input string {s}", .{key}),
                    .exceptDown = inB.exceptDown.?,
                } };

                if (!spEnd) split += 1;

                continue;
            }

            if (inB.mouse) |m| {
                const v = StringToKeyMap.get(m) orelse std.debug.panic("unknown input string {s}", .{m});
                if (v == sdl.SDL_EVENT_MOUSE_MOTION) {
                    in.* = .{
                        .mouseMotion = .{},
                    };
                } else if (v == sdl.SDL_EVENT_MOUSE_WHEEL) {
                    in.* = .{ .mouseWheel = .{
                        .directionUp = inB.wheelDirectionUp.?,
                    } };
                } else if (std.mem.startsWith(u8, m, "M_")) {
                    in.* = .{ .mouseButton = .{
                        .button = v,
                        .exceptDown = inB.exceptDown.?,
                    } };
                }

                if (!spEnd) split += 1;

                continue;
            } else {
                spEnd = true;
            }

            if (spEnd) {
                if (inB.gamepad) |g| {
                    if (std.mem.startsWith(u8, g, "GB")) {
                        in.* = .{ .gamepadButton = .{
                            .button = StringToKeyMap.get(g) orelse std.debug.panic("unknown input string {s}", .{g}),
                            .exceptDown = inB.exceptDown.?,
                        } };
                    } else if (std.mem.startsWith(u8, g, "GA")) {
                        const deadzone = @min(1.0, inB.deadzone.?);
                        in.* = .{ .gamepadAxis = .{
                            .axis = StringToKeyMap.get(g) orelse std.debug.panic("unknown input string {s}", .{g}),
                            .deadzone = @intFromFloat(deadzone * (std.math.maxInt(i16) - 1)),
                        } };
                    }
                }
            }
        }

        a.split = split;
    }

    for (actions) |value| {
        std.log.debug("{d}, {}, {any}, {f}, {*}, {d}, {}", .{
            value.count,
            value.canConsume,
            value.inputs,
            value.name,
            value.parent,
            value.split,
            value.strictSeq,
        });
        // std.log.debug("{any}\n {any}", .{ value., value2 });
    }

    return .{ .mem = mem, .inputActions = actions };
}

pub fn deinit(self: *Self, allocator: Allocator) void {
    allocator.free(self.mem);
}

fn findSameIDIndex(ctxBindings: []KeyBindingFile.InputBinding, id: u32) usize {
    for (ctxBindings.actions, 0..) |a, i| {
        if (a.id == id) return i;
    }

    unreachable;
}

fn isKey(name: []const u8) bool {
    if (std.mem.startsWith(u8, name, "M_")) return false;
    if (std.mem.startsWith(u8, name, "GA")) return false;
    if (std.mem.startsWith(u8, name, "GB")) return false;

    return true;
}

/// for new inputRouter copy from existed
pub fn copyAndReset(self: *Self, allocator: Allocator) !Self {
    var res: Self = undefined;
    const copy = try allocator.dupe(u8, self.mem);

    const old_start = @intFromPtr(self.mem.ptr);
    const old_end = old_start + copy.len;
    const new_start = @intFromPtr(copy.ptr);
    const delta: isize = @as(isize, @intCast(new_start)) - @as(isize, @intCast(old_start));

    // const list_offset = 0; // @intFromPtr(self.inputActions.ptr) - old_start;
    const new_list_ptr: [*]InputAction = @ptrCast(@alignCast(copy.ptr));
    const new_list: []InputAction = new_list_ptr[0..self.inputActions.len];

    rebaseSlices(new_list, old_start, old_end, delta);

    res = .{ .mem = copy, .inputActions = new_list };

    for (res.inputActions) |*v| {
        v.canConsume = false;
    }

    for (self.inputActions, res.inputActions) |value, value2| {
        std.log.debug("{d}, {}, {any}, {f}, {*}, {d}, {}\n{d}, {}, {any}, {f}, {*}, {d}, {}\n", .{
            value.count,
            value.canConsume,
            value.inputs,
            value.name,
            value.parent,
            value.split,
            value.strictSeq,

            value2.count,
            value2.canConsume,
            value2.inputs,
            value2.name,
            value2.parent,
            value2.split,
            value2.strictSeq,
        });
        // std.log.debug("{any}\n {any}", .{ value., value2 });
    }

    return res;
}

fn rebaseSlices(
    items: anytype,
    old_start: usize,
    old_end: usize,
    delta: isize,
) void {
    const SliceType = @TypeOf(items);
    const ItemType = @typeInfo(SliceType).pointer.child;
    const struct_info = @typeInfo(ItemType).@"struct";

    for (items) |*item| {
        // 编译期展开：遍历 T 的所有字段
        inline for (struct_info.fields) |field| {
            const field_info = @typeInfo(field.type);

            // 检查当前字段是否是切片（.slice）
            if (field_info == .pointer and field_info.pointer.size == .slice) {
                const slice_val = @field(item, field.name);
                const addr = @intFromPtr(slice_val.ptr);

                // 核心安全检查：只有指针确实落在旧内存范围内时才偏移
                // （避免误修改静态字面量如 "const str = \"hello\"" 或空切片）
                if (addr >= old_start and addr < old_end) {
                    const new_addr: usize = @intCast(@as(isize, @intCast(addr)) + delta);
                    @field(item, field.name).ptr = @ptrFromInt(new_addr);
                }
            }
        }
    }
}

pub fn getAction(self: *Self, name: Str) *InputAction {
    return &self.inputActions[name.id];
}
