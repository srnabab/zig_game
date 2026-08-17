const std = @import("std");
const tracy = @import("tracy");

pub fn MemoryPoolSlice(comptime Item: type) type {
    return struct {
        const Pool = @This();

        const Node = struct {
            ptr: [*]Item,
            size: usize,
            next: ?*@This(),
        };

        arena: std.heap.ArenaAllocator,
        free_lists: [8]?*Node = [_]?*Node{null} ** 8,

        pub fn init(allocator: std.mem.Allocator) Pool {
            return .{ .arena = std.heap.ArenaAllocator.init(allocator) };
        }

        pub fn deinit(pool: *Pool) void {
            pool.arena.deinit();
            pool.* = undefined;
        }

        pub const ResetMode = std.heap.ArenaAllocator.ResetMode;

        pub fn reset(pool: *Pool, mode: ResetMode) bool {
            // TODO: Potentially store all allocated objects in a list as well, allowing to
            //       just move them into the free list instead of actually releasing the memory.

            const reset_successful = pool.arena.reset(mode);

            pool.free_list = null;

            return reset_successful;
        }

        pub fn create(pool: *Pool, size: u32) ![]Item {
            const zone = tracy.initZone(@src(), .{ .name = "create slice" });
            defer zone.deinit();

            std.debug.assert(size != 0);

            const pow_of_two: usize = 31 - @clz(size);

            if (pool.free_lists[pow_of_two]) |item| {
                pool.free_lists[pow_of_two] = item.next;
                const res = item.ptr[0..size];

                if (item.size > size) {
                    item.size = item.size - size;
                    item.ptr = item.ptr + size;
                    const idx: usize = 31 - @clz(item.size);

                    item.next = pool.free_lists[idx];
                    pool.free_lists[idx] = item;
                } else {
                    pool.arena.allocator().destroy(item);
                }

                return res;
            } else {
                return pool.arena.allocator().alloc(Item, size);
            }
        }

        pub fn destroy(pool: *Pool, slice: []Item) !void {
            const pow_of_two: usize = 31 - @clz(slice.len);
            const node = try pool.arena.allocator().create(Node);

            node.* = .{
                .ptr = slice.ptr,
                .size = slice.len,
                .next = pool.free_lists[pow_of_two],
            };
            pool.free_lists[pow_of_two] = node;
        }
    };
}
