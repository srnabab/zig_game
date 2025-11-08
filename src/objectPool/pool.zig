const std = @import("std");

const assert = std.debug.assert;

const tracy = @import("tracy");
const mem = struct {
    offset: u32,
    count: u32,
};

pub fn ObjectPool(T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,

        items: []T,
        memList: []mem,
        memListIndex: u32 = 0,
        allocCount: u32 = 0,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .items = &.{},
                .memList = &.{},
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.items);
            self.allocator.free(self.memList);
        }

        pub fn alloc(self: *Self, size: usize) !mem {
            const zone = tracy.initZone(@src(), .{ .name = "object pool alloc" });
            defer zone.deinit();

            if (self.items.len == 0) {
                self.items = try self.allocator.alloc(T, newLenCalculate(0, size));
                self.memList = try self.allocator.alloc(mem, newLenCalculate(0, 1));

                self.memList[0] = .{
                    .offset = @intCast(size),
                    .count = @intCast(self.items.len - size),
                };
                self.memListIndex += 1;

                self.allocCount += 1;

                return .{
                    .offset = 0,
                    .count = @intCast(size),
                };
            } else {
                var lastMemIndex: usize = 0;
                var biggestOffset: u32 = 0;
                for (self.memList[0..self.memListIndex], 0..) |*m, i| {
                    if (m.count >= size) {
                        const oldOffset = m.offset;

                        m.offset += @intCast(size);
                        m.count -= @intCast(size);

                        self.allocCount += 1;
                        if (self.memList.len < self.allocCount) {
                            self.memList = try self.allocator.realloc(self.memList, newLenCalculate(self.memList.len, self.allocCount));
                        }

                        return .{
                            .offset = oldOffset,
                            .count = @intCast(size),
                        };
                    }

                    if (m.offset > biggestOffset) {
                        biggestOffset = m.offset;
                        lastMemIndex = i;
                    }
                }

                const oldLen = self.items.len;
                self.items = try self.allocator.realloc(self.items, newLenCalculate(self.items.len, size));

                if (self.memList[lastMemIndex].count + self.memList[lastMemIndex].offset == oldLen) {
                    const oldOffset = self.memList[lastMemIndex].offset;

                    self.memList[lastMemIndex].offset += @intCast(size);
                    self.memList[lastMemIndex].count += @intCast(self.items.len - oldLen - size);

                    self.allocCount += 1;
                    if (self.memList.len < self.allocCount) {
                        self.memList = try self.allocator.realloc(self.memList, newLenCalculate(self.memList.len, self.allocCount));
                    }

                    return .{
                        .offset = oldOffset,
                        .count = @intCast(size),
                    };
                } else {
                    self.allocCount += 1;
                    if (self.memList.len < self.allocCount) {
                        self.memList = try self.allocator.realloc(self.memList, newLenCalculate(self.memList.len, self.allocCount));
                    }

                    self.memList[self.memListIndex - 1] = .{
                        .offset = @intCast(oldLen + size),
                        .count = @intCast(self.items.len - size),
                    };
                    self.memListIndex += 1;

                    return .{
                        .offset = @intCast(oldLen),
                        .count = @intCast(size),
                    };
                }
            }
        }

        pub fn realloc(self: *Self, old: mem, newSize: usize) !mem {
            const zone = tracy.initZone(@src(), .{ .name = "object pool realloc" });
            defer zone.deinit();

            if (old.count == newSize) {
                return old;
            }

            if (old.count > newSize) {
                const freeSize = old.count - newSize;
                self.free(.{ .offset = @intCast(old.offset + newSize), .count = @intCast(freeSize) });

                return .{
                    .offset = old.offset,
                    .count = @intCast(newSize),
                };
            } else {
                const start = old.offset;
                const end = start + old.count;

                const exapndSize = newSize - old.count;

                var canSplit = true;
                var firstBigMem: i64 = -1;
                for (self.memList[0..self.memListIndex], 0..) |*m, i| {
                    if (canSplit) {
                        if (m.offset == end) {
                            if (m.count > exapndSize) {
                                m.offset += @intCast(exapndSize);
                                m.count -= @intCast(exapndSize);

                                return .{
                                    .offset = start,
                                    .count = @intCast(newSize),
                                };
                            } else if (m.count == exapndSize) {
                                m.* = self.memList[self.memListIndex - 1];
                                self.memListIndex -= 1;

                                if (self.memListIndex == 0) {
                                    self.memList[0] = .{ .offset = 0, .count = 0 };
                                    self.memListIndex += 1;
                                }

                                return .{
                                    .offset = start,
                                    .count = @intCast(newSize),
                                };
                            }

                            canSplit = false;
                        }
                        if (m.count >= newSize and firstBigMem < 0) {
                            firstBigMem = @intCast(i);
                        }
                    } else {
                        if (m.count >= newSize and firstBigMem < 0) {
                            firstBigMem = @intCast(i);
                        }

                        if (firstBigMem >= 0) {
                            const newOffset = self.memList[@intCast(firstBigMem)].offset;
                            @memcpy(self.items[newOffset..][0..old.count], self.items[old.offset..][0..old.count]);

                            if (self.memList[@intCast(firstBigMem)].count > newSize) {
                                //
                                self.memList[@intCast(firstBigMem)].offset += @intCast(newSize);
                                self.memList[@intCast(firstBigMem)].count -= @intCast(newSize);
                                //
                            } else if (self.memList[@intCast(firstBigMem)].count == newSize) {
                                //
                                self.memList[@intCast(firstBigMem)] = self.memList[self.memListIndex - 1];
                                self.memListIndex -= 1;

                                if (self.memListIndex == 0) {
                                    self.memList[0] = .{ .offset = 0, .count = 0 };
                                    self.memListIndex += 1;
                                }
                                //
                            }

                            return .{
                                .offset = newOffset,
                                .count = @intCast(newSize),
                            };
                        }
                    }
                }

                const newMem = try self.alloc(newSize);
                @memcpy(self.items[newMem.offset..][0..old.count], self.items[old.offset..][0..old.count]);

                self.free(old);

                return newMem;
            }
        }

        pub fn free(self: *Self, items: mem) void {
            const zone = tracy.initZone(@src(), .{ .name = "object pool free" });
            defer zone.deinit();

            const start = items.offset;
            const end = start + items.count;

            var front: i64 = -1;
            var back: i64 = -1;

            for (self.memList[0..self.memListIndex], 0..) |*m, i| {
                if (end > m.offset and start < m.offset + m.count) {
                    std.debug.panic("mem intersect with free memory\n passed: {}\n mem: {}", .{ items, m.* });
                    return;
                }

                if (m.offset + m.count == start and front < 0) {
                    front = @intCast(i);
                    continue;
                }

                if (m.offset == end and back < 0) {
                    back = @intCast(i);
                    continue;
                }

                if (front >= 0 and back >= 0) {
                    break;
                }
            }

            if (front >= 0 or back >= 0) {
                if (front >= 0 and back < 0) {
                    self.memList[@intCast(front)].count += items.count;
                } else if (front < 0 and back >= 0) {
                    self.memList[@intCast(back)].offset = start;
                    self.memList[@intCast(back)].count += items.count;
                } else {
                    self.memList[@intCast(front)].count += self.memList[@intCast(back)].count + items.count;

                    self.memList[@intCast(back)] = self.memList[self.memListIndex - 1];
                    self.memListIndex -= 1;

                    if (self.memListIndex == 0) {
                        self.memList[0] = .{ .offset = 0, .count = 0 };
                        self.memListIndex += 1;
                    }
                }

                self.allocCount -= 1;

                return;
            }

            assert(self.memListIndex < self.memList.len);

            self.memList[self.memListIndex] = .{
                .offset = start,
                .count = items.count,
            };
            self.memListIndex += 1;
            self.allocCount -= 1;
        }

        const init_capacity = @as(comptime_int, @max(1, std.atomic.cache_line / @sizeOf(T)));

        fn newLenCalculate(oldLen: usize, newLen: usize) usize {
            var new = oldLen;
            while (true) {
                new +|= new / 2 + init_capacity;
                if (new >= newLen)
                    return new;
            }
        }

        pub fn get(self: *Self, range: mem) []T {
            return self.items[range.offset..][0..range.count];
        }
    };
}

test "alloc and free" {
    std.testing.log_level = .info;
    const a = std.testing.allocator;

    var pool: ObjectPool(u32) = .init(a);
    defer pool.deinit();

    try std.testing.expectEqual(mem{ .offset = 0, .count = 1 }, pool.alloc(1));

    // std.log.info("capacity {d}", .{pool.items.len});
    const currentCapacity = pool.items.len;

    try std.testing.expectEqual(mem{ .offset = 1, .count = 1 }, pool.alloc(1));

    try std.testing.expectEqual(mem{ .offset = 2, .count = @intCast(currentCapacity - 2) }, pool.memList[0]);

    pool.free(.{ .offset = 0, .count = 1 });

    try std.testing.expectEqual(mem{ .offset = 0, .count = 1 }, pool.memList[1]);

    pool.free(.{ .offset = 1, .count = 1 });

    std.testing.expectEqual(mem{ .offset = 0, .count = @intCast(currentCapacity) }, pool.memList[0]) catch |err| {
        std.log.err("{}", .{err});
        std.log.info("{}", .{pool.memList[0]});
        std.log.info("{}", .{pool.memList[1]});
    };
    try std.testing.expectEqual(1, pool.memListIndex);
}

test "realloc" {
    std.testing.log_level = .info;
    const a = std.testing.allocator;

    var pool: ObjectPool(u32) = .init(a);
    defer pool.deinit();

    var mem1 = try pool.alloc(10);
    for (pool.items[mem1.offset..][0..mem1.count], 0..) |*v, i| {
        v.* = @intCast(i);
    }

    try std.testing.expectEqual(mem{ .offset = 0, .count = 10 }, mem1);

    var mem2 = try pool.realloc(mem1, 20);

    try std.testing.expectEqual(mem{ .offset = 0, .count = 20 }, mem2);
    try std.testing.expectEqual(mem{ .offset = 20, .count = 12 }, pool.memList[0]);

    for (pool.items[mem2.offset..][0..10], 0..) |v, i| {
        try std.testing.expect(v == i);
    }

    pool.free(mem2);

    mem1 = try pool.alloc(10);

    mem2 = try pool.realloc(mem1, 32);

    try std.testing.expectEqual(mem{ .offset = 0, .count = 32 }, mem2);
    std.testing.expectEqual(mem{ .offset = 0, .count = 0 }, pool.memList[0]) catch |err| {
        std.log.err("{}", .{err});
        std.log.info("{}", .{pool.memList[0]});
        std.log.info("{d}", .{pool.memListIndex});
    };

    pool.free(mem2);

    mem1 = try pool.alloc(10);
    for (pool.items[mem1.offset..][0..mem1.count], 0..) |*v, i| {
        v.* = @intCast(i);
    }

    mem2 = try pool.alloc(22);

    const mem3 = try pool.realloc(mem1, 11);
    try std.testing.expectEqual(mem{ .offset = 32, .count = 11 }, mem3);

    for (pool.items[mem3.offset..][0..10], 0..) |v, i| {
        try std.testing.expect(v == i);
    }
}
