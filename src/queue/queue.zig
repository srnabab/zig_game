const std = @import("std");
const DoublyLinkedList = std.DoublyLinkedList;
const Allocator = std.mem.Allocator;
const Mutex = std.Io.Mutex;
const MemoryPoolExtra = std.heap.MemoryPoolExtra;

const tracy = @import("tracy");

pub fn Queue(T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        buffer: []T = &.{},
        head: usize = 0,
        totalSize: usize = 0,
        mutex: Mutex = .init,
        io: std.Io,

        pub fn init(allocator: Allocator, io: std.Io) !Self {
            return .{
                .allocator = allocator,
                .buffer = try allocator.alloc(T, 128),
                .io = io,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.buffer.len > 0) {
                self.allocator.free(self.buffer);
                self.buffer = &.{};
            }
        }

        fn ensureCapacity(self: *Self, new_capacity: usize) !void {
            if (self.buffer.len >= new_capacity) return;
            const new_len = @max(self.buffer.len * 2, new_capacity);
            var larger = try self.allocator.alloc(T, new_len);

            var i: usize = 0;
            while (i < self.totalSize) : (i += 1) {
                larger[i] = self.getPtr(i).*;
            }

            if (self.buffer.len > 0) {
                self.allocator.free(self.buffer);
            }
            self.buffer = larger;
            self.head = 0;
        }

        fn getPtr(self: *Self, logical_idx: usize) *T {
            return &self.buffer[(self.head + logical_idx) % self.buffer.len];
        }

        fn removeAt(self: *Self, logical_idx: usize) void {
            if (logical_idx >= self.totalSize) return;

            if (logical_idx == 0) {
                self.head = (self.head + 1) % self.buffer.len;
            } else if (logical_idx != self.totalSize - 1) {
                var i: usize = logical_idx;
                while (i < self.totalSize - 1) : (i += 1) {
                    self.getPtr(i).* = self.getPtr(i + 1).*;
                }
            }
            self.totalSize -= 1;
        }

        pub fn pushFirst(self: *Self, data: T) !void {
            const zone = tracy.initZone(@src(), .{ .name = "queue push first" });
            defer zone.deinit();

            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);

            try self.ensureCapacity(self.totalSize + 1);

            if (self.head == 0) {
                self.head = self.buffer.len - 1;
            } else {
                self.head -= 1;
            }
            self.buffer[self.head] = data;
            self.totalSize += 1;
        }

        pub fn popFirst(self: *Self) ?T {
            const zone = tracy.initZone(@src(), .{ .name = "queue pop first" });
            defer zone.deinit();

            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);

            if (self.totalSize == 0) return null;

            const val = self.buffer[self.head];
            self.head = (self.head + 1) % self.buffer.len;
            self.totalSize -= 1;

            return val;
        }

        pub fn pushLast(self: *Self, data: T) !void {
            const zone = tracy.initZone(@src(), .{ .name = "queue push last" });
            defer zone.deinit();

            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);

            try self.ensureCapacity(self.totalSize + 1);

            const tail = (self.head + self.totalSize) % self.buffer.len;
            self.buffer[tail] = data;
            self.totalSize += 1;
        }

        pub fn popLast(self: *Self) ?T {
            const zone = tracy.initZone(@src(), .{ .name = "queue pop last" });
            defer zone.deinit();

            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);

            if (self.totalSize == 0) return null;

            const tail = (self.head + self.totalSize - 1) % self.buffer.len;
            const val = self.buffer[tail];
            self.totalSize -= 1;

            return val;
        }

        pub fn toOwnedSlice(self: *Self) ![]T {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);

            var res = try self.allocator.alloc(T, self.totalSize);
            var idx: usize = 0;

            while (self.totalSize > 0) {
                res[idx] = self.buffer[self.head];
                self.head = (self.head + 1) % self.buffer.len;
                self.totalSize -= 1;
                idx += 1;
            }

            return res;
        }

        pub fn peekFirst(self: *Self) ?T {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);

            if (self.totalSize == 0) return null;
            return self.buffer[self.head];
        }

        pub fn peekLast(self: *Self) ?T {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);

            if (self.totalSize == 0) return null;
            const tail = (self.head + self.totalSize - 1) % self.buffer.len;
            return self.buffer[tail];
        }

        pub fn remove(self: *Self, data: T) void {
            self.mutex.lockUncancelable(self.io);
            defer self.mutex.unlock(self.io);

            const zone = tracy.initZone(@src(), .{ .name = "queue remove" });
            defer zone.deinit();

            var i: usize = 0;
            while (i < self.totalSize) {
                if (std.meta.eql(self.getPtr(i).*, data)) {
                    self.removeAt(i);
                } else {
                    i += 1;
                }
            }
        }

        pub fn appendSlice(self: *Self, slice: []T) !void {
            for (slice) |value| {
                try self.pushLast(value);
            }
        }
    };
}
