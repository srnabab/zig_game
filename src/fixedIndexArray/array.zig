const std = @import("std");

pub fn FixedIndexArray(T: type) type {
    return struct {
        const Self = @This();

        const freeListNode = struct {
            index: usize,
            next: ?*freeListNode,
        };

        const Item = union {
            data: T,
            free: freeListNode,
        };

        const IndexAndPtr = struct {
            index: usize,
            ptr: *T,
        };

        items: std.array_list.Managed(Item),
        freeList: ?*freeListNode,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .items = .init(allocator),
                .freeList = null,
            };
        }

        pub fn deinit(self: *Self) void {
            self.items.deinit();
            self.freeList = null;
        }

        pub fn addOne(self: *Self) !IndexAndPtr {
            if (self.freeList) |node| {
                const index = node.index;

                self.freeList = node.next;

                self.items.items[index] = .{ .data = undefined };

                return IndexAndPtr{
                    .index = index,
                    .ptr = &self.items.items[index].data,
                };
            }

            var ptr = try self.items.addOne();
            ptr.* = .{ .data = undefined };

            return IndexAndPtr{
                .index = self.items.items.len - 1,
                .ptr = &ptr.data,
            };
        }

        pub fn remove(self: *Self, index: usize) void {
            if (index >= self.items.items.len) return;

            const ptr = &self.items.items[index];

            const tempFreeList = self.freeList;
            ptr.* = .{ .free = .{ .index = index, .next = null } };

            self.freeList = &ptr.free;
            ptr.free.next = tempFreeList;
        }

        pub fn get(self: *Self, index: usize) *T {
            return &self.items.items[index].data;
        }
    };
}

test "basic" {
    std.testing.log_level = .debug;

    var array: FixedIndexArray(u32) = .init(std.testing.allocator);
    defer array.deinit();

    const ptr1 = try array.addOne();
    const ptr2 = try array.addOne();
    const ptr3 = try array.addOne();

    std.debug.assert(ptr1.ptr == &array.items.items[0].data);
    std.debug.assert(ptr2.ptr == &array.items.items[1].data);
    std.debug.assert(ptr3.ptr == &array.items.items[2].data);

    ptr1.ptr.* = 1;
    ptr2.ptr.* = 2;
    ptr3.ptr.* = 3;

    std.debug.assert(array.items.items[0].data == 1);
    std.debug.assert(array.items.items[1].data == 2);
    std.debug.assert(array.items.items[2].data == 3);

    array.remove(1);
    array.remove(0);

    std.debug.assert(ptr3.ptr == &array.items.items[2].data);

    const ptr4 = try array.addOne();
    const ptr5 = try array.addOne();

    std.debug.assert(ptr4.ptr == &array.items.items[0].data);
    std.debug.assert(ptr5.ptr == &array.items.items[1].data);
}
