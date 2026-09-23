const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const mstd = @import("std.zig");

const tracy = @import("tracy");

/// double-buffering queue
/// spsc
/// call swap in consumer thread
pub fn doubleBufferQueue(T: type) type {
    return struct {
        const Self = @This();
        const Deque = mstd.FixedIndexArray(T);

        allocator: Allocator,
        queues: [2]Deque,

        consumerIdx: u32 = 1,

        state: std.atomic.Value(u32) = .init(0),

        writers: std.atomic.Value(u32) = .init(0),

        pub fn init(allocator: Allocator, io: Io) !Self {
            _ = io;

            return .{
                .allocator = allocator,
                .queues = .{ .init(allocator), .init(allocator) },
            };
        }

        pub fn deinit(self: *Self) void {
            for (&self.queues) |*queue| {
                queue.deinit();
            }
        }

        /// append in proceduer
        pub fn appendP(self: *Self, data: T) !void {
            const zone = tracy.initZone(@src(), .{ .name = "doubleBufferQueue pushLastP" });
            defer zone.deinit();

            while (true) {
                const s0 = self.state.load(.seq_cst);
                if (s0 & 1 != 0) {
                    std.atomic.spinLoopHint();
                    continue;
                }

                _ = self.writers.fetchAdd(1, .seq_cst);
                if (self.state.load(.seq_cst) != s0) {
                    _ = self.writers.fetchSub(1, .seq_cst);
                    std.atomic.spinLoopHint();
                    continue;
                }

                const idx = (s0 >> 1) & 1;
                self.queues[idx].append(data) catch |err| {
                    _ = self.writers.fetchSub(1, .seq_cst);
                    return err;
                };
                _ = self.writers.fetchSub(1, .seq_cst);
                return;
            }
        }

        /// append to consumer
        pub fn appendC(self: *Self, data: T) !void {
            try self.queues[self.consumerIdx].append(data);
        }

        pub fn iterateC(self: *Self) Deque.Iterator {
            return self.queues[self.consumerIdx].iterate();
        }

        pub fn removeAt(self: *Self, index: usize) void {
            self.queues[self.consumerIdx].remove(index);
        }

        pub fn swap(self: *Self) void {
            const zone = tracy.initZone(@src(), .{ .name = "doubleBufferQueue swap" });
            defer zone.deinit();

            _ = self.state.fetchAdd(1, .seq_cst);
            while (self.writers.load(.seq_cst) != 0) {
                std.atomic.spinLoopHint();
            }

            self.consumerIdx = 1 - self.consumerIdx;

            _ = self.state.fetchAdd(1, .seq_cst);
        }
    };
}
