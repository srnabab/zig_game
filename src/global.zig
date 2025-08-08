const std = @import("std");
const Allocator = std.mem.Allocator;
const texture = @import("textureSet.zig");
const HashMapType = @import("linkedListHashMap.zig").AutoLinkedListHashMap(u64, texture, 16);
const Node = HashMapType.Node;

pub var down = false;
pub var textureHashMap: HashMapType = undefined;

pub fn init(allocator: Allocator) !void {
    textureHashMap = HashMapType.init(allocator);
}
