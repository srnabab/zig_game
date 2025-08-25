const std = @import("std");
const Mutex = std.Thread.Mutex;
const Atomic = std.atomic;
const global = @import("global");

const Self = @This();

pub const HashMapType = @import("../linkedListHashMap.zig").AutoLinkedListHashMap(u64, Self, 16);
pub const Node = HashMapType.Node;

ID: u64,

const memType = std.heap.MemoryPoolExtra(Node, .{ .alignment = @alignOf(Node) });
var mem: memType = undefined;
var AutoIncrecemetnID = Atomic.Value(u64).init(0);
var mutex = Mutex{};
pub var textureSet: HashMapType = undefined;

pub fn init() void {
    mem = memType.init(global.gpa);
    textureSet = HashMapType.init(global.gpa);
}

pub fn addTexture() !*Self {
    mutex.lock();
    defer mutex.unlock();

    const ID = AutoIncrecemetnID.fetchAdd(1, .seq_cst);
    var temp = try mem.create();
    temp.data.key = ID;
    temp.data.value = Self{ .ID = ID };
    try textureSet.put(temp);

    return &temp.data.value;
}

pub fn deinit() void {
    textureSet.deinit();
    mem.deinit();
}
