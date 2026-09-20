const std = @import("std");

pub const maps = [_][]const u8{
    "rdatas",
};

pub fn rdatas() std.StaticStringMap(u32) {
    return .initComptime(.{
        .{ "sprite", 0 },
        .{ "feather", 1 },
    });
}
