const std = @import("std");
const Thread = std.Thread;
const Mutex = std.Thread.Mutex;

var carshListTest = [_]usize{0} ** 16;
var queuesTest = [_]usize{0} ** 16;
var mutexs = [_]Mutex{.{}} ** 16;
var gMutex: Mutex = .{};
var done = false;

fn getQueue() usize {
    var minest: usize = carshListTest[0];
    var index: usize = 0;
    for (carshListTest, 0..carshListTest.len) |aaa, i| {
        if (aaa == 0) {
            carshListTest[i] += 1;
            return i;
        } else {
            minest = @min(minest, aaa);
            if (minest == aaa) {
                index = i;
            }
        }
    }
    carshListTest[index] += 1;
    return index;
}

fn releaseQueue(queu: usize) void {
    if (carshListTest[queu] > 0) {
        carshListTest[queu] -= 1;
    }
}

fn testRun() void {
    while (true) {
        gMutex.lock();
        const index = getQueue();
        // std.debug.print("get index {d}\n", .{index});
        gMutex.unlock();

        mutexs[index].lock();
        // std.debug.print("lock\n", .{});
        std.debug.print("queue{d} using\n", .{index});
        std.time.sleep(std.crypto.random.int(u64) % 1000000000);
        // std.debug.print("unlock\n", .{});
        mutexs[index].unlock();

        gMutex.lock();
        releaseQueue(index);
        // std.debug.print("release index {d}\n", .{index});
        gMutex.unlock();
        if (done) break;
    }
}

test "main queue test" {
    // const status = [_]VkQueuStatus{.EMPTY} ** 16;

    // var freeQueueCount: u32 = 16;
    for (0..queuesTest.len) |i| {
        queuesTest[i] += i;
    }
    var threads: [64]Thread = undefined;
    for (0..threads.len) |i| {
        threads[i] = try Thread.spawn(.{}, testRun, .{});
    }
    std.time.sleep(3000000000);
    done = true;
    for (threads) |thread| {
        Thread.join(thread);
    }
}
