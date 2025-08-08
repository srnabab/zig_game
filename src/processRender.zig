const std = @import("std");
const Thread = std.Thread;
const Atomic = std.atomic;
const Queue = @import("queue.zig");
const drawC = @import("drawCommand.zig");
const drawCProcess = @import("drawCommandProcess.zig");
const texture = @import("textureSet.zig");

pub const Drawable = struct {
    draw: bool,
    texture_t: *texture,
    time: i128,
};
const DrawableQueueType = Queue.QueueConstructor(Drawable);

var DrawableQueue: [3]DrawableQueueType = undefined;
var semaphore = Thread.Semaphore{};
var mutex = Thread.Mutex{};
var queueIndex = Atomic.Value(u32).init(0);
var semaphoreValue = Atomic.Value(u64).init(0);
var gpa: std.mem.Allocator = undefined;

pub fn init(allocator: std.mem.Allocator) !void {
    DrawableQueue[0] = try DrawableQueueType.init(allocator);
    DrawableQueue[1] = try DrawableQueueType.init(allocator);
    DrawableQueue[2] = try DrawableQueueType.init(allocator);
    gpa = allocator;
}

pub fn processStart() void {
    mutex.lock();
    defer mutex.unlock();
    const index = queueIndex.load(.seq_cst);
    queueIndex.store((index + 1) % 3, .seq_cst);
    DrawableQueue[(index + 1) % 3].reset();
    // std.log.info("index next {d}", .{(index + 1) % 3});

    semaphore.post();
    const value = semaphoreValue.fetchAdd(1, .seq_cst);
    if (value > 1) {
        _ = semaphoreValue.fetchSub(1, .seq_cst);
        semaphore.wait();
    }
}

pub fn addProcess(command: Drawable) !void {
    mutex.lock();
    defer mutex.unlock();
    const index = queueIndex.load(.seq_cst);
    try DrawableQueue[index].enqueue(command);
}

pub fn addProcesses(commands: []Drawable) !void {
    mutex.lock();
    defer mutex.unlock();
    const index = queueIndex.load(.seq_cst);
    try DrawableQueue[index].enqueues(commands);
}

/// do not call this function from more than one thread simultaneous
pub fn process() !void {
    semaphore.wait();
    const value = semaphoreValue.fetchSub(1, .seq_cst);
    std.log.info("value {d}", .{value});

    var index: u32 = 0;

    var queue: []Drawable = undefined;
    {
        std.log.info("process start", .{});
        mutex.lock();
        defer mutex.unlock();
        std.log.info("1: {d}, 2: {d}, 3: {d}", .{ DrawableQueue[0].count(), DrawableQueue[1].count(), DrawableQueue[2].count() });
        index = (queueIndex.load(.seq_cst) + 2) % 3;
        std.log.info("process {d}", .{index});
        queue = try gpa.alloc(Drawable, DrawableQueue[index].count());
        _ = DrawableQueue[index].toOwnedSlice(queue);
    }
    defer gpa.free(queue);

    std.log.info("current time {d}", .{std.time.nanoTimestamp()});
    for (queue) |data| {
        if (data.draw) {
            std.log.info("process once {} {d}", .{ data.draw, data.time });
        }
    }
}

pub fn deinit() void {
    for (0..10) |_|
        semaphore.post();

    DrawableQueue[0].deinit();
    DrawableQueue[1].deinit();
    DrawableQueue[2].deinit();
}
