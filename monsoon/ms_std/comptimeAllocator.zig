const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn ComptimeAllocator(comptime size: usize) type {
    return struct {
        buffer: [size]u8 = undefined,
        index: usize = 0,

        const Self = @This();

        pub fn init() Self {
            return .{};
        }

        pub fn allocator(self: *Self) Allocator {
            return .{
                .ptr = self,
                .vtable = &.{
                    .alloc = alloc,
                    .resize = Allocator.noResize,
                    .free = Allocator.noFree,
                    .remap = Allocator.noRemap,
                },
            };
        }

        fn alloc(ctx: *anyopaque, len: usize, ptr_align: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
            _ = ret_addr;
            const self: *Self = @ptrCast(@alignCast(ctx));
            const alignment = ptr_align.toByteUnits();

            const aligned_idx = std.mem.alignForward(usize, self.index, alignment);
            // if (aligned_idx + len > size) return null;
            self.index = aligned_idx + len;
            return self.buffer[aligned_idx..][0..len].ptr;
        }
    };
}
