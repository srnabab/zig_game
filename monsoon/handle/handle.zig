const std = @import("std");
const atomic = std.atomic;

const Option = enum {
    Reuse,
    Once,
};

const Context = opaque {};
pub const Handle = *Context;
pub const WaitFill = std.math.maxInt(u32);
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
    padding: u8,
    version: atomic.Value(u16),
    index: atomic.Value(u32),
};

pub fn getIndex(handle: Handle) ?u32 {
    const ptr: *Content = @ptrCast(@alignCast(handle));

    if (ptr.version.load(.monotonic) == InvalidVersion) return null;

    return ptr.index.load(.monotonic);
}

pub fn typeCompare(handle: Handle, exceptedType: ResourceType) bool {
    const ptr: *Content = @ptrCast(@alignCast(handle));

    return ptr.resourceType == exceptedType;
}

pub fn handleIsValid(handle: Handle) bool {
    const ptr: *Content = @ptrCast(@alignCast(handle));

    return ptr.version.load(.monotonic) != InvalidVersion;
}

pub fn Handles(comptime capacity: u32, comptime option: Option) type {
    return struct {
        const Self = @This();

        array: []Content,
        index: std.atomic.Value(u32),

        loop: if (option == .Reuse) bool else void,
        lastEndIndex: if (option == .Reuse) u32 else void,

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                .array = try allocator.alloc(Content, capacity),
                .index = .init(0),
                .loop = if (option == .Reuse) false else void{},
                .lastEndIndex = if (option == .Reuse) 0 else void{},
            };
        }

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            allocator.free(self.array);
        }

        pub fn createHandle(self: *Self, index: u32, resourceType: ResourceType) Handle {
            if (option == .Reuse) {
                if (self.loop) {
                    for (self.array[self.lastEndIndex..], self.lastEndIndex..) |value, i| {
                        if (value.index.load(.monotonic) == std.math.maxInt(u32)) {
                            self.lastEndIndex = @intCast(i);

                            self.array[i].resourceType = resourceType;
                            self.array[i].version.store(if (index == WaitFill) InvalidVersion else 0, .monotonic);
                            self.array[i].index.store(index, .monotonic);

                            return @ptrCast(@alignCast(&self.array[i]));
                        }
                    }

                    std.process.abort();
                } else {
                    const current = self.index.fetchAdd(1, .seq_cst);

                    if (current == capacity - 1) {
                        self.loop = true;
                    }

                    self.array[current].resourceType = resourceType;
                    self.array[current].version.store(if (index == WaitFill) InvalidVersion else 0, .monotonic);
                    self.array[current].index.store(index, .monotonic);

                    return @ptrCast(@alignCast(&self.array[current]));
                }
            } else if (option == .Once) {
                const current = self.index.fetchAdd(1, .seq_cst);

                std.debug.assert(current < capacity);

                self.array[current].resourceType = resourceType;
                self.array[current].version.store(if (index == WaitFill) InvalidVersion else 0, .monotonic);
                self.array[current].index.store(index, .monotonic);

                return @ptrCast(@alignCast(&self.array[current]));
            }
        }

        pub fn destroyHandle(self: *Self, handle: Handle) void {
            if (option == .Reuse) {
                _ = self;

                const ptr: *Content = @ptrCast(@alignCast(handle));

                ptr.resourceType = .others;
                ptr.version.store(InvalidVersion, .monotonic);
                ptr.index.store(std.math.maxInt(u32), .monotonic);
            } else if (option == .Once) {
                _ = self;

                const ptr: *Content = @ptrCast(@alignCast(handle));

                ptr.resourceType = .others;
                ptr.version.store(InvalidVersion, .monotonic);
                ptr.index.store(std.math.maxInt(u32), .monotonic);
            }
        }

        pub fn setIndex(self: *Self, handle: Handle, index: u32) void {
            _ = self;
            const ptr: *Content = @ptrCast(@alignCast(handle));

            ptr.version.store(0, .monotonic);
            ptr.index.store(index, .monotonic);
        }
    };
}
