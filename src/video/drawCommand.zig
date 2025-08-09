const std = @import("std");
const texture = @import("textureSet.zig");

pub const DrawType = enum {
    graphic,
};

drawType: DrawType,
timestamp: i128 = 0,
texture_t: ?*texture,
