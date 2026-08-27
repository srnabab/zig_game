const std = @import("std");
const builtin = @import("builtin");

pub fn u8pack(comptime T: type) type {
    const info = @typeInfo(T);

    // @compileLog(std.fmt.comptimePrint("{s}", .{@tagName(std.meta.activeTag(info))}));
    if (info != .pointer) @compileError("not a slice");

    const ArrayType = info.pointer.child;

    if (ArrayType != u8) @compileError("not a slice of u8");

    return if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe)
        T
    else
        u32;
}
