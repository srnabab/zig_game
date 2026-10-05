const std = @import("std");
const Allocator = std.mem.Allocator;
const atomic = std.atomic;

const assert = std.debug.assert;

const tracy = @import("tracy");

pub fn ObserverRingBuffer(T: type, Capacity: usize) type {
    assert(Capacity % 2 == 0);

    return struct {
        const Slot = struct {
            seq: atomic.Value(u32) = .init(0),
            data: T,
        };

        const Self = @This();

        pub const empty = Self{
            .buffer = undefined,
        };

        buffer: [Capacity]Slot,
        head: atomic.Value(u64) align(64) = .init(0),
        tail: atomic.Value(u64) align(64) = .init(0),

        pub fn init(allocator: Allocator) !Self {
            return .{ .buffer = try allocator.alloc(Slot, Capacity) };
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            allocator.free(self.buffer);
        }

        pub fn push(self: *Self, data: T) bool {
            const zone = tracy.initZone(@src(), .{ .name = "observerRingBuffer push" });
            defer zone.deinit();

            const t = self.tail.load(.acquire);
            const h = self.head.load(.acquire);

            if (t - h >= Capacity) return false;

            const slot = &self.buffer[t & (Capacity - 1)];

            _ = slot.seq.fetchAdd(1, .acquire);
            slot.data = data;

            _ = slot.seq.fetchAdd(1, .release);

            self.tail.store(t + 1, .release);

            return true;
        }

        pub fn pop(self: *Self) void {
            const zone = tracy.initZone(@src(), .{ .name = "observerRingBuffer pop" });
            defer zone.deinit();

            const t = self.tail.load(.acquire);
            const h = self.head.load(.acquire);

            if (h == t) return;

            // slot.data = undefined;

            self.head.store(h + 1, .release);
        }

        pub fn peekHead_A(self: *Self) ?T {
            const zone = tracy.initZone(@src(), .{ .name = "observerRingBuffer peek head a" });
            defer zone.deinit();

            const h = self.head.load(.acquire);
            const t = self.tail.load(.acquire);

            if (h == t) return null;

            // std.log.debug("{d}, {d}", .{ h, t });

            return self.buffer[h & (Capacity - 1)].data;
        }

        /// when checkFn return true at 0, traverse will end, result will at 1, new checkFn res will replace old, when conflict happened, return false
        pub fn traverseFromTail(self: *Self, checkValue: anytype, comptime checkFn: fn (v: @TypeOf(checkValue), data: *const T) [2]bool) bool {
            const t_snap = self.tail.load(.acquire);
            const h_snap = self.head.load(.acquire);

            if (t_snap == h_snap) return false;

            const available = t_snap - h_snap;
            const count: u64 = @min(Capacity, available);

            const start_idx = t_snap - count;

            var i = t_snap;
            var res = [_]bool{false} ** 2;
            while (i > start_idx) : (i -= 1) {
                const data = &self.buffer[(i - 1) & (Capacity - 1)];

                res = checkFn(checkValue, &data.data);
                if (res[0]) break;
            }

            const t_now = self.tail.load(.acquire);
            const h_now = self.head.load(.acquire);

            if (i < h_now) {
                std.log.info("failed because of conflict", .{});
                return false;
            }

            if (t_now - start_idx > Capacity) {
                std.log.info("failed because of conflict", .{});
                return false;
            }

            return res[1];
        }
    };
}
