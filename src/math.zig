const std = @import("std");

fn doubleWidthCast(value: anytype) doubleWidthIntType(@TypeOf(value)) {
    return @intCast(value);
}

fn doubleWidthIntType(comptime T: type) type {
    const info = @typeInfo(T);

    std.debug.assert(info == .int and info.int.signedness == .unsigned);

    return @Type(.{
        .int = .{
            .signedness = .unsigned,
            .bits = info.int.bits * 2,
        },
    });
}

pub fn szudzikPairing(a: anytype, b: @TypeOf(a)) doubleWidthIntType(@TypeOf(b)) {
    const doubleA = doubleWidthCast(a);
    const doubleB = doubleWidthCast(b);
    return if (a >= b) doubleA * doubleA + doubleA + doubleB else doubleB * doubleB + doubleA;
}

pub inline fn round(comptime integer: usize, value: usize) usize {
    std.debug.assert(integer % 2 == 0);

    const minus1 = integer - 1;

    return (value + minus1) & (~minus1);
}
