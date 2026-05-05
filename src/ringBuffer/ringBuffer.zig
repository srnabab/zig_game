const std = @import("std");
const atomic = std.atomic;

/// spsc
pub fn RingBuffer(T: type, comptime capacity: u32) type {
    var bit: u32 = 0;
    var value: u32 = capacity;
    while (value != 0) : (value /= 2) {
        bit += 1;
    }

    const actualCapacity = 1 << bit;

    return struct {
        const Self = @This();
        const MASK = actualCapacity - 1;

        data: [actualCapacity]T align(64),
        head: atomic.Value(u64) align(64) = .init(0),
        tail: atomic.Value(u64) align(64) = .init(0),

        pub fn init() Self {
            return .{
                .data = undefined,
                .head = .init(0),
                .tail = .init(0),
            };
        }

        pub fn push(self: *Self, item: T) bool {
            const cur_tail = self.tail.load(.seq_cst);
            const next_tail = (cur_tail + 1) & MASK;

            if (next_tail == self.head.load(.seq_cst)) {
                return false;
            }

            self.data[cur_tail] = item;

            self.tail.store(next_tail, .seq_cst);
            return true;
        }

        pub fn pop(self: *Self) ?T {
            const cur_head = self.head.load(.seq_cst);

            if (cur_head == self.tail.load(.seq_cst)) {
                return null;
            }

            const item = self.data[cur_head];
            self.head.store((cur_head + 1) & MASK, .seq_cst);

            return item;
        }
    };
}
