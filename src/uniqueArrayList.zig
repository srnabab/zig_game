const std = @import("std");
const tracy = @import("tracy");

/// it just use for-loop to remove duplicate
pub fn UniqueArrayList(comptime T: type) type {
    const typeType = comptime @typeInfo(T);
    std.debug.assert(typeType == .int or (typeType == .pointer and @typeInfo(typeType.pointer.child) == .int));

    return struct {
        const Self = @This();

        list: std.array_list.Managed(T),
        bitMap: []bool = &.{},

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .list = .init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.list.deinit();
        }

        pub fn append(self: *Self, item: T) !bool {
            const zone = tracy.initZone(@src(), .{ .name = "unique array list append" });
            defer zone.deinit();

            const index = switch (typeType) {
                .int => item,
                .pointer => item.*,
                else => unreachable,
            };

            if (index >= self.bitMap.len) {
                self.bitMap = try self.list.allocator.realloc(self.bitMap, @max(128, self.bitMap.len * 2));
            }

            if (self.bitMap[index]) return true;

            try self.list.append(item);
            self.bitMap[index] = true;

            return false;
        }

        pub fn have(self: *Self, item: T) bool {
            const index = comptime switch (typeType) {
                .int => item,
                .pointer => item.*,
                else => unreachable,
            };

            if (index >= self.bitMap.len) return false;

            return self.bitMap[index];
        }

        pub fn appendSlice(self: *Self, items: []const T) !usize {
            const zone = tracy.initZone(@src(), .{ .name = "unique array list append slice" });
            defer zone.deinit();

            var count: usize = 0;
            var pos: usize = 0;
            for (items, 0..) |value, i| {
                const index = comptime switch (typeType) {
                    .int => value,
                    .pointer => value.*,
                    else => unreachable,
                };

                if (index >= self.bitMap.len) {
                    self.bitMap = try self.list.allocator.realloc(self.bitMap, @max(128, self.bitMap.len * 2));
                }

                if (self.bitMap[index]) {
                    if (pos == i) {
                        pos += 1;
                        continue;
                    }
                    try self.list.appendSlice(items[pos..i]);
                    count += i - pos;
                    for (items[pos..i]) |a| {
                        const indexA = comptime switch (typeType) {
                            .int => a,
                            .pointer => a.*,
                            else => unreachable,
                        };
                        self.bitMap[indexA] = true;
                    }
                    pos = i + 1;
                }
            }
            if (pos == items.len) {
                return 0;
            }

            try self.list.appendSlice(items[pos..items.len]);
            count += items.len - pos;
            for (items[pos..items.len]) |a| {
                const indexA = comptime switch (typeType) {
                    .int => a,
                    .pointer => a.*,
                    else => unreachable,
                };
                self.bitMap[indexA] = true;
            }

            return count;
        }
    };
}
