const std = @import("std");
const fifo = std.fifo;

pub fn QueueConstructor(datatype: type) type {
    return struct {
        const Self = @This();

        // gpa: std.mem.Allocator,
        // count: u32 = 0,
        datas: fifo.LinearFifo(datatype, .Dynamic),

        pub fn init(gpa: std.mem.Allocator) !Self {
            return Self{
                .datas = fifo.LinearFifo(datatype, .Dynamic).init(gpa),
                // .gpa = gpa,
            };
        }

        pub fn enqueue(self: *Self, data: datatype) !void {
            try self.datas.writeItem(data);
        }

        pub fn dequeue(self: *Self) ?datatype {
            return self.datas.readItem();
        }

        pub fn deinit(self: *Self) void {
            self.datas.deinit();
        }

        pub fn count(self: *Self) usize {
            return self.datas.count;
        }
    };
}

test "queue" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    var qqq = try QueueConstructor(u32).init(gpa.allocator());
    defer qqq.deinit();

    try qqq.enqueue(128);
    std.log.warn("count: {d}", .{qqq.count()});
    try qqq.enqueue(127);
    std.log.warn("count: {d}", .{qqq.count()});
    const a = qqq.dequeue() orelse 0;
    std.log.warn("a: {d}", .{a});
    std.log.warn("count: {d}", .{qqq.count()});
}
