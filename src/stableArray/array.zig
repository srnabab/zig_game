const std = @import("std");

const tracy = @import("tracy");

/// not thread-safe
pub fn StableArray(T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,

        array: std.ArrayList(T),
        // map: std.AutoHashMap(usize, *T),

        borrowList: std.ArrayList(u8),
        totalBorrowed: u32 = 0,

        mutex: std.Thread.Mutex = .{},

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .array = .empty,
                .borrowList = .empty,
            };
        }

        pub fn deinit(self: *Self) void {
            self.array.deinit(self.allocator);
            self.borrowList.deinit(self.allocator);
        }

        pub fn add(self: *Self) !*T {
            const zone = tracy.initZone(@src(), .{ .name = "stable array add" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.array.capacity > self.array.items.len) {
                const index = self.array.items.len;

                const ptr = self.array.addOneAssumeCapacity();
                self.borrowList.items[index] = 1;
                self.totalBorrowed += 1;

                return ptr;
                // try self.map.put(index, ptr);
            } else {
                if (self.totalBorrowed == 0) {
                    const index = self.array.items.len;

                    const ptr = try self.array.addOne(self.allocator);
                    try self.borrowList.ensureTotalCapacityPrecise(self.allocator, self.array.capacity);
                    self.borrowList.expandToCapacity();

                    self.borrowList.items[index] = 1;
                    self.totalBorrowed += 1;

                    return ptr;
                    // try self.map.put(index, ptr);
                } else {
                    return error.HaveBorrowed;
                }
            }
        }

        pub fn get(self: *Self, index: usize) ?*T {
            const zone = tracy.initZone(@src(), .{ .name = "stable array get" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            if (index >= self.array.items.len) return null;

            const ptr = &self.array.items[index];

            self.borrowList.items[index] += 1;
            self.totalBorrowed += 1;

            return ptr;
        }

        pub fn giveBack(self: *Self, ptr: *T) void {
            const index = self.getIndex(ptr);

            self.giveBackByIndex(index);
        }

        pub fn giveBackByIndex(self: *Self, index: usize) void {
            const zone = tracy.initZone(@src(), .{ .name = "stable array give back" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            if (index >= self.array.items.len) return;

            self.borrowList.items[index] -= 1;
            self.totalBorrowed -= 1;
        }

        pub fn removeByIndex(self: *Self, index: usize) !void {
            const zone = tracy.initZone(@src(), .{ .name = "stable array remove" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            if (index >= self.array.items.len) return;

            if (self.totalBorrowed == 0) {
                _ = self.array.orderedRemove(index);
                return;
            } else {
                return error.HaveBorrowed;
            }
        }

        pub fn removeByPtr(self: *Self, ptr: *T) !void {
            const zone = tracy.initZone(@src(), .{ .name = "stable array remove" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.totalBorrowed == 0) {
                const firstPtr: *T = &self.array.items[0];

                const index = ptr - firstPtr;
                _ = self.array.orderedRemove(index);
            } else {
                return error.HaveBorrowed;
            }
        }

        pub fn getIndex(self: *Self, ptr: *T) usize {
            const zone = tracy.initZone(@src(), .{ .name = "stable array get index" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            const firstPtr: *T = &self.array.items[0];
            return ptr - firstPtr;
        }
    };
}

test "basic" {
    std.testing.log_level = .info;
    const a = std.testing.allocator;

    var array: StableArray(u32) = .init(a);
    defer array.deinit();

    const addPtr1 = try array.add();
    const addPtr2 = try array.add();
    const addPtr3 = try array.add();

    addPtr1.* = 1;
    addPtr2.* = 2;
    addPtr3.* = 3;

    try std.testing.expectEqual(3, array.array.items.len);

    const ptr1 = array.get(0);
    const ptr2 = array.get(1);
    const ptr3 = array.get(2);

    try std.testing.expectEqual(1, ptr1.?.*);
    try std.testing.expectEqual(2, ptr2.?.*);
    try std.testing.expectEqual(3, ptr3.?.*);

    try std.testing.expectEqual(error.HaveBorrowed, array.removeByPtr(ptr1.?));

    array.giveBack(ptr1.?);
    array.giveBack(ptr2.?);
    array.giveBack(ptr3.?);
    array.giveBack(ptr1.?);
    array.giveBack(ptr2.?);
    array.giveBack(ptr3.?);

    try std.testing.expectEqual(0, array.totalBorrowed);

    try array.removeByIndex(0);
    try array.removeByIndex(0);
    try array.removeByIndex(0);

    try std.testing.expectEqual(0, array.array.items.len);
}

test "addExpandCapacity" {
    std.testing.log_level = .info;

    const a = std.testing.allocator;

    var array: StableArray(u64) = .init(a);
    defer array.deinit();

    for (0..16) |i| {
        const temp = try array.add();
        temp.* = i;
    }

    try std.testing.expectEqual(16, array.array.items.len);

    const ptr1 = array.get(14);

    try std.testing.expectError(error.HaveBorrowed, array.add());

    array.giveBack(ptr1.?);
    for (0..16) |i| {
        array.giveBackByIndex(i);
    }

    const ptr = try array.add();
    ptr.* = 16;

    try std.testing.expectEqual(17, array.array.items.len);
}
