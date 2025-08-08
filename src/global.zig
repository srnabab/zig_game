const std = @import("std");
const Allocator = std.mem.Allocator;
// const texture = @import("textureSet.zig");

pub var gpa: Allocator = undefined;
pub var down = false;
// pub var textureHashMap: texture.HashMapType = undefined;

// pub fn init(allocator: Allocator) !void {
//     textureHashMap = HashMapType.init(allocator);
// }
