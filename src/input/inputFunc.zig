const sdl = @import("sdl").sdl;

const std = @import("std");

const input = @import("input");

const tracy = @import("tracy");

pub const triggerPack = struct {
    down: bool = false,
    pre: bool = false,
    timestamp: u64 = 0,

    pub fn preIsTrue(self: *triggerPack) bool {
        defer self.pre = false;

        return self.pre;
    }
};

const short = 0;
const long = 1;
const inputTrigger = struct {
    keyPress: std.array_list.Managed([2]?*triggerPack),

    ID: u32 = 0,

    keyFunc: [sdl.SDL_SCANCODE_COUNT]u32,
    mouseButtons: [5]u32,
    gamepadButtons: [sdl.SDL_GAMEPAD_BUTTON_COUNT]u32,

    pub fn init(allocator: std.mem.Allocator) !*inputTrigger {
        const mem = try allocator.create(@This());

        mem.keyPress = .init(allocator);

        for (0..mem.keyFunc.len) |i| {
            mem.keyFunc[i] = 1000;
        }

        for (0..mem.mouseButtons.len) |i| {
            mem.mouseButtons[i] = 1000;
        }

        for (0..mem.gamepadButtons.len) |i| {
            mem.gamepadButtons[i] = 1000;
        }

        mem.ID = 0;

        return mem;
    }

    pub fn deinit(self: *inputTrigger) void {
        const allocator = self.keyPress.allocator;

        self.keyPress.deinit();

        allocator.destroy(self);
    }

    pub fn getID(self: *inputTrigger) u32 {
        defer self.ID += 1;

        return self.ID;
    }

    pub fn bindKey(
        self: *inputTrigger,
        ID: u32,
        key: sdl.SDL_Keycode,
        pTriggerPack: *triggerPack,
        isLong: bool,
    ) !void {
        if (self.keyFunc[key] != 1000) {
            return error.AlreadyBound;
        }

        self.keyFunc[key] = ID;

        if (self.keyPress.capacity < ID + 1) {
            const start = self.keyPress.items.len;

            try self.keyPress.ensureTotalCapacity(ID + 1);
            self.keyPress.expandToCapacity();

            for (start..self.keyPress.items.len) |i| {
                self.keyPress.items[i][0] = null;
                self.keyPress.items[i][1] = null;
            }
        }

        if (isLong) {
            self.keyPress.items[ID][long] = pTriggerPack;
        } else {
            self.keyPress.items[ID][short] = pTriggerPack;
        }
    }

    pub fn bindMouseButton(
        self: *inputTrigger,
        ID: u32,
        button: u32,
        pTriggerPack: *triggerPack,
        isLong: bool,
    ) !void {
        if (self.mouseButtons[button] != 1000) {
            return error.AlreadyBound;
        }

        self.mouseButtons[button] = ID;

        if (self.keyPress.capacity < ID + 1) {
            try self.keyPress.ensureTotalCapacity(ID + 1);
            self.keyPress.expandToCapacity();
        }

        if (isLong) {
            self.keyPress.items[ID][long] = pTriggerPack;
        } else {
            self.keyPress.items[ID][short] = pTriggerPack;
        }
    }

    pub fn bindGamepadButton(
        self: *inputTrigger,
        ID: u32,
        button: u32,
        pTriggerPack: *triggerPack,
        isLong: bool,
    ) !void {
        if (self.gamepadButtons[button] != 1000) {
            return error.AlreadyBound;
        }

        self.gamepadButtons[button] = ID;

        if (self.keyPress.capacity < ID + 1) {
            try self.keyPress.ensureTotalCapacity(ID + 1);
            self.keyPress.expandToCapacity();
        }

        if (isLong) {
            self.keyPress.items[ID][long] = pTriggerPack;
        } else {
            self.keyPress.items[ID][short] = pTriggerPack;
        }
    }

    const expiredTime = std.time.ns_per_ms * 40;
    pub fn set(self: *inputTrigger, pInput: *input.Input) void {
        switch (pInput.*) {
            .key => |key| {
                if (self.keyFunc[key.key] == 1000) {
                    return;
                }

                input.logKey(@constCast(&key));

                if (sdl.SDL_GetTicksNS() - key.timestamp > expiredTime) {
                    std.log.debug("exipred", .{});
                    return;
                }

                if (key.down) {
                    if (key.repeat) {
                        if (self.keyPress.items[self.keyFunc[key.key]][long]) |p| {
                            p.* = .{
                                .down = true,
                                .pre = false,
                                .timestamp = key.timestamp,
                            };
                        }
                    } else {
                        if (self.keyPress.items[self.keyFunc[key.key]][short]) |p| {
                            p.* = .{
                                .down = true,
                                .pre = false,
                                .timestamp = key.timestamp,
                            };
                        }
                    }
                } else {
                    if (self.keyPress.items[self.keyFunc[key.key]][long]) |p| {
                        const cur = p.down;
                        p.* = .{
                            .down = false,
                            .pre = cur,
                            .timestamp = key.timestamp,
                        };
                    }

                    if (self.keyPress.items[self.keyFunc[key.key]][short]) |p| {
                        p.* = .{
                            .down = false,
                            .pre = true,
                            .timestamp = key.timestamp,
                        };
                    }
                }
            },
            else => {},
        }
    }
};

const idInputTrigger = struct {
    ID: u32,
    pTriggerPack: [2]?*triggerPack,
};

const Self = @This();

triggerPackMem: std.heap.MemoryPoolExtra(triggerPack, .{}),
actionIdMap: std.hash_map.StringHashMap(idInputTrigger),

allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .triggerPackMem = .init(allocator),
        .actionIdMap = .init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    self.triggerPackMem.deinit();
    self.actionIdMap.deinit();
}

pub fn createInputTrigger(self: *Self) !*inputTrigger {
    return inputTrigger.init(self.allocator);
}

pub fn registerAction(
    self: *Self,
    pInputTrigger: *inputTrigger,
    name: []const u8,
    bindKey: ?sdl.SDL_Keycode,
    bindMouseButton: ?u32,
    bindGamepadButton: ?u32,
    isLong: bool,
) !*triggerPack {
    const zone = tracy.initZone(@src(), .{ .name = "register action" });
    defer zone.deinit();

    const res = try self.actionIdMap.getOrPut(name);
    var id: u32 = 0;
    var ptr: *triggerPack = undefined;

    if (res.found_existing) {
        id = res.value_ptr.ID;
        ptr = blk: {
            if (!isLong) {
                if (res.value_ptr.pTriggerPack[short]) |p| {
                    break :blk p;
                }
            }

            if (isLong) {
                if (res.value_ptr.pTriggerPack[long]) |p| {
                    break :blk p;
                }
            }

            break :blk try self.triggerPackMem.create();
        };

        res.value_ptr.pTriggerPack[if (isLong) long else short] = ptr;
    } else {
        id = pInputTrigger.getID();
        ptr = try self.triggerPackMem.create();

        res.key_ptr.* = name;
        res.value_ptr.* = .{
            .ID = id,
            .pTriggerPack = .{
                if (isLong) null else ptr,
                if (isLong) ptr else null,
            },
        };
    }

    if (bindKey) |key| {
        try pInputTrigger.bindKey(id, key, ptr, isLong);
    }

    if (bindMouseButton) |button| {
        try pInputTrigger.bindMouseButton(id, button, ptr, isLong);
    }

    if (bindGamepadButton) |button| {
        try pInputTrigger.bindGamepadButton(id, button, ptr, isLong);
    }

    return ptr;
}
