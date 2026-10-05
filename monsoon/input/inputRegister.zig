const std = @import("std");
const Allocator = std.mem.Allocator;

const mstd = @import("ms_std");

const u8pack = @import("u8pack");
const Str = u8pack.Str;

pub const InputAction = struct {
    name: Str,
    strictSeq: bool,
    isPulse: bool,
    needValue: bool,
    isCamera: bool,
    maxInputCount: u32,
};

var actionArray: std.array_list.Managed(InputAction) = undefined;
var actionMap: u8pack.HashMap(InputAction) = undefined;

var allocator: std.heap.ArenaAllocator = undefined;

pub fn init(gpa: Allocator) void {
    actionArray = .init(gpa);
    actionMap = .init(gpa);

    allocator = .init(gpa);
}

pub fn deinit() void {
    actionArray.deinit();
    actionMap.deinit();

    allocator.deinit();
}

pub fn createInputAction(
    comptime ctx: ?*u8pack.CTX,
    comptime name: []const u8,
    comptime strictSeq: bool,
    comptime isPulse: bool,
    comptime needValue: bool,
    comptime isCamera: bool,
    comptime maxInputCount: u32,
) !InputAction {
    if (ctx != null) {
        ctx.?.inputActions = ctx.?.inputActions ++ .{name};

        return undefined;
    } else {
        var name_str = u8pack.toStr(name);
        if (actionMap.get(name_str)) |buffer| {
            return buffer;
        }

        const name_dupe = try allocator.allocator().dupe(u8, name);
        name_str.name = name_dupe;

        const inputAction = InputAction{
            .name = name_str,
            .strictSeq = strictSeq,
            .isPulse = isPulse,
            .isCamera = isCamera,
            .needValue = needValue,
            .maxInputCount = maxInputCount,
        };

        try actionMap.put(name_str, inputAction);
        try actionArray.append(inputAction);

        return inputAction;
    }
}

pub fn getActionCount() u32 {
    return @intCast(actionArray.items.len);
}

pub fn getAction(index: u32) InputAction {
    return actionArray.items[index];
}
