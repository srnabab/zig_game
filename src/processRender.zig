const std = @import("std");
const Thread = std.Thread;
const Queue = @import("queue.zig");

pub const Drawable = struct {
    draw: bool,
};
const DrawableQueueType = Queue.QueueConstructor(Drawable);

var DrawableQueue: DrawableQueueType = undefined;
var semaphore = Thread.Semaphore{};
var mutex = Thread.Mutex{};
var end = false;

pub fn init(allocator: std.mem.Allocator) !void {
    DrawableQueue = try DrawableQueueType.init(allocator);
}

pub fn processStart() void {
    semaphore.post();
}

pub fn processEnd() void {
    mutex.lock();
    defer mutex.unlock();
    end = true;
}

pub fn addProcess(command: Drawable) !void {
    mutex.lock();
    defer mutex.unlock();
    const value = command;
    try DrawableQueue.enqueue(value);
}

pub fn process() void {
    semaphore.wait();

    while (true) {
        mutex.lock();
        defer mutex.unlock();
        if (DrawableQueue.count() == 0) {
            if (end) {
                end = false;
                break;
            }

            continue;
        }
        const data = DrawableQueue.dequeue().?;
        std.log.info("process once {}, count: {d}", .{ data.draw, DrawableQueue.count() });
    }
}

pub fn deinit() void {
    DrawableQueue.deinit();
}
