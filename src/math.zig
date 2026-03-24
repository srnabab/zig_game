const std = @import("std");
const cglm = @import("cglm").cglm;

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

pub inline fn glm_ortho_vulkan(left: f32, right: f32, bottom: f32, top: f32, nearZ: f32, farZ: f32, dest: *cglm.mat4) void {
    var rl: f32 = 0.0;
    var tb: f32 = 0.0;
    var Fn: f32 = 0.0;

    cglm.glm_mat4_zero(&dest.*);

    rl = 1.0 / (right - left);
    tb = 1.0 / (top - bottom);
    Fn = 1.0 / (farZ - nearZ); // 修改：Vulkan 使用 [0, 1] 范围

    dest[0][0] = 2.0 * rl;
    dest[1][1] = -2.0 * tb;
    dest[2][2] = Fn; // 修改：Z 值映射到 [0, 1]
    dest[3][0] = -(right + left) * rl;
    dest[3][1] = -(top + bottom) * tb;
    dest[3][2] = -nearZ * Fn; // 修改：适配 Vulkan 深度范围
    dest[3][3] = 1.0;
}
