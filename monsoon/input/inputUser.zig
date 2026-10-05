const std = @import("std");

const maxU32 = std.math.maxInt(u32);

const global = @import("global");

const u8pack = @import("u8pack");
const Str = u8pack.Str;

const input = @import("input");
const Router = @import("inputRouter");

pub const InputUser = struct {
    keyboardID: u32 = maxU32,
    mouseID: u32 = maxU32,
    gamepadID: u32 = maxU32,

    const BoundCall = struct {
        b: *InputUser,
        a: *Router.InputAction,

        /// the stream do not have gamepad axis, so wasTriggered on them always return false
        pub fn wasTriggered(self: BoundCall, duration: f32) bool {
            return self.a.wasTriggered(duration, self.b.keyboardID, self.b.mouseID, self.b.gamepadID);
        }

        pub fn getHoldDuration(self: BoundCall) ?f32 {
            return self.a.getHoldDuration(self.b.keyboardID, self.b.mouseID, self.b.gamepadID);
        }

        pub fn consume(self: BoundCall) void {
            return self.a.consume(self.b.gamepadID != std.math.maxInt(u32));
        }

        pub fn getValue2(
            self: BoundCall,
            isCamera: bool,
            mouseSens: f32,
            stickSens: f32,
            deltaTime: f32,
        ) [2]f32 {
            return self.a.getValue2(
                self.b.keyboardID,
                self.b.mouseID,
                self.b.gamepadID,
                isCamera,
                mouseSens,
                stickSens,
                deltaTime,
            );
        }

        pub fn getValue1(self: BoundCall) f32 {
            return self.a.getValue1(self.b.keyboardID, self.b.mouseID, self.b.gamepadID);
        }
    };

    pub fn using(self: *InputUser, action: *Router.InputAction) BoundCall {
        return .{ .b = self, .a = action };
    }
};

const Self = @This();

pInput: *input,

singleUser: InputUser = .{},
keyboardSet: bool = false,
mouseSet: bool = false,
gamepadSet: bool = false,

multUsers: []InputUser = &.{},
mode: u32 = 0,

pub fn update(self: *Self) void {
    if (self.mode == 0) {
        if (!self.keyboardSet) {
            const id = global.firstKeyboardID.load(.monotonic);
            if (id != maxU32) {
                self.singleUser.keyboardID = id;
                self.keyboardSet = true;
            }
        }

        if (!self.mouseSet) {
            const id = global.firstMouseID.load(.monotonic);
            if (id != maxU32) {
                self.singleUser.mouseID = id;
                self.mouseSet = true;
            }
        }

        if (!self.gamepadSet) {
            const id = global.firstGamepadID.load(.monotonic);
            if (id != maxU32) {
                self.singleUser.gamepadID = id;
                self.gamepadSet = true;
            }
        }

        if (global.usingGamepad.load(.monotonic) == 1) {
            const id = global.firstGamepadID.load(.monotonic);
            if (id != maxU32) {
                self.singleUser.gamepadID = id;
                self.gamepadSet = true;
            }
        } else {
            self.singleUser.gamepadID = maxU32;
        }
    }
}

pub fn getSingleUser(self: *Self) *InputUser {
    return &self.singleUser;
}

pub fn setWindowRelativeMouseMode(self: *Self, enabled: bool) void {
    self.pInput.setWindowRelativeMouseMode(enabled);
    self.mouseSet = false;
}
