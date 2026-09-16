const std = @import("std");
const atomic = std.atomic;

const assert = std.debug.assert;

const Option = enum {
    Reuse,
    Once,
};

const Context = opaque {};
pub const Handle = *Context;

const max_u32 = std.math.maxInt(u32);

pub const Invalid = max_u32;
pub const WaitFill = max_u32 - 1;

const Limit = max_u32 - 2;

const InvalidVersion = std.math.maxInt(u16);

pub const ResourceType = enum(u8) {
    texture,
    buffer,
    mesh,
    instance,
    pipeline,
    viewport,
    scissor,
    others,
};

const Content = struct {
    resourceType: ResourceType,
    padding: u8 = 0,
    version: u16,
    index: u32,
};

const Node = packed struct(u64) {
    tag: u32 = max_u32,
    index: u32 = max_u32,
};

const H = union {
    content: Content,
    next: Node,
};

const LockFreeSingleList = struct {};

pub fn getIndex(handle: Handle) ?u32 {
    const ptr: *H = @ptrCast(@alignCast(handle));

    if (ptr.content.index == Invalid) return null;

    return ptr.content.index;
}

pub fn typeCompare(handle: Handle, exceptedType: ResourceType) bool {
    const ptr: *H = @ptrCast(@alignCast(handle));

    return ptr.content.resourceType == exceptedType;
}

pub fn handleIsValid(handle: Handle) bool {
    const ptr: *H = @ptrCast(@alignCast(handle));

    return ptr.content.index != Invalid;
}

pub fn Handles(comptime capacity: u32, comptime option: Option) type {
    _ = option;
    return struct {
        const Self = @This();

        const Max = @min(capacity, Limit);

        array: []H,
        lastEndIndex: std.atomic.Value(u32) = .init(0),

        next: atomic.Value(Node) = .{ .raw = .{} },

        cap: atomic.Value(u32) = .init(capacity),

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                .array = try allocator.alloc(H, capacity),
            };
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            allocator.free(self.array);
        }

        pub fn createHandle(self: *Self, index: u32, resourceType: ResourceType) Handle {
            var cur = self.lastEndIndex.load(.seq_cst);

            var quick = true;

            while (true) {
                if (cur >= Max) {
                    quick = false;
                    break;
                }

                if (self.lastEndIndex.cmpxchgWeak(cur, cur + 1, .seq_cst, .seq_cst)) |v| {
                    cur = v;
                } else {
                    break;
                }
            }

            if (!quick) {
                var old_head = self.next.load(.seq_cst);

                while (true) {
                    const cur_idx = old_head.index;

                    if (cur_idx == max_u32) {
                        std.log.err("no more free handle", .{});
                        std.process.abort();
                    }

                    const next_idx = self.array[cur_idx].next.index;
                    const new_tag = old_head.tag +% 1;

                    const new_head = Node{
                        .index = next_idx,
                        .tag = new_tag,
                    };

                    if (self.next.cmpxchgWeak(old_head, new_head, .seq_cst, .seq_cst)) |h| {
                        old_head = h;
                    } else {
                        cur = cur_idx;
                        break;
                    }
                }
                // std.log.debug("reuse: cap {d}", .{self.cap.load(.seq_cst)});
            }

            _ = self.cap.fetchSub(1, .seq_cst);

            self.array[cur] = .{ .content = .{
                .resourceType = resourceType,
                .version = 0,
                .index = index,
            } };

            return @ptrCast(@alignCast(&self.array[cur]));
        }

        pub fn destroyHandle(self: *Self, handle: Handle) void {
            const ptr: *H = @ptrCast(@alignCast(handle));
            var old_head = self.next.load(.seq_cst);

            while (true) {
                const cur_idx = old_head.index;
                ptr.* = .{ .next = .{ .index = cur_idx } };

                const new_tag = old_head.tag +% 1;
                const new_head = Node{
                    .index = @intCast(ptr - self.array.ptr),
                    .tag = new_tag,
                };

                if (self.next.cmpxchgWeak(old_head, new_head, .seq_cst, .seq_cst)) |h| {
                    old_head = h;
                } else {
                    break;
                }
            }

            _ = self.cap.fetchAdd(1, .seq_cst);
        }

        pub fn setIndex(self: *Self, handle: Handle, index: u32) void {
            _ = self;

            const ptr: *H = @ptrCast(@alignCast(handle));

            ptr.content.index = index;
        }
    };
}
