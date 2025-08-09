const drawCommand = @import("drawCommand.zig");
const texture = @import("textureSet.zig");
const std = @import("std");
const Atomic = std.atomic;
const global = @import("../global.zig");
// const textureHashMap = global.textureHashMap;
const DrawCommandMemoryPool = std.heap.MemoryPoolExtra(drawCommand, .{ .alignment = @alignOf(drawCommand) });

const linkedList = std.SinglyLinkedList(drawCommand);

var drawCommandMem: DrawCommandMemoryPool = undefined;
const max_count = 16;
var threadLinkedLists: [2][max_count]linkedList = undefined;
var listsIndex = Atomic.Value(u32).init(0);

pub fn init(allocator: std.mem.Allocator) void {
    drawCommandMem = DrawCommandMemoryPool.init(allocator);
}
pub fn addGraphicCommand(texture_t: *texture) !void {
    var dm = try drawCommandMem.create();
    dm.drawType = .graphic;
    dm.texture_t = texture_t;
    // std.log.info("pointer {*}", .{dm.texture_t});
}

pub fn deinit() void {
    drawCommandMem.deinit();
}
