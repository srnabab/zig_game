/// device support count have limit
const std = @import("std");
const Allocator = std.mem.Allocator;
const Mutex = std.Io.Mutex;
const atomic = std.atomic;

const assert = std.debug.assert;

const tracy = @import("tracy");

const global = @import("global");

const mstd = @import("ms_std");

const ObserverRingBuffer = mstd.ObserverRingBuffer;

const sdl = @import("sdl").sdl;
const SDL_EventType = @import("sdl").SDL_EventType;
const SDL_Keycode = @import("sdl").SDL_Keycode;
const SDL_Scancode = @import("sdl").SDL_Scancode;

const SDL_GetTicksNS = sdl.SDL_GetTicksNS;

const maxU32 = std.math.maxInt(u32);

const MaxKeepMs = 1000;
const MaxKeepMs_Ns = 500 * std.time.ns_per_ms;
const MaxCountPerSecond = 150;

const mouseButtonCount = 32;

pub const State = enum(u8) {
    released,
    held,
};

pub const Key = struct {
    down: bool = false,
    repeat: bool = false,
    key: sdl.SDL_Scancode = 0,
};
pub const KeyState = struct {
    seq: atomic.Value(u32) = .init(0),
    state: State = .released,
    timestamp: u64 = 0,
    consumedID: atomic.Value(u32) = .init(maxU32),
    generation: u32 = 0,

    pub fn getGeneration(self: *KeyState) u32 {
        var se: u32 = 0;

        var s: u32 = 0;
        while (true) {
            s = self.seq.load(.acquire);

            if (s % 2 == 1) continue;

            se = self.generation;

            if (s != self.seq.load(.acquire)) continue;

            break;
        }

        return se;
    }

    pub fn getStateAndTimestamp(self: *KeyState) struct {
        state: State,
        timestamp: u64,
    } {
        var se: State = .released;
        var timestamp: u64 = 0;

        var s: u32 = 0;
        while (true) {
            s = self.seq.load(.acquire);

            if (s % 2 == 1) continue;

            se = self.state;
            timestamp = self.timestamp;

            if (s != self.seq.load(.acquire)) continue;

            break;
        }

        return .{ .state = se, .timestamp = timestamp };
    }
};

pub const MouseButton = struct {
    down: bool = false,
    clicks: u8 = 0,
    button: u8 = 0,
    x: f32 = 0,
    y: f32 = 0,
};
pub const MouseButtonState = struct {
    seq: atomic.Value(u32) = .init(0),
    state: State = .released,
    timestamp: u64 = 0,
    consumedID: atomic.Value(u32) = .init(maxU32),
    generation: u32 = 0,

    pub fn getGeneration(self: *MouseButtonState) u32 {
        var se: u32 = 0;

        var s: u32 = 0;
        while (true) {
            s = self.seq.load(.acquire);

            if (s % 2 == 1) continue;

            se = self.generation;

            if (s != self.seq.load(.acquire)) continue;

            break;
        }

        return se;
    }

    pub fn getStateAndTimestamp(self: *MouseButtonState) struct {
        state: State,
        timestamp: u64,
    } {
        var se: State = .released;
        var timestamp: u64 = 0;

        var s: u32 = 0;
        while (true) {
            s = self.seq.load(.acquire);

            if (s % 2 == 1) continue;

            se = self.state;
            timestamp = self.timestamp;

            if (s != self.seq.load(.acquire)) continue;

            break;
        }

        return .{ .state = se, .timestamp = timestamp };
    }
};

pub const MouseMotion = struct {
    x: f32 = 0,
    y: f32 = 0,
};
pub const MouseMotionState = struct {
    seq: atomic.Value(u32) = .init(0),
    x: f32 = 0,
    y: f32 = 0,
    timestamp: u64 = 0,

    pub fn getTimestamp(self: *MouseMotionState) u64 {
        var timestamp: u64 = 0;

        var s: u32 = 0;
        while (true) {
            s = self.seq.load(.acquire);

            if (s % 2 == 1) continue;

            timestamp = self.timestamp;

            if (s != self.seq.load(.acquire)) continue;

            break;
        }

        return timestamp;
    }
};

pub const MouseWheel = struct {
    x: f32 = 0,
    y: f32 = 0,
    mouse_x: f32 = 0,
    mouse_y: f32 = 0,
};
pub const MouseWheelState = struct {
    seq: atomic.Value(u32) = .init(0),
    x: atomic.Value(f32) = .init(0),
    y: atomic.Value(f32) = .init(0),
    mouse_x: f32 = 0,
    mouse_y: f32 = 0,
    timestamp: u64 = 0,

    pub fn getTimestamp(self: *MouseWheelState) u64 {
        var timestamp: u64 = 0;

        var s: u32 = 0;
        while (true) {
            s = self.seq.load(.acquire);

            if (s % 2 == 1) continue;

            timestamp = self.timestamp;

            if (s != self.seq.load(.acquire)) continue;

            break;
        }

        return timestamp;
    }
};

pub const GamePadAxis = struct {
    axis: u8 = 0,
    value: i16 = 0,
};
pub const GamePadAxisState = struct {
    seq: atomic.Value(u32) = .init(0),
    axis: u8 = 0,
    value: i16 = 0,
    timestamp: u64 = 0,

    pub fn getTimestamp(self: *GamePadAxisState) u64 {
        var timestamp: u64 = 0;

        var s: u32 = 0;
        while (true) {
            s = self.seq.load(.acquire);

            if (s % 2 == 1) continue;

            timestamp = self.timestamp;

            if (s != self.seq.load(.acquire)) continue;

            break;
        }

        return timestamp;
    }

    pub fn getTimestampAndValue(self: *GamePadAxisState) struct {
        timestamp: u64,
        value: i16,
    } {
        var timestamp: u64 = 0;
        var value: i16 = 0;

        var s: u32 = 0;
        while (true) {
            s = self.seq.load(.acquire);

            if (s % 2 == 1) continue;

            timestamp = self.timestamp;
            value = self.value;

            if (s != self.seq.load(.acquire)) continue;

            break;
        }

        return .{ .value = value, .timestamp = timestamp };
    }
};

pub const GamePadButton = struct {
    down: bool = false,
    // repeat: bool = false,
    button: u8 = 0,
};
pub const GamePadButtonState = struct {
    seq: atomic.Value(u32) = .init(0),
    state: State = .released,
    timestamp: u64 = 0,
    consumedID: atomic.Value(u32) = .init(maxU32),
    generation: u32 = 0,

    pub fn getGeneration(self: *GamePadButtonState) u32 {
        var se: u32 = 0;

        var s: u32 = 0;
        while (true) {
            s = self.seq.load(.acquire);

            if (s % 2 == 1) continue;

            se = self.generation;

            if (s != self.seq.load(.acquire)) continue;

            break;
        }

        return se;
    }

    pub fn getStateAndTimestamp(self: *GamePadButtonState) struct {
        state: State,
        timestamp: u64,
    } {
        var se: State = .released;
        var timestamp: u64 = 0;

        var s: u32 = 0;
        while (true) {
            s = self.seq.load(.acquire);

            if (s % 2 == 1) continue;

            se = self.state;
            timestamp = self.timestamp;

            if (s != self.seq.load(.acquire)) continue;

            break;
        }

        return .{ .state = se, .timestamp = timestamp };
    }
};

pub const InputType = enum {
    key,
    mouseMotion,
    mouseButton,
    mouseWheel,
    gamepadAxis,
    gamepadButton,
};
pub const Input = struct {
    timestamp: u64 = 0,
    hardwareID: sdl.SDL_KeyboardID = 0,
    id: u32 = 0,
    input: InputUnion,
};
const InputUnion = union(InputType) {
    key: Key,
    mouseMotion: MouseMotion,
    mouseButton: MouseButton,
    mouseWheel: MouseWheel,
    gamepadAxis: GamePadAxis,
    gamepadButton: GamePadButton,
};

const Keyborad = struct {
    keys: [sdl.SDL_SCANCODE_COUNT]KeyState,
};
const Mouse = struct {
    // * - Button 1: Left mouse button
    // * - Button 2: Middle mouse button
    // * - Button 3: Right mouse button
    // * - Button 4: Side mouse button 1
    // * - Button 5: Side mouse button 2
    mouseButtons: [mouseButtonCount]MouseButtonState,

    mouseMotion: MouseMotionState,
    mouseWheel: MouseWheelState,
};
const GamePad = struct {
    gamepadAxis: [sdl.SDL_GAMEPAD_AXIS_COUNT]GamePadAxisState,
    gamepadButtons: [sdl.SDL_GAMEPAD_BUTTON_COUNT]GamePadButtonState,
};

// const StreamSize = mstd.Math.round(128, (MaxCountPerSecond * MaxKeepMs) / 1000);
const StreamSize = 256;
const StreamType = ObserverRingBuffer(Input, StreamSize);

const Self = @This();

var count: atomic.Value(u64) align(64) = .init(0);
var totalTime: atomic.Value(u64) align(64) = .init(0);

mem: []u8 = &.{},
mutex: Mutex = .init,
window: *sdl.SDL_Window,

isRelative: atomic.Value(u8) = .init(0),

stateIndexKeyboardID: []sdl.SDL_KeyboardID = &.{},
stateIndexMouseID: []sdl.SDL_MouseID = &.{},
stateIndexGamepadID: []sdl.SDL_JoystickID = &.{},

keyboardState: []Keyborad = &.{},
mouseState: []Mouse = &.{},
gamepadState: []GamePad = &.{},

keyboardActiveMap: [][sdl.SDL_SCANCODE_COUNT]u8 = &.{},
mouseActiveMap: [][mouseButtonCount]u8 = &.{},
gamepadActiveMap: [][sdl.SDL_GAMEPAD_BUTTON_COUNT]u8 = &.{},

keyboardQueryMap: [][2]std.StaticBitSet(sdl.SDL_SCANCODE_COUNT) = &.{},
keyboardQueryMap_idx: []atomic.Value(u8) = &.{},
mouseQueryMap: []atomic.Value(u8) = &.{},
gamepadQueryMap: []atomic.Value(u32) = &.{},

lastMouseMotionTime: []u64 = &.{},
lastMouseWheelTime: []u64 = &.{},
lastGamepadAxisTime: [][sdl.SDL_GAMEPAD_AXIS_COUNT]u64 = &.{},

maxCount: u32 = 0,

idAdd: u32 = 0,
stream: StreamType,

pub fn init(allocator: std.mem.Allocator, window: *sdl.SDL_Window) !Self {
    std.log.debug("input size {d}", .{@sizeOf(Input)});

    var self: Self = .{
        .window = window,
        .stream = .empty,
    };

    self.mem = try allocator.alloc(u8, 1024 * 1024);
    @memset(self.mem, 0x11);

    const tempStruct = struct {
        stateIndexKeyboardID: []sdl.SDL_KeyboardID,
        stateIndexMouseID: []sdl.SDL_MouseID,
        stateIndexGamepadID: []sdl.SDL_JoystickID,

        keyboardState: []Keyborad,
        mouseState: []Mouse,
        gamepadState: []GamePad,

        keyboardActiveMap: [][sdl.SDL_SCANCODE_COUNT]u8,
        mouseActiveMap: [][mouseButtonCount]u8,
        gamepadActiveMap: [][sdl.SDL_GAMEPAD_BUTTON_COUNT]u8,

        keyboardQueryMap: [][2]std.StaticBitSet(sdl.SDL_SCANCODE_COUNT),
        keyboardQueryMap_idx: []atomic.Value(u8),
        mouseQueryMap: []atomic.Value(u8),
        gamepadQueryMap: []atomic.Value(u32),

        lastMouseMotionTime: []u64,
        lastMouseWheelTime: []u64,
        lastGamepadAxisTime: [][sdl.SDL_GAMEPAD_AXIS_COUNT]u64,
    };

    const res = layoutIntoStruct(tempStruct, self.mem, 0);
    const typeInfo = @typeInfo(tempStruct);
    inline for (typeInfo.@"struct".fields) |field| {
        @field(self, field.name) = @field(res.slices, field.name);
    }
    self.maxCount = @intCast(res.maxCount);

    std.log.debug("max input device count {d}", .{self.maxCount});

    return self;
}

pub fn deinit(self: *Self, allocator: Allocator) void {
    const tt = totalTime.load(.monotonic);
    const c = count.load(.monotonic);

    const at = @as(f32, @floatFromInt(tt)) / @as(f32, @floatFromInt(c));

    std.log.debug("count: {d}, average time: {d}ns", .{ c, at });
    allocator.free(self.mem);
}

pub fn findHardwareIndex(maps: []u32, hardwareID: u32) ?u32 {
    for (maps, 0..) |value, i| {
        if (hardwareID == value) return @intCast(i);
    }

    return null;
}

pub fn findHardwareIndex2(self: *Self, keyboard: bool, mouse: bool, gamepad: bool, hardwareID: u32) ?u32 {
    const maps = if (keyboard) a: {
        const end = @atomicLoad(usize, &self.stateIndexKeyboardID.len, .monotonic);
        break :a self.stateIndexKeyboardID[0..end];
    } else if (gamepad) a: {
        const end = @atomicLoad(usize, &self.stateIndexGamepadID.len, .monotonic);
        break :a self.stateIndexGamepadID[0..end];
    } else if (mouse) a: {
        const end = @atomicLoad(usize, &self.stateIndexMouseID.len, .monotonic);
        break :a self.stateIndexMouseID[0..end];
    } else return null;

    for (maps, 0..) |value, i| {
        if (hardwareID == value) return @intCast(i);
    }

    return null;
}

pub fn setInput(self: *Self, eventType: SDL_EventType, event: *sdl.SDL_Event) !void {
    const zone = tracy.initZone(@src(), .{ .name = "set input" });
    defer zone.deinit();

    var input: Input = undefined;
    var add = true;

    const isRelative = self.isRelative.load(.acquire);
    if (isRelative == 1) {
        self.isRelative.store(2, .release);
        while (self.isRelative.cmpxchgWeak(4, 5, .release, .acquire)) |_| {
            atomic.spinLoopHint();
        }
    }

    switch (eventType) {
        .SDL_EVENT_KEY_DOWN, .SDL_EVENT_KEY_UP => {
            const hardwareID = event.key.which;
            const index = findHardwareIndex(self.stateIndexKeyboardID, hardwareID) orelse i: {
                const idx = self.stateIndexKeyboardID.len;

                if (idx == self.maxCount) return;

                @atomicStore(usize, &self.stateIndexKeyboardID.len, idx + 1, .monotonic);
                self.keyboardState.len += 1;

                self.stateIndexKeyboardID[idx] = hardwareID;
                @memset(&self.keyboardState[idx].keys, KeyState{});

                break :i idx;
            };

            // const preState = self.keyboardState[index].keys[event.key.scancode].state;
            var curState: State = .released;

            if (event.key.down) {
                curState = .held;
            }

            const s = self.keyboardState[index].keys[event.key.scancode].seq.load(.acquire);
            _ = self.keyboardState[index].keys[event.key.scancode].seq.store(s + 1, .release);

            self.keyboardState[index].keys[event.key.scancode].state = curState;

            // if (self.keyboardState[index].keys[event.key.scancode].consumedID.load(.acquire) != maxU32) {
            //     self.keyboardState[index].keys[event.key.scancode].timestamp = event.key.timestamp;
            //     self.keyboardState[index].keys[event.key.scancode].consumedID.store(maxU32, .release);
            // }
            if (!event.key.repeat) {
                self.keyboardState[index].keys[event.key.scancode].timestamp = event.key.timestamp;
                self.keyboardState[index].keys[event.key.scancode].generation += 1;
                self.keyboardState[index].keys[event.key.scancode].consumedID.store(maxU32, .release);
            }

            _ = self.keyboardState[index].keys[event.key.scancode].seq.store(s + 2, .release);

            // if (event.key.repeat) std.log.debug("repeat {d}", .{event.key.key});

            input = Input{
                .timestamp = event.key.timestamp,
                .hardwareID = hardwareID,
                .id = self.idAdd,
                .input = .{ .key = .{
                    .down = event.key.down,
                    .repeat = event.key.repeat,
                    .key = event.key.scancode,
                } },
            };

            if (global.firstKeyboardID.load(.monotonic) == maxU32) global.firstKeyboardID.store(event.key.which, .monotonic);
            global.usingGamepad.store(0, .monotonic);
            // std.log.debug(" {d} range: {d}", .{ input.timestamp, SDL_GetTicksNS() - input.timestamp });
        },
        .SDL_EVENT_MOUSE_BUTTON_DOWN, .SDL_EVENT_MOUSE_BUTTON_UP => {
            // for mouse will send event bigger than 32, avoid panic, choose to ignore
            if (event.button.button > mouseButtonCount) return;

            const hardwareID = event.button.which;
            const index = findHardwareIndex(self.stateIndexMouseID, hardwareID) orelse i: {
                const idx = self.stateIndexMouseID.len;

                if (idx == self.maxCount) return;

                @atomicStore(usize, &self.stateIndexMouseID.len, idx + 1, .monotonic);
                self.mouseState.len += 1;
                self.lastMouseMotionTime.len += 1;
                self.lastMouseWheelTime.len += 1;

                self.stateIndexMouseID[idx] = hardwareID;
                @memset(&self.mouseState[idx].mouseButtons, MouseButtonState{});
                self.mouseState[idx].mouseMotion = .{};
                self.mouseState[idx].mouseWheel = .{};
                self.lastMouseMotionTime[idx] = 0;
                self.lastMouseWheelTime[idx] = 0;

                break :i idx;
            };

            const curState: State = a: {
                if (event.button.down) {
                    break :a .held;
                } else {
                    break :a .released;
                }
            };

            const s = self.mouseState[index].mouseButtons[event.button.button].seq.load(.acquire);

            _ = self.mouseState[index].mouseButtons[event.button.button].seq.store(s + 1, .release);

            self.mouseState[index].mouseButtons[event.button.button].state = curState;
            self.mouseState[index].mouseButtons[event.button.button].timestamp = event.button.timestamp;

            _ = self.mouseState[index].mouseButtons[event.button.button].seq.store(s + 2, .release);

            self.mouseState[index].mouseButtons[event.button.button].consumedID.store(maxU32, .release);

            input = .{
                .timestamp = event.key.timestamp,
                .hardwareID = hardwareID,
                .id = self.idAdd,
                .input = .{ .mouseButton = .{
                    .down = event.button.down,
                    .button = event.button.button,
                    .clicks = event.button.clicks,
                    .x = event.button.x,
                    .y = event.button.y,
                } },
            };
            // std.log.debug("set", .{});

            if (global.firstMouseID.load(.monotonic) == maxU32) {
                const isR = self.isRelative.load(.acquire);

                if (isR == 5) {
                    if (event.button.which != 0) global.firstMouseID.store(event.button.which, .monotonic);
                } else {
                    global.firstMouseID.store(event.button.which, .monotonic);
                }
            }
            global.usingGamepad.store(0, .monotonic);
        },
        .SDL_EVENT_MOUSE_MOTION => {
            const hardwareID = event.motion.which;
            const index = findHardwareIndex(self.stateIndexMouseID, hardwareID) orelse i: {
                const idx = self.stateIndexMouseID.len;

                if (idx == self.maxCount) return;

                @atomicStore(usize, &self.stateIndexMouseID.len, idx + 1, .monotonic);
                self.mouseState.len += 1;
                self.lastMouseMotionTime.len += 1;
                self.lastMouseWheelTime.len += 1;

                self.stateIndexMouseID[idx] = hardwareID;
                @memset(&self.mouseState[idx].mouseButtons, MouseButtonState{});
                self.mouseState[idx].mouseMotion = .{};
                self.mouseState[idx].mouseWheel = .{};
                self.lastMouseMotionTime[idx] = 0;
                self.lastMouseWheelTime[idx] = 0;

                break :i idx;
            };

            const x = if (isRelative == 5) event.motion.xrel else event.motion.x;
            const y = if (isRelative == 5) event.motion.yrel else event.motion.y;

            const s = self.mouseState[index].mouseMotion.seq.load(.acquire);

            _ = self.mouseState[index].mouseMotion.seq.store(s + 1, .release);

            self.mouseState[index].mouseMotion.timestamp = event.motion.timestamp;

            if (isRelative == 5) {
                _ = @atomicRmw(f32, &self.mouseState[index].mouseMotion.x, .Add, x, .release);
                _ = @atomicRmw(f32, &self.mouseState[index].mouseMotion.y, .Add, y, .release);
            } else {
                self.mouseState[index].mouseMotion.x = x;
                self.mouseState[index].mouseMotion.y = y;
            }

            _ = self.mouseState[index].mouseMotion.seq.store(s + 2, .release);
            // std.log.debug("set", .{});

            const time = self.lastMouseMotionTime[index];
            // std.log.debug("{d} : {d}", .{ event.motion.timestamp, time });
            if (event.motion.timestamp > 10 * std.time.ns_per_ms + time) {
                input = .{
                    .timestamp = event.motion.timestamp,
                    .hardwareID = hardwareID,
                    .id = self.idAdd,
                    .input = .{ .mouseMotion = .{
                        .x = x,
                        .y = y,
                    } },
                };
                self.lastMouseMotionTime[index] = event.motion.timestamp;
            } else {
                add = false;
            }

            if (global.firstMouseID.load(.monotonic) == maxU32) {
                const isR = self.isRelative.load(.acquire);

                if (isR == 5) {
                    if (event.motion.which != 0) global.firstMouseID.store(event.motion.which, .monotonic);
                } else {
                    global.firstMouseID.store(event.motion.which, .monotonic);
                }
            }
            global.usingGamepad.store(0, .monotonic);
        },
        .SDL_EVENT_MOUSE_WHEEL => {
            const hardwareID = event.wheel.which;
            const index = findHardwareIndex(self.stateIndexMouseID, hardwareID) orelse i: {
                const idx = self.stateIndexMouseID.len;

                if (idx == self.maxCount) return;

                @atomicStore(usize, &self.stateIndexMouseID.len, idx + 1, .monotonic);
                self.mouseState.len += 1;
                self.lastMouseMotionTime.len += 1;
                self.lastMouseWheelTime.len += 1;

                self.stateIndexMouseID[idx] = hardwareID;
                @memset(&self.mouseState[idx].mouseButtons, MouseButtonState{});
                self.mouseState[idx].mouseMotion = .{};
                self.mouseState[idx].mouseWheel = .{};
                self.lastMouseMotionTime[idx] = 0;
                self.lastMouseWheelTime[idx] = 0;

                break :i idx;
            };

            const s = self.mouseState[index].mouseWheel.seq.load(.acquire);
            const flip: f32 = if (event.wheel.direction == sdl.SDL_MOUSEWHEEL_FLIPPED) -1.0 else 1.0;

            _ = self.mouseState[index].mouseWheel.seq.store(s + 1, .release);

            self.mouseState[index].mouseWheel.timestamp = event.wheel.timestamp;
            _ = self.mouseState[index].mouseWheel.x.fetchAdd(event.wheel.x * flip, .release);
            _ = self.mouseState[index].mouseWheel.y.fetchAdd(event.wheel.y * flip, .release);
            self.mouseState[index].mouseWheel.mouse_x = event.wheel.mouse_x;
            self.mouseState[index].mouseWheel.mouse_y = event.wheel.mouse_y;

            _ = self.mouseState[index].mouseWheel.seq.store(s + 2, .release);
            // std.log.debug("set", .{});

            input = .{
                .timestamp = event.wheel.timestamp,
                .hardwareID = hardwareID,
                .id = self.idAdd,
                .input = .{ .mouseWheel = .{
                    .x = event.wheel.x * flip,
                    .y = event.wheel.y * flip,
                    .mouse_x = event.wheel.mouse_x * flip,
                    .mouse_y = event.wheel.mouse_y * flip,
                } },
            };
            self.lastMouseWheelTime[index] = event.wheel.timestamp;

            if (global.firstMouseID.load(.monotonic) == maxU32) {
                const isR = self.isRelative.load(.acquire);

                if (isR == 5) {
                    if (event.wheel.which != 0) global.firstMouseID.store(event.wheel.which, .monotonic);
                } else {
                    global.firstMouseID.store(event.wheel.which, .monotonic);
                }
            }
            global.usingGamepad.store(0, .monotonic);
        },
        .SDL_EVENT_GAMEPAD_BUTTON_DOWN, .SDL_EVENT_GAMEPAD_BUTTON_UP => {
            const hardwareID = event.gbutton.which;
            const index = findHardwareIndex(self.stateIndexGamepadID, hardwareID) orelse i: {
                const idx = self.stateIndexGamepadID.len;

                if (idx == self.maxCount) return;

                @atomicStore(usize, &self.stateIndexGamepadID.len, idx + 1, .monotonic);
                self.gamepadState.len += 1;
                self.lastGamepadAxisTime.len += 1;

                self.stateIndexGamepadID[idx] = hardwareID;

                @memset(&self.gamepadState[idx].gamepadButtons, GamePadButtonState{});
                @memset(&self.gamepadState[idx].gamepadAxis, GamePadAxisState{});
                @memset(&self.lastGamepadAxisTime[idx], 0);

                break :i idx;
            };

            // const preState = self.keyboardState[index].keys[event.key.scancode].state;
            var curState: State = .released;

            if (event.gbutton.down) {
                curState = .held;
            }

            const s = self.gamepadState[index].gamepadButtons[event.gbutton.button].seq.load(.acquire);

            _ = self.gamepadState[index].gamepadButtons[event.gbutton.button].seq.store(s + 1, .release);

            self.gamepadState[index].gamepadButtons[event.gbutton.button].state = curState;

            // if (!event.gbutton.repeat) {
            self.gamepadState[index].gamepadButtons[event.gbutton.button].timestamp = event.gbutton.timestamp;
            self.gamepadState[index].gamepadButtons[event.gbutton.button].generation += 1;
            self.gamepadState[index].gamepadButtons[event.gbutton.button].consumedID.store(maxU32, .release);
            // }

            _ = self.gamepadState[index].gamepadButtons[event.gbutton.button].seq.store(s + 2, .release);

            input = Input{
                .timestamp = event.gbutton.timestamp,
                .hardwareID = hardwareID,
                .id = self.idAdd,
                .input = .{ .gamepadButton = .{
                    .button = event.gbutton.button,
                    .down = event.gbutton.down,
                } },
            };

            if (global.firstGamepadID.load(.monotonic) == maxU32) global.firstGamepadID.store(event.gbutton.which, .monotonic);
            global.usingGamepad.store(1, .monotonic);
        },
        .SDL_EVENT_GAMEPAD_AXIS_MOTION => {
            const hardwareID = event.gaxis.which;
            const index = findHardwareIndex(self.stateIndexGamepadID, hardwareID) orelse i: {
                const idx = self.stateIndexGamepadID.len;

                if (idx == self.maxCount) return;

                @atomicStore(usize, &self.stateIndexGamepadID.len, idx + 1, .monotonic);
                self.gamepadState.len += 1;
                self.lastGamepadAxisTime.len += 1;

                self.stateIndexGamepadID[idx] = hardwareID;

                @memset(&self.gamepadState[idx].gamepadAxis, GamePadAxisState{});
                @memset(&self.gamepadState[idx].gamepadButtons, GamePadButtonState{});
                @memset(&self.lastGamepadAxisTime[idx], 0);

                break :i idx;
            };

            const s = self.gamepadState[index].gamepadButtons[event.gbutton.button].seq.load(.acquire);

            _ = self.gamepadState[index].gamepadAxis[event.gaxis.axis].seq.store(s + 1, .release);
            self.gamepadState[index].gamepadAxis[event.gaxis.axis] = .{
                .timestamp = event.key.timestamp,
                .axis = event.gaxis.axis,
                .value = event.gaxis.value,
            };
            _ = self.gamepadState[index].gamepadAxis[event.gaxis.axis].seq.store(s + 2, .release);

            add = false;

            // const time = self.lastGamepadAxisTime[index][event.gaxis.axis];
            // // std.log.debug("{d} : {d}", .{ event.motion.timestamp, time });
            // if (event.gaxis.timestamp > 10 * std.time.ns_per_ms + time) {
            //     input = .{
            //         .timestamp = event.gaxis.timestamp,
            //         .hardwareID = hardwareID,
            //         .id = self.idAdd,
            //         .input = .{ .gamepadAxis = .{
            //             .axis = event.gaxis.axis,
            //             .value = event.gaxis.value,
            //         } },
            //     };
            //     self.lastGamepadAxisTime[index][event.gaxis.axis] = event.gaxis.timestamp;
            // } else {
            //     add = false;
            // }

            if (global.firstGamepadID.load(.monotonic) == maxU32) global.firstGamepadID.store(event.gaxis.which, .monotonic);
            global.usingGamepad.store(1, .monotonic);
        },
        else => unreachable,
    }
    self.idAdd += 1;

    if (add and !self.stream.push(input)) {
        self.stream.pop();
        assert(self.stream.push(input));
    }
    if (add) {
        _ = count.fetchAdd(1, .monotonic);
        const t = SDL_GetTicksNS() - input.timestamp;
        _ = totalTime.fetchAdd(t, .monotonic);

        // std.log.debug(" {d} range: {d}", .{ input.timestamp, t });
    }

    const checktime = SDL_GetTicksNS();
    while (true) {
        const peek = self.stream.peekHead_A();
        if (peek) |p| {
            if (checktime - p.timestamp > MaxKeepMs_Ns) {
                // std.log.debug("aa", .{});
                self.stream.pop();
            } else {
                // std.log.debug("aaa", .{});
                break;
            }
        } else {
            break;
        }
    }
}

pub fn logKey(key: *Key) void {
    std.log.debug("down: {}, repeat: {}, timestamp: {d}, key: {s}", .{
        key.down,
        key.repeat,
        key.timestamp,
        // key.key,
        @tagName(@as(SDL_Scancode, @enumFromInt(key.key))),
    });
}

pub fn setWindowRelativeMouseMode(self: *Self, enabled: bool) void {
    if (enabled) {
        self.isRelative.store(1, .release);

        while (self.isRelative.cmpxchgWeak(2, 3, .release, .acquire)) |_| {
            atomic.spinLoopHint();
        }

        assert(sdl.SDL_SetWindowRelativeMouseMode(self.window, true));

        for (self.mouseState) |*mouseState| {
            @atomicStore(f32, &mouseState.mouseMotion.x, 0, .release);
            @atomicStore(f32, &mouseState.mouseMotion.y, 0, .release);
        }

        self.isRelative.store(4, .release);

        global.firstMouseID.store(maxU32, .monotonic);
    } else {
        self.isRelative.store(0, .release);

        global.firstMouseID.store(0, .monotonic);

        assert(sdl.SDL_SetWindowRelativeMouseMode(self.window, false));
    }
}

pub fn layoutIntoStruct(
    comptime Target: type,
    buffer: []u8,
    fixed_bytes: usize,
) struct {
    maxCount: usize,
    slices: Target,
} {
    const fields = std.meta.fields(Target);

    // 1. 编译期元数据收集与校验
    const FieldMeta = struct {
        name: [:0]const u8,
        Elem: type,
        alignment: usize,
        size: usize,
    };

    comptime var metas: [fields.len]FieldMeta = undefined;
    comptime var max_align: usize = 1;
    comptime var unit_size: usize = 0;

    inline for (fields, 0..) |f, i| {
        // 提取切片的元素类型（如 []u64 -> u64）
        const Elem = std.meta.Child(f.type);
        const elem_align = @alignOf(Elem);
        const elem_size = @sizeOf(Elem);

        metas[i] = .{
            .name = f.name,
            .Elem = Elem,
            .alignment = elem_align,
            .size = elem_size,
        };

        max_align = @max(max_align, elem_align);
        unit_size += elem_size;
    }

    // 2. 编译期按对齐大小降序排序（保证切片间 Padding 恒为 0）
    comptime {
        var i: usize = 0;
        while (i < metas.len) : (i += 1) {
            var j: usize = i + 1;
            while (j < metas.len) : (j += 1) {
                if (metas[j].alignment > metas[i].alignment) {
                    const tmp = metas[i];
                    metas[i] = metas[j];
                    metas[j] = tmp;
                }
            }
        }
    }

    // 3. 运行期：计算动态区域对齐起始点与长度上限
    const start_offset = std.mem.alignForward(usize, fixed_bytes, max_align);

    var result_slices: Target = undefined;

    // 边界情况：缓冲区不足
    if (start_offset >= buffer.len or unit_size == 0) {
        inline for (fields) |f| {
            @field(result_slices, f.name) = &.{};
        }
        return .{ .maxCount = 0, .slices = result_slices };
    }

    const available_bytes = buffer.len - start_offset;
    const max_len = available_bytes / unit_size; // 得出最大元素数量上限

    // 4. 按照排好序的对齐顺序在内存中顺序切分，并通过反射赋回对应名称的字段
    var offset = start_offset;
    inline for (metas) |m| {
        const ptr: [*]m.Elem = @ptrCast(@alignCast(buffer.ptr + offset));
        const slice = ptr[0..0];

        // 核心反射：按字段名写回到结果结构体中
        @field(result_slices, m.name) = slice;

        offset += max_len * m.size;
    }

    return .{
        .maxCount = max_len,
        .slices = result_slices,
    };
}
