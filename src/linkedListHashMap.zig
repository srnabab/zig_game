const std = @import("std");
const Allocator = std.mem.Allocator;
const math = std.math;
const assert = std.debug.assert;
const hashmap = std.HashMapUnmanaged;

pub fn LinkedListHashMap(
    comptime K_type: type,
    comptime V_type: type,
    comptime Context: type,
    comptime initCapacity: u64,
) type {
    return struct {
        const Self = @This();
        const max_load: u64 = 3;
        const minimal_capacity = 8;

        allocator: Allocator,
        ctx: Context,

        /// Current number of elements in the hashmap.
        size: Size = 0,
        available: Size = 0,

        header_t: ?*Header = null,

        pointer_stability: std.debug.SafetyLock = .{},

        pub const KVs = std.SinglyLinkedList(KV);
        pub const Node = KVs.Node;
        pub const KVN = struct {
            data: KVs,
        };

        // This hashmap is specially designed for sizes that fit in a u32.
        pub const Size = u32;

        // u64 hashes guarantee us that the fingerprint bits will never be used
        // to compute the index of a slot, maximizing the use of entropy.
        pub const Hash = u64;

        pub const Entry = struct {
            key_ptr: *K_type,
            value_ptr: *V_type,
        };

        pub const KV = struct {
            key: K_type,
            value: V_type,
        };

        const Header = struct {
            key_values: [*]KVN,
            capacity: Size,
        };

        pub const GetOrPutResult = struct {
            key_ptr: *K_type,
            value_ptr: *V_type,
            found_existing: bool,
        };

        pub const Iterator = struct {
            hm: *const Self,
            index: Size = 0,
            postion: Size = 0,

            pub fn next(it: *Iterator) ?Entry {
                assert(it.index <= it.hm.capacity());
                if (it.hm.size == 0) return null;

                // std.log.warn("index {d}, pos {d}", .{ it.index, it.postion });
                // std.log.warn("pos 1", .{});

                if (it.postion != 0) {
                    var step = it.postion;
                    var node = it.hm.header().key_values[it.index].data.first;
                    while (step > 0) : (step -= 1) {
                        node = node.?.next;
                    }
                    if (node) |a| {
                        it.postion += 1;
                        return Entry{ .key_ptr = &a.data.key, .value_ptr = &a.data.value };
                    }
                    it.postion = 0;
                    it.index += 1;
                }

                // std.log.warn("pos 2", .{});
                if (it.postion == 0) {
                    var first = it.hm.header().key_values[it.index].data.first;
                    // std.log.warn("pos 3", .{});
                    for (it.index..it.hm.capacity()) |i| {
                        first = it.hm.header().key_values[i].data.first;

                        if (first == null) {
                            it.index += 1;
                        } else {
                            break;
                        }

                        // std.log.warn("{*}", .{first});
                    }
                    // std.log.warn("pos 4", .{});
                    // std.log.warn("index {d}, pos {d}", .{ it.index, it.postion });
                    if (it.index == it.hm.capacity()) return null;
                    if (first.?.next == null) {
                        it.index += 1;
                    } else {
                        it.postion += 1;
                    }
                    // std.log.warn("pos 5", .{});
                    return Entry{ .key_ptr = &first.?.data.key, .value_ptr = &first.?.data.value };
                }

                return null;
            }
        };
        pub fn iterator(self: *const Self) Iterator {
            return .{ .hm = self };
        }

        pub fn init(allocator: Allocator) Self {
            if (@sizeOf(Context) != 0) {
                @compileError("Context must be specified! Call initContext(allocator, ctx) instead.");
            }

            return .{ .allocator = allocator, .ctx = undefined };
        }

        pub fn initContext(allocator: Allocator, ctx: Context) Self {
            return .{ .allocator = allocator, .ctx = ctx };
        }

        fn allocate(self: *Self, allocator: Allocator, new_capacity: Size) Allocator.Error!void {
            const header_align = @alignOf(Header);
            const key_val_align = @alignOf(KVN);
            const max_align = comptime @max(header_align, key_val_align);

            const new_cap: usize = new_capacity;

            const keys_start = std.mem.alignForward(usize, @sizeOf(Header), key_val_align);
            const keys_end = keys_start + new_cap * @sizeOf(KVN);

            const total_size = std.mem.alignForward(usize, keys_end, max_align);

            // std.log.warn("header align {d}, key val align {d}, key start {d}, total size {d}", .{ header_align, key_val_align, keys_start, total_size });

            const slice = try allocator.alignedAlloc(u8, max_align, total_size);
            const ptr: [*]u8 = @ptrCast(slice.ptr);

            const hdr = @as(*Header, @ptrCast(@alignCast(ptr)));
            hdr.key_values = @ptrCast(@alignCast((ptr + keys_start)));
            for (0..new_cap) |i| {
                hdr.key_values[i].data.first = null;
                // std.log.warn("{*}", .{hdr.key_values[i].data.first});
            }
            hdr.capacity = new_capacity;
            self.header_t = hdr;
        }

        fn deallocateNode(self: *Self, allocator: Allocator) void {
            _ = self;
            _ = allocator;
            @panic("unusable");
            // for (0..self.capacity()) |i| {
            //     var list = &self.header().key_values[i].data;
            //     var ptrr = list.first;
            //     while (ptrr) |ptr| {
            //         const free = ptr;
            //         ptrr = ptr.next;
            //         list.remove(free);
            //         allocator.free(free[0..1]);
            //     }
            // }
        }

        fn deallocateMap(self: *Self, allocator: Allocator) void {
            if (self.header_t == null) return;

            const header_align = @alignOf(Header);
            const key_val_align = @alignOf(KVN);
            const max_align = comptime @max(header_align, key_val_align);

            const cap: usize = self.capacity();

            const keys_start = std.mem.alignForward(usize, @sizeOf(Header), key_val_align);
            const keys_end = keys_start + cap * @sizeOf(KVN);

            const total_size = std.mem.alignForward(usize, keys_end, max_align);

            const slice = @as([*]align(max_align) u8, @ptrCast(@alignCast(self.header())))[0..total_size];
            allocator.free(slice);

            self.header_t = null;
            self.available = 0;
        }

        pub fn deinit(self: *Self) void {
            // self.deallocateNode(self.allocator);
            self.deallocateMap(self.allocator);
            self.* = undefined;
        }

        fn capacityForSize(size: Size) Size {
            const new_cap = math.ceilPowerOfTwo(u32, size) catch unreachable;
            return new_cap;
        }

        fn growIfNeeded(self: *Self, allocator: Allocator, new_count: Size, ctx: Context) Allocator.Error!void {
            if (new_count > self.available) {
                try self.grow(allocator, capacityForSize(self.capacity() + new_count), ctx);
                // std.log.warn("available {d}", .{self.available});
            }
        }
        fn grow(self: *Self, allocator: Allocator, new_capacity: Size, ctx: Context) Allocator.Error!void {
            @branchHint(.cold);
            const new_cap = @max(new_capacity, minimal_capacity, capacityForSize(initCapacity));
            assert(new_cap > self.capacity());
            assert(std.math.isPowerOfTwo(new_cap));

            var map: Self = .{ .allocator = allocator, .ctx = ctx };
            try map.allocate(allocator, new_cap);
            errdefer comptime unreachable;
            map.pointer_stability.lock();

            if (self.size != 0) {
                const old_capacity = self.capacity();
                for (self.keys_values()[0..old_capacity]) |kvn| {
                    const list = kvn.data;
                    var ptrr = list.first;
                    while (ptrr) |next| {
                        self.putAssumeCapacityNoClobberContext(next, ctx);
                        ptrr = next.next;
                    }
                    if (map.size == self.size) break;
                }
            }

            self.size = 0;
            map.available = @truncate(@as(u64, @intCast(new_cap)) * max_load);
            self.pointer_stability = .{};
            std.mem.swap(Self, self, &map);
            map.deallocateMap(allocator);
        }

        pub fn putAssumeCapacityNoClobberContext(self: *Self, node: *Node, ctx: Context) void {
            assert(!self.containsContext(node.data.key, ctx));

            const hash: Hash = ctx.hash(node.data.key);
            const mask = self.capacity() - 1;
            const idx: usize = @truncate(hash & mask);

            self.header().key_values[idx].data.prepend(node);
            self.size += 1;
            self.available -= 1;
        }

        pub fn clearRetainingCapacity(self: *Self) void {
            for (0..self.capacity()) |i| {
                self.header().key_values[i].data.first = null;
            }
            self.size = 0;
            self.available = @truncate(@as(u64, @intCast(self.capacity())) * max_load);
        }

        pub fn count(self: *Self) Size {
            return self.size;
        }

        fn getIndex(self: Self, key: K_type, ctx: anytype) ?usize {
            if (self.size == 0) {
                // We use cold instead of unlikely to force a jump to this case,
                // no matter the weight of the opposing side.
                @branchHint(.cold);
                return null;
            }

            // If you get a compile error on this line, it means that your generic hash
            // function is invalid for these parameters.
            const hash: Hash = ctx.hash(key);

            const mask = self.capacity() - 1;
            const idx = @as(usize, @truncate(hash & mask));

            if (self.header().key_values[idx].data.len() == 0) return null;

            return idx;
        }

        fn header(self: Self) *Header {
            return self.header_t.?;
        }

        fn keys_values(self: Self) [*]KVN {
            return self.header().key_values;
        }

        pub fn capacity(self: Self) Size {
            if (self.header_t == null) return 0;

            return self.header().capacity;
        }

        pub fn put(self: *Self, node: *Node) Allocator.Error!void {
            if (@sizeOf(Context) != 0)
                @compileError("Cannot infer context " ++ @typeName(Context) ++ ", call putContext instead.");
            return self.putContext(self.allocator, node, undefined);
        }
        pub fn putContext(self: *Self, allocator: Allocator, node: *Node, ctx: Context) Allocator.Error!void {
            var res = try self.getOrPutContext(allocator, node, ctx);
            res.found_existing = true;
        }
        pub fn getOrPutContext(self: *Self, allocator: Allocator, node: *Node, ctx: Context) Allocator.Error!GetOrPutResult {
            const gop = try self.getOrPutContextAdapted(allocator, node, ctx, ctx);
            return gop;
        }
        pub fn getOrPutContextAdapted(self: *Self, allocator: Allocator, node: *Node, key_ctx: anytype, ctx: Context) Allocator.Error!GetOrPutResult {
            {
                self.pointer_stability.lock();
                defer self.pointer_stability.unlock();
                self.growIfNeeded(allocator, 1, ctx) catch |err| {
                    // If allocation fails, try to do the lookup anyway.
                    // If we find an existing item, we can return it.
                    // Otherwise return the error, we could not add another.
                    const index = self.getIndex(node.data.key, key_ctx) orelse return err;
                    const list = self.keys_values()[index].data;
                    const node_old = findInList(list, node.data.key, key_ctx).?;
                    return GetOrPutResult{
                        .key_ptr = &node_old.data.key,
                        .value_ptr = &node_old.data.value,
                        .found_existing = true,
                    };
                };
            }
            return self.getOrPutAssumeCapacityAdapted(node, key_ctx);
        }
        pub fn getOrPutAdapted(self: *Self, allocator: Allocator, node: *Node, key_ctx: anytype) Allocator.Error!GetOrPutResult {
            if (@sizeOf(Context) != 0)
                @compileError("Cannot infer context " ++ @typeName(Context) ++ ", call getOrPutContextAdapted instead.");
            return self.getOrPutContextAdapted(allocator, node, key_ctx, undefined);
        }

        pub fn getOrPutAssumeCapacityAdapted(self: *Self, node: *Node, ctx: anytype) GetOrPutResult {

            // If you get a compile error on this line, it means that your generic hash
            // function is invalid for these parameters.
            // std.log.warn("pos 0", .{});
            const hash: Hash = ctx.hash(node.data.key);
            // std.log.warn("pos 1", .{});
            // std.log.warn("hash: {d}", .{hash});

            const mask = self.capacity() - 1;
            const idx = @as(usize, @truncate(hash & mask));
            // std.log.warn("index: {d}", .{idx});

            var list = &self.header().key_values[idx].data;
            var ptrr = list.first;
            // std.log.warn("pos 2", .{});

            while (ptrr) |nodee| {
                if (ctx.eql(node.data.key, nodee.data.key)) {
                    // std.log.warn("compare", .{});
                    return GetOrPutResult{
                        .key_ptr = &nodee.data.key,
                        .value_ptr = &nodee.data.value,
                        .found_existing = true,
                    };
                }
                ptrr = nodee.next;
            }
            // std.log.warn("pos 3", .{});

            const new_key = &node.data.key;
            const new_value = &node.data.value;
            list.prepend(node);
            // std.log.warn("list {*}", .{list.first});
            self.size += 1;
            // std.log.warn("available {d}", .{self.available});
            self.available -= 1;

            return GetOrPutResult{
                .key_ptr = new_key,
                .value_ptr = new_value,
                .found_existing = false,
            };
        }

        fn findInList(list: KVs, key: K_type, key_ctx: anytype) ?*Node {
            var ptrr = list.first;
            while (ptrr) |node| {
                if (key_ctx.eql(node.data.key, key)) {
                    return node;
                }
                ptrr = node.next;
            }
            return null;
        }

        /// Return true if there is a value associated with key in the map.
        pub fn contains(self: Self, key: K_type) bool {
            if (@sizeOf(Context) != 0)
                @compileError("Cannot infer context " ++ @typeName(Context) ++ ", call containsContext instead.");
            return self.containsContext(key, undefined);
        }
        pub fn containsContext(self: Self, key: K_type, ctx: Context) bool {
            return self.containsAdapted(key, ctx);
        }
        pub fn containsAdapted(self: Self, key: anytype, ctx: anytype) bool {
            return self.getIndex(key, ctx) != null;
        }

        /// Get a copy of the value associated with key, if present.
        pub fn get(self: Self, key: K_type) ?V_type {
            if (@sizeOf(Context) != 0)
                @compileError("Cannot infer context " ++ @typeName(Context) ++ ", call getContext instead.");
            return self.getContext(key, undefined);
        }
        pub fn getContext(self: Self, key: K_type, ctx: Context) ?V_type {
            return self.getAdapted(key, ctx);
        }
        pub fn getAdapted(self: Self, key: anytype, ctx: anytype) ?V_type {
            if (self.getIndex(key, ctx)) |idx| {
                const list = self.header().key_values[idx].data;
                if (findInList(list, key, ctx)) |node| {
                    return node.data.value;
                }
            }
            return null;
        }

        pub fn getOrPutValue(self: *Self, allocator: Allocator, node: *Node) Allocator.Error!Entry {
            if (@sizeOf(Context) != 0)
                @compileError("Cannot infer context " ++ @typeName(Context) ++ ", call getOrPutValueContext instead.");
            return self.getOrPutValueContext(allocator, node, undefined);
        }
        pub fn getOrPutValueContext(self: *Self, allocator: Allocator, node: *Node, ctx: Context) Allocator.Error!Entry {
            const res = try self.getOrPutAdapted(allocator, node, ctx);
            return Entry{ .key_ptr = res.key_ptr, .value_ptr = res.value_ptr };
        }

        pub fn rehash() void {
            @compileError("invalid function");
        }
    };
}

pub fn AutoLinkedListHashMap(comptime K_type: type, comptime V_type: type, comptime initCapacity: u64) type {
    return LinkedListHashMap(K_type, V_type, std.hash_map.AutoContext(K_type), initCapacity);
}

const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "basic usage" {
    // std.log.warn("start", .{});
    const mapType = AutoLinkedListHashMap(u32, u32, 8);
    var map = mapType.init(std.testing.allocator);
    defer map.deinit();

    const count = 5;
    var i: u32 = 0;
    var total: u32 = 0;
    var nodes = try std.testing.allocator.alloc(mapType.Node, 5);
    defer std.testing.allocator.free(nodes);
    while (i < count) : (i += 1) {
        // std.log.warn("i: {d}", .{i});
        nodes[i].data.key = i;
        nodes[i].data.value = i;
        try map.put(&nodes[i]);
        total += i;
    }

    var sum: u32 = 0;
    var it = map.iterator();
    while (it.next()) |kv| {
        sum += kv.key_ptr.*;
    }
    try expectEqual(total, sum);

    i = 0;
    sum = 0;
    while (i < count) : (i += 1) {
        try expectEqual(i, map.get(i).?);
        sum += map.get(i).?;
    }
    try expectEqual(total, sum);
}

test "clearRetainingCapacity" {
    const mapType = AutoLinkedListHashMap(u32, u32, 8);
    var map = mapType.init(std.testing.allocator);
    defer map.deinit();

    map.clearRetainingCapacity();

    var node = try std.testing.allocator.create(mapType.Node);
    defer std.testing.allocator.destroy(node);

    node.data.key = 1;
    node.data.value = 1;
    try map.put(node);
    try expectEqual(map.get(1).?, 1);
    try expectEqual(map.count(), 1);

    // map.clearRetainingCapacity();
    // map.putAssumeCapacity(1, 1);
    // try expectEqual(map.get(1).?, 1);
    // try expectEqual(map.count(), 1);

    const cap = map.capacity();
    try expect(cap > 0);

    map.clearRetainingCapacity();
    map.clearRetainingCapacity();
    try expectEqual(map.count(), 0);
    try expectEqual(map.capacity(), cap);
    try expect(!map.contains(1));
}
