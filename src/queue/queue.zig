const std = @import("std");
const DoublyLinkedList = std.DoublyLinkedList;
const Allocator = std.mem.Allocator;
const Mutex = std.Thread.Mutex;
const MemoryPoolExtra = std.heap.MemoryPoolExtra;

const tracy = @import("tracy");

pub fn Queue(T: type) type {
    return struct {
        const Self = @This();

        pub const DataNode = struct {
            data: T,
            node: DoublyLinkedList.Node = .{},
        };

        const Iterator = struct {
            const it = @This();
            p: Self,
            current: ?*DoublyLinkedList.Node,

            pub fn next(self: *it) bool {
                if (self.current == null) {
                    self.current = self.p.list.first;
                    return if (self.current != null) true else false;
                } else {
                    self.current = self.current.?.next;
                    return true;
                }
            }

            pub fn getCurrentAndNext(self: *it) ?T {
                if (self.current != null) {
                    const parent: *DataNode = @fieldParentPtr("node", self.current.?);
                    const current = self.current;
                    self.current = self.current.?.next;

                    self.p.list.remove(current);
                    self.p.nodeMemory.destroy(parent);
                    self.p.totalSize -= 1;

                    return parent.data;
                } else {
                    return null;
                }
            }

            pub fn prev(self: *it) bool {
                if (self.current == null) {
                    self.current = self.p.list.last;
                    return if (self.current != null) true else false;
                } else {
                    self.current = self.current.?.prev;
                    return true;
                }
            }

            pub fn getCurrentAndPrev(self: *it) ?T {
                if (self.current != null) {
                    const parent: *DataNode = @fieldParentPtr("node", self.current.?);
                    const current = self.current;
                    self.current = self.current.?.prev;

                    self.p.list.remove(current);
                    self.p.nodeMemory.destroy(parent);
                    self.p.totalSize -= 1;

                    return parent.data;
                } else {
                    return null;
                }
            }

            pub fn peekCurrent(self: *it) ?T {
                if (self.current) |cc| {
                    const parent: *DataNode = @fieldParentPtr("node", cc);
                    return parent.data;
                } else {
                    return null;
                }
            }
        };

        threadSafeAllocator: std.heap.ThreadSafeAllocator = undefined,
        nodeMemory: MemoryPoolExtra(DataNode, .{}) = undefined,
        list: DoublyLinkedList = .{},
        totalSize: usize = 0,
        mutex: Mutex = .{},

        pub fn init(self: *Self, allocator: Allocator) void {
            self.threadSafeAllocator = std.heap.ThreadSafeAllocator{ .child_allocator = allocator };
            self.nodeMemory = .init(self.threadSafeAllocator.allocator());
            self.list = .{};
            self.totalSize = 0;
            self.mutex = .{};
        }

        pub fn deinit(self: *Self) void {
            self.mutex.lock();
            defer self.mutex.unlock();

            self.nodeMemory.deinit();
        }

        pub fn pushFirst(self: *Self, data: T) !void {
            const zone = tracy.initZone(@src(), .{ .name = "queue push first" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            const nnode = try self.nodeMemory.create();
            nnode.* = DataNode{
                .data = data,
            };
            self.list.prepend(&nnode.node);
            self.totalSize += 1;
        }

        pub fn popFirst(self: *Self) ?T {
            const zone = tracy.initZone(@src(), .{ .name = "queue pop first" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.list.first == null) return null;

            const node = self.list.popFirst();
            const parent: *DataNode = @fieldParentPtr("node", node.?);

            defer self.nodeMemory.destroy(parent);
            self.totalSize -= 1;

            return parent.data;
        }

        pub fn pushLast(self: *Self, data: T) !void {
            const zone = tracy.initZone(@src(), .{ .name = "queue push last" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            const nnode = try self.nodeMemory.create();
            nnode.* = DataNode{
                .data = data,
            };
            self.list.append(&nnode.node);
            self.totalSize += 1;
        }

        pub fn popLast(self: *Self) ?T {
            const zone = tracy.initZone(@src(), .{ .name = "queue pop last" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.list.last == null) return null;

            const node = self.list.pop();
            const parent: *DataNode = @fieldParentPtr("node", node.?);

            defer self.nodeMemory.destroy(parent);
            self.totalSize -= 1;

            return parent.data;
        }

        pub fn toOwnedSlice(self: *Self) ![]T {
            var res = try self.threadSafeAllocator.allocator().alloc(T, self.totalSize);
            var idx: usize = 0;

            while (self.list.popFirst()) |node| {
                const parent: *DataNode = @fieldParentPtr("node", node);
                res[idx] = parent.data;
                idx += 1;
            }

            return res;
        }

        pub fn peekFirst(self: *Self) ?T {
            if (self.list.first == null) {
                return null;
            } else {
                const node: *DataNode = @fieldParentPtr("node", self.list.first.?);
                return node.data;
            }
        }

        pub fn peekLast(self: *Self) ?T {
            if (self.list.last == null) {
                return null;
            } else {
                const node: *DataNode = @fieldParentPtr("node", self.list.last.?);
                return node.data;
            }
        }

        pub fn iterate(self: *Self) Iterator {
            return .{ .current = null, .p = self };
        }

        pub fn remove(self: *Self, data: T) void {
            const zone = tracy.initZone(@src(), .{ .name = "queue remove" });
            defer zone.deinit();

            var first = self.list.first;
            while (first) |node| {
                const parent: *DataNode = @fieldParentPtr("node", node);
                if (std.meta.eql(&[_]T{parent.data}, &[_]T{data})) {
                    self.list.remove(node);
                }

                // if (node == node.next) break;

                first = node.next;
            }
        }

        pub fn find(self: *Self, data: T) ?*T {
            var first = self.list.first;
            while (first) |node| {
                const parent: *DataNode = @fieldParentPtr("node", node);
                if (std.meta.eql(&[_]T{parent.data}, &[_]T{data})) {
                    return &parent.data;
                }
                // if (node == node.next) break;

                first = node.next;
            }

            return null;
        }
    };
}
