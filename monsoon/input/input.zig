const std = @import("std");
const Allocator = std.mem.Allocator;
const Mutex = std.Io.Mutex;

const assert = std.debug.assert;

const mstd = @import("ms_std");

const RingBuffer = mstd.RingBuffer;

const sdl = @import("sdl").sdl;
const SDL_EventType = @import("sdl").SDL_EventType;
const SDL_Keycode = @import("sdl").SDL_Keycode;
const SDL_Scancode = @import("sdl").SDL_Scancode;

const SDL_GetTicksNS = sdl.SDL_GetTicksNS;

const MaxKeepMs = 500;
const MaxCountPerSecond = 150;

const State = enum(u8) {
    released,
    held,
};

pub const Key = struct {
    down: bool = false,
    repeat: bool = false,
    key: sdl.SDL_Scancode = 0,
    timestamp: u64 = 0,
    hardwareID: sdl.SDL_KeyboardID = 0,
};
pub const KeyState = struct {
    state: State = .released,
    timestamp: u64 = 0,
    consumedID: u32 = 0,
};

pub const MouseButton = struct {
    down: bool = false,
    clicks: u8 = 0,
    button: u8 = 0,
    x: f32 = 0,
    y: f32 = 0,
    timestamp: u64 = 0,
    hardwareID: sdl.SDL_MouseID = 0,
};
pub const MouseButtonState = struct {
    state: State = .released,
    timestamp: u64 = 0,
    consumedID: u32 = 0,
};

pub const MouseMotion = struct {
    x: f32 = 0,
    y: f32 = 0,
    timestamp: u64 = 0,
    hardwareID: sdl.SDL_MouseID = 0,
};
pub const MouseMotionState = struct {
    x: f32 = 0,
    y: f32 = 0,
    timestamp: u64 = 0,
};

pub const MouseWheel = struct {
    x: f32 = 0,
    y: f32 = 0,
    mouse_x: f32 = 0,
    mouse_y: f32 = 0,
    timestamp: u64 = 0,
    hardwareID: sdl.SDL_MouseID = 0,
};
pub const MouseWheelState = struct {
    x: f32 = 0,
    y: f32 = 0,
    mouse_x: f32 = 0,
    mouse_y: f32 = 0,
    timestamp: u64 = 0,
};

pub const GamePadAxis = struct {
    axis: u8 = 0,
    value: i16 = 0,
    timestamp: u64 = 0,
    hardwareID: sdl.SDL_JoystickID = 0,
};
pub const GamePadAxisState = struct {
    axis: u8 = 0,
    value: i16 = 0,
    timestamp: u64 = 0,
};

pub const GamePadButton = struct {
    pre: bool = false,
    down: bool = false,
    button: u8 = 0,
    timestamp: u64 = 0,
    hardwareID: sdl.SDL_JoystickID = 0,
};
pub const GamePadButtonState = struct {
    state: State,
    timestamp: u64 = 0,
    consumedID: u32 = 0,
};

const InputType = enum {
    key,
    mouseMotion,
    mouseButton,
    mouseWheel,
    gamepadAxis,
    gamepadButton,
};
pub const Input = union(InputType) {
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
    mouseButtons: [5]MouseButtonState,

    mouseMotion: MouseMotionState,
    mouseWheel: MouseWheelState,
};
const GamePad = struct {
    gamepadAxis: [sdl.SDL_GAMEPAD_AXIS_COUNT]GamePadAxisState,
    gamepadButtons: [sdl.SDL_GAMEPAD_BUTTON_COUNT]GamePadButtonState,
};

const StreamType = RingBuffer(Input, (MaxCountPerSecond * 1000) / MaxKeepMs);

const Self = @This();

allocator: Allocator,
mutex: Mutex = .init,
window: *sdl.SDL_Window,

isRelative: bool,

stateIndexKeyboardID: []sdl.SDL_KeyboardID = &.{},
stateIndexMouseID: []sdl.SDL_MouseID = &.{},
stateIndexGamepadID: []sdl.SDL_JoystickID = &.{},

keyboardState: []Keyborad = &.{},
mouseState: []Mouse = &.{},
gamepadState: []GamePad = &.{},

stream: std.array_list.Managed(Input),

pub fn init(allocator: std.mem.Allocator, window: *sdl.SDL_Window) !Self {
    std.log.debug("input size {d}", .{@sizeOf(Input)});

    return .{
        .stream = .init(allocator),
        .allocator = allocator,
        .window = window,
        .isRelative = false,
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.stateIndexGamepadID);
    self.allocator.free(self.stateIndexMouseID);
    self.allocator.free(self.stateIndexKeyboardID);
    self.allocator.free(self.keyboardState);
    self.allocator.free(self.gamepadState);
    self.allocator.free(self.mouseState);

    self.stream.deinit();
}

fn findHardwareIndex(maps: []u32, hardwareID: u32) ?u32 {
    for (maps, 0..) |value, i| {
        if (hardwareID == value) return @intCast(i);
    }

    return null;
}

pub fn setInput(self: *Self, io: std.Io, event: *sdl.SDL_Event) !void {
    const eventType: SDL_EventType = @enumFromInt(event.type);

    switch (eventType) {
        .SDL_EVENT_KEY_DOWN, .SDL_EVENT_KEY_UP => {
            const hardwareID = event.key.which;
            const index = findHardwareIndex(self.stateIndexKeyboardID, hardwareID) orelse i: {
                const idx = self.stateIndexKeyboardID.len;
                self.stateIndexKeyboardID = try self.allocator.realloc(self.stateIndexKeyboardID, idx + 1);
                self.keyboardState = try self.allocator.realloc(self.keyboardState, idx + 1);

                self.stateIndexKeyboardID[idx] = hardwareID;
                @memset(&self.keyboardState[idx].keys, KeyState{});

                break :i idx;
            };

            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            // const preState = self.keyboardState[index].keys[event.key.scancode].state;

            const curState: State = a: {
                if (event.key.down) {
                    break :a .held;
                } else {
                    break :a .released;
                }
            };

            self.keyboardState[index].keys[event.key.scancode] = .{
                .state = curState,
                .timestamp = event.key.timestamp,
            };

            try self.stream.append(.{ .key = .{
                .down = event.key.down,
                .repeat = event.key.repeat,
                .key = event.key.scancode,
                .timestamp = event.key.timestamp,
                .hardwareID = hardwareID,
            } });
        },
        .SDL_EVENT_MOUSE_MOTION => {
            const hardwareID = event.motion.which;
            const index = findHardwareIndex(self.stateIndexMouseID, hardwareID) orelse i: {
                const idx = self.stateIndexMouseID.len;
                self.stateIndexMouseID = try self.allocator.realloc(self.stateIndexMouseID, idx + 1);
                self.mouseState = try self.allocator.realloc(self.mouseState, idx + 1);

                self.stateIndexMouseID[idx] = hardwareID;
                @memset(&self.mouseState[idx].mouseButtons, MouseButtonState{});
                self.mouseState[idx].mouseMotion = .{};
                self.mouseState[idx].mouseWheel = .{};

                break :i idx;
            };

            const x = if (self.isRelative) event.motion.xrel else event.motion.x;
            const y = if (self.isRelative) event.motion.yrel else event.motion.y;

            self.mouseState[index].mouseMotion = .{
                .timestamp = event.key.timestamp,
                .x = x,
                .y = y,
            };

            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            try self.stream.append(.{ .mouseMotion = .{
                .x = x,
                .y = y,
                .timestamp = event.motion.timestamp,
                .hardwareID = event.motion.which,
            } });
        },
        .SDL_EVENT_MOUSE_BUTTON_DOWN, .SDL_EVENT_MOUSE_BUTTON_UP => {
            const hardwareID = event.button.which;
            const index = findHardwareIndex(self.stateIndexMouseID, hardwareID) orelse i: {
                const idx = self.stateIndexMouseID.len;
                self.stateIndexMouseID = try self.allocator.realloc(self.stateIndexMouseID, idx + 1);
                self.mouseState = try self.allocator.realloc(self.mouseState, idx + 1);

                self.stateIndexMouseID[idx] = hardwareID;
                @memset(&self.mouseState[idx].mouseButtons, MouseButtonState{});
                self.mouseState[idx].mouseMotion = .{};
                self.mouseState[idx].mouseWheel = .{};

                break :i idx;
            };

            const curState: State = a: {
                if (event.button.down) {
                    break :a .held;
                } else {
                    break :a .released;
                }
            };

            self.mouseState[index].mouseButtons[event.button.button] = .{
                .state = curState,
                .timestamp = event.button.timestamp,
            };

            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            try self.stream.append(.{ .mouseButton = .{
                .down = event.button.down,
                .button = event.button.button,
                .clicks = event.button.clicks,
                .x = event.button.x,
                .y = event.button.y,
                .timestamp = event.motion.timestamp,
                .hardwareID = event.motion.which,
            } });
        },
        else => unreachable,
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

pub fn setWindowRelativeMouseMode(self: *Self, enabled: bool) !void {
    assert(sdl.SDL_SetWindowRelativeMouseMode(self.window, enabled));
    self.isRelative = enabled;
}
