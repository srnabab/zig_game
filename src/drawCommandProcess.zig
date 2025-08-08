const drawCommand = @import("drawCommand.zig");
const texture = @import("textureSet.zig");
const std = @import("std");
const Atomic = std.atomic;
const global = @import("global.zig");
const textureHashMap = global.textureHashMap;
const memoryPool = std.heap.MemoryPool;

const linkedList = std.SinglyLinkedList(drawCommand);

const max_count = 16;
var threadLinkedLists: [2][max_count]linkedList = undefined;
var listsIndex = Atomic.Value(u32).init(0);

pub fn addGraphicCommand(texture_t: *texture) !void {}
