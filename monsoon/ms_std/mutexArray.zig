const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

pub fn MutexArray(T: type) type {
    return struct {
        const Self = @This();

        const Error = std.Io.Cancelable || Allocator.Error;

        mutex: std.Io.Mutex,
        array: std.array_list.Managed(T),

        pub fn init(gpa: std.mem.Allocator) Self {
            return .{
                .mutex = .init,
                .array = .init(gpa),
            };
        }

        pub fn deinit(self: *Self) void {
            self.array.deinit();
        }

        pub fn append(self: *Self, io: Io, item: T) Error!void {
            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            const new_item_ptr = try self.array.addOne();
            new_item_ptr.* = item;
        }
    };
}
