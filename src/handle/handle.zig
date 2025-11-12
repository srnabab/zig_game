const std = @import("std");

const Option = enum {
    Reuse,
    Once,
};

pub const Handle = *anyopaque;

pub fn Handles(comptime capacity: u32, comptime option: Option) type {
    return struct {
        const Self = @This();

        array: []u32,
        index: std.atomic.Value(u32),

        loop: if (option == .Reuse) bool else void,
        lastEndIndex: if (option == .Reuse) u32 else void,

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                .array = try allocator.alloc(u32, capacity),
                .index = .init(0),
                .loop = if (option == .Reuse) false else void{},
                .lastEndIndex = if (option == .Reuse) 0 else void{},
            };
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            allocator.free(self.array);
        }

        pub fn createHandle(self: *Self, index: u32) Handle {
            if (option == .Reuse) {
                if (self.loop) {
                    for (self.array[self.lastEndIndex..], self.lastEndIndex..) |value, i| {
                        if (value == std.math.maxInt(u32)) {
                            self.lastEndIndex = @intCast(i);

                            self.array[i] = index;

                            return @ptrCast(@alignCast(&self.array[i]));
                        }
                    }

                    std.process.abort();
                } else {
                    const current = self.index.fetchAdd(1, .seq_cst);

                    if (current == capacity - 1) {
                        self.loop = true;
                    }

                    self.array[current] = index;
                    return @ptrCast(@alignCast(&self.array[current]));
                }
            } else if (option == .Once) {
                const current = self.index.fetchAdd(1, .seq_cst);

                std.debug.assert(current < capacity);

                self.array[current] = index;
                return @ptrCast(@alignCast(&self.array[current]));
            }
        }

        pub fn destroyHandle(self: *Self, handle: Handle) void {
            if (option == .Reuse) {
                _ = self;

                const ptr: *u32 = @ptrCast(@alignCast(handle));

                ptr.* = std.math.maxInt(u32);
            } else if (option == .Once) {
                _ = self;

                const ptr: *u32 = @ptrCast(@alignCast(handle));

                ptr.* = std.math.maxInt(u32);
            }
        }
    };
}
