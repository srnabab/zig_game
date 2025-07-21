const std = @import("std");
const Allocator = std.mem.Allocator;
const Mutex = std.Thread.Mutex;
pub const Entity = @import("entity.zig").Entity;

const CompentError = error{
    NotFound,
    OutOfCapacity,
};

pub fn compentPool(comptime dataSet: type) type {
    return struct {
        const Self = @This();

        sparse_array: std.ArrayList(usize),
        dense_array: std.ArrayList(dataSet),
        dense_entity_array: std.ArrayList(Entity),
        mutex: Mutex = .{},

        pub fn init(allocator: Allocator) Self {
            var sparse_array = std.ArrayList(usize).initCapacity(allocator, 4) catch |err| {
                std.log.err("err {s}\n", .{@errorName(err)});
                unreachable;
            };
            const dense_array = std.ArrayList(dataSet).init(allocator);
            const dense_entity_array = std.ArrayList(Entity).init(allocator);

            sparse_array.expandToCapacity();

            for (0..sparse_array.items.len) |i| {
                sparse_array.items[i] = std.math.maxInt(u32) + 1;
            }

            return Self{
                .sparse_array = sparse_array,
                .dense_array = dense_array,
                .dense_entity_array = dense_entity_array,
            };
        }

        pub fn register(self: *Self, ent: Entity, data: dataSet) !void {
            self.mutex.lock();
            // std.debug.print("lock\n", .{});
            defer self.mutex.unlock();
            // defer std.debug.print("unlock\n", .{});

            const id_usize: usize = @intCast(ent.id);

            // std.debug.print("ent id: {d}, usize: {d}\n", .{ ent.id, id_usize });
            const initCapacity = self.sparse_array.capacity;
            // std.debug.print("init capacity: {d}\n", .{initCapacity});

            if (self.sparse_array.capacity <= id_usize) {
                try self.sparse_array.ensureTotalCapacity(id_usize + 1);
                self.sparse_array.expandToCapacity();
                for (initCapacity..self.sparse_array.capacity) |i| {
                    self.sparse_array.items[i] = std.math.maxInt(u32) + 1;
                }
            }

            // std.debug.print("space: {d}\n", .{self.sparse_array.items[id_usize]});
            if (self.sparse_array.items[id_usize] < std.math.maxInt(u32)) return;
            std.debug.assert(self.sparse_array.items[id_usize] > std.math.maxInt(u32));

            const len = self.dense_array.items.len;
            try self.dense_array.append(data);
            try self.dense_entity_array.append(ent);
            self.sparse_array.items[id_usize] = len;
        }

        pub fn getData(self: *Self, ent: Entity) !dataSet {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.sparse_array.capacity < ent.id) {
                return CompentError.OutOfCapacity;
            }

            const index = self.sparse_array.items[@intCast(ent.id)];
            return self.dense_array.items[index];
        }

        pub fn deinit(self: *Self) void {
            self.sparse_array.deinit();
            self.dense_array.deinit();
            self.dense_entity_array.deinit();
        }
    };
}
