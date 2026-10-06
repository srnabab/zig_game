const std = @import("std");
const atomic = std.atomic;

const builtin = @import("builtin");

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

pub fn Handles(comptime capacity: u32, comptime stack_depth: usize) type {
    const stack_n = @max(1, stack_depth);

    return struct {
        const Self = @This();

        const Max = @min(capacity, Limit);

        array: []H,
        lastEndIndex: std.atomic.Value(u32) = .init(0),

        next: atomic.Value(Node) = .{ .raw = .{} },

        cap: atomic.Value(u32) = .init(capacity),

        createCount: atomic.Value(u32) = .init(0),

        stack_addresses: if (builtin.mode == .Debug) [][stack_n]usize else void,

        pub fn init(allocator: std.mem.Allocator) !Self {
            const stack_addresses = if (builtin.mode == .Debug) al: {
                break :al try allocator.alloc([stack_n]usize, capacity);
            } else void{};

            if (builtin.mode == .Debug) {
                @memset(stack_addresses, [_]usize{std.math.maxInt(usize)} ** stack_n);
            }

            return Self{
                .array = try allocator.alloc(H, capacity),
                .stack_addresses = stack_addresses,
            };
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            allocator.free(self.array);

            if (builtin.mode == .Debug) {
                if (self.createCount.load(.monotonic) != 0)
                    for (self.stack_addresses, 0..) |*address, i| {
                        if (address[0] == std.math.maxInt(usize)) continue;

                        const stack_addresses = address;
                        var len: usize = 0;
                        while (len < stack_n and stack_addresses[len] != 0) {
                            len += 1;
                        }
                        const stack_trace = std.debug.StackTrace{
                            .return_addresses = stack_addresses[0..len],
                            .skipped = if (len < stack_addresses.len) .none else .unknown,
                        };

                        std.log.err("-> handle {*} not destroyed", .{&self.array[i]});

                        std.log.err("handle leaked: {f}", .{
                            std.debug.FormatStackTrace{
                                .stack_trace = stack_trace,
                                .terminal_mode = std.log.terminalMode(),
                            },
                        });
                    };

                allocator.free(self.stack_addresses);
            }
        }

        pub fn createHandle(self: *Self, index: u32, resourceType: ResourceType) Handle {
            const returnAddress = @returnAddress();

            if (self.cap.load(.seq_cst) == 0) {
                std.log.err("no more free handle, used: {d}, capactiy: {d}", .{
                    self.createCount.load(.acquire),
                    self.cap.load(.acquire),
                });
                std.process.abort();
            }

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
                        std.log.err("no more free handle, used: {d}, capactiy: {d}", .{
                            self.createCount.load(.acquire),
                            self.cap.load(.acquire),
                        });
                        // for (self.array) |v| {
                        //     std.log.debug("{d}, {s}", .{ v.content.index, @tagName(v.content.resourceType) });
                        // }
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
            _ = self.createCount.fetchAdd(1, .acq_rel);

            var addr_buf = &self.stack_addresses[cur];
            const st = std.debug.captureCurrentStackTrace(.{ .first_address = returnAddress }, addr_buf);
            @memset(addr_buf[@min(st.return_addresses.len, addr_buf.len)..], 0);

            self.array[cur] = .{ .content = .{
                .resourceType = resourceType,
                .version = 0,
                .index = index,
            } };

            return @ptrCast(@alignCast(&self.array[cur]));
        }

        pub fn destroyHandle(self: *Self, handle: Handle) void {
            if (@intFromPtr(handle) < @intFromPtr(self.array.ptr) or @intFromPtr(handle) > @intFromPtr(self.array.ptr + (self.array.len - 1))) return;

            const ptr: *H = @ptrCast(@alignCast(handle));
            const destroyIndex = ptr - self.array.ptr;

            if (destroyIndex >= capacity) return;

            var old_head = self.next.load(.seq_cst);

            while (true) {
                const cur_idx = old_head.index;
                ptr.* = .{ .next = .{ .index = cur_idx } };

                const new_tag = old_head.tag +% 1;
                const new_head = Node{
                    .index = @intCast(destroyIndex),
                    .tag = new_tag,
                };

                if (self.next.cmpxchgWeak(old_head, new_head, .seq_cst, .seq_cst)) |h| {
                    old_head = h;
                } else {
                    if (builtin.mode == .Debug)
                        self.stack_addresses[destroyIndex][0] = std.math.maxInt(usize);

                    break;
                }
            }

            _ = self.cap.fetchAdd(1, .seq_cst);
            _ = self.createCount.fetchSub(1, .acq_rel);
        }

        pub fn setIndex(self: *Self, handle: Handle, index: u32) void {
            _ = self;

            const ptr: *H = @ptrCast(@alignCast(handle));

            ptr.content.index = index;
        }
    };
}

test "handle create, destroy" {
    const testCount = 1024;
    const TestHandlePoolType = Handles(testCount, .Reuse);
    var hs: TestHandlePoolType = try .init(std.testing.allocator);
    defer hs.deinit(std.testing.allocator);

    var ptrs = try std.testing.allocator.alloc(Handle, testCount);
    defer std.testing.allocator.free(ptrs);

    for (0..testCount) |i| {
        ptrs[i] = hs.createHandle(@intCast(i), .others);
    }
    try std.testing.expect(hs.cap.raw == 0);
    try std.testing.expect(hs.createCount.raw == testCount);

    for (0..testCount) |i| {
        if (i % 2 == 0) {
            hs.destroyHandle(ptrs[i]);
        }
    }
    try std.testing.expect(hs.cap.raw == testCount / 2);
    try std.testing.expect(hs.createCount.raw == testCount / 2);

    for (0..testCount) |i| {
        if (i % 2 == 0) {
            _ = hs.createHandle(@intCast(i), .others);
        }
    }
}
