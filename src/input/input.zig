const std = @import("std");

const sdl = @import("sdl").sdl;
const SDL_EventType = @import("sdl").SDL_EventType;
const SDL_Keycode = @import("sdl").SDL_Keycode;
const SDL_Scancode = @import("sdl").SDL_Scancode;

pub const Key = struct {
    down: bool = false,
    repeat: bool = false,
    key: sdl.SDL_Scancode = 0,
    timestamp: u64 = 0,
};

pub const MouseButton = struct {
    down: bool = false,
    clicks: u8 = 0,
    button: u8 = 0,
    x: f32 = 0,
    y: f32 = 0,
    timestamp: u64 = 0,
};

pub const Mouse = struct {
    x: f32 = 0,
    y: f32 = 0,
    relX: f32 = 0,
    relY: f32 = 0,
    timestamp: u64 = 0,
};

pub const MouseWheel = struct {
    x: f32 = 0,
    y: f32 = 0,
    timestamp: u64 = 0,
};

pub const GamePadAxis = struct {
    axis: u8 = 0,
    value: i16 = 0,
    timestamp: u64 = 0,
};

pub const GamePadButton = struct {
    pre: bool = false,
    down: bool = false,
    button: u8 = 0,
    timestamp: u64 = 0,
};

const InputType = enum {
    key,
    mouseButton,
    mouse,
    mouseWheel,
    gamepadAxis,
    gamepadButton,
};
pub const Input = union(InputType) {
    key: Key,
    mouseButton: MouseButton,
    mouse: Mouse,
    mouseWheel: MouseWheel,
    gamepadAxis: GamePadAxis,
    gamepadButton: GamePadButton,
};

const Self = @This();

keys: [sdl.SDL_SCANCODE_COUNT]Key,

// * - Button 1: Left mouse button
// * - Button 2: Middle mouse button
// * - Button 3: Right mouse button
// * - Button 4: Side mouse button 1
// * - Button 5: Side mouse button 2
mouseButtons: [5]MouseButton,

mouse: Mouse,
mouseWheel: MouseWheel,

gamepadAxis: [sdl.SDL_GAMEPAD_AXIS_COUNT]GamePadAxis,
gamepadButtons: [sdl.SDL_GAMEPAD_BUTTON_COUNT]GamePadButton,

mutex: std.Io.Mutex = .init,

inputQueue: std.array_list.Managed(Input),

pub fn init(allocator: std.mem.Allocator) !*Self {
    std.log.debug("input size {d}", .{@sizeOf(Input)});
    const mem = try allocator.create(@This());

    for (0..mem.keys.len) |i| {
        mem.keys[i] = .{};
    }

    for (0..mem.mouseButtons.len) |i| {
        mem.mouseButtons[i] = .{};
    }

    for (0..mem.gamepadAxis.len) |i| {
        mem.gamepadAxis[i] = .{};
    }

    for (0..mem.gamepadButtons.len) |i| {
        mem.gamepadButtons[i] = .{};
    }

    mem.mouse = .{};
    mem.mouseWheel = .{};
    mem.inputQueue = .init(allocator);
    mem.mutex = .init;

    return mem;
}

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    allocator.destroy(self);
}

pub fn setInput(self: *Self, io: std.Io, event: *sdl.SDL_Event) !void {
    // const eventType: SDL_EventType = @enumFromInt(event.type);

    switch (event.type) {
        sdl.SDL_EVENT_KEY_DOWN => {
            self.keys[event.key.scancode] = .{
                .down = event.key.down,
                .repeat = event.key.repeat,
                .timestamp = event.key.timestamp,
                .key = event.key.scancode,
            };

            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            try self.inputQueue.append(.{ .key = self.keys[event.key.scancode] });
        },
        sdl.SDL_EVENT_KEY_UP => {
            self.keys[event.key.scancode] = .{
                .down = event.key.down,
                .repeat = event.key.repeat,
                .timestamp = event.key.timestamp,
                .key = event.key.scancode,
            };

            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            try self.inputQueue.append(.{ .key = self.keys[event.key.scancode] });
        },
        sdl.SDL_EVENT_MOUSE_MOTION => {
            self.mouse = .{
                .x = event.motion.x,
                .y = event.motion.y,
                .relX = event.motion.xrel,
                .relY = event.motion.yrel,
                .timestamp = event.motion.timestamp,
            };

            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            try self.inputQueue.append(.{ .mouse = self.mouse });
        },
        else => {},
    }
}

pub fn getCurrentInput(self: *Self, io: std.Io) ![]Input {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    return self.inputQueue.toOwnedSlice();
}

pub fn releaseCurrentInput(self: *Self, io: std.Io, inputs: []Input) !void {
    try self.mutex.lock(io);
    defer self.mutex.unlock(io);

    self.inputQueue.allocator.free(inputs);
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
