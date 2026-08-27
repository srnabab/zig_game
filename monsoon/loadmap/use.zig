const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const assert = std.debug.assert;

const cglm = @import("cglm");
const resource = @import("resource");

pub const loadmap = @import("loadmap.zig");

const Self = @This();

loadmaps: []loadmap,

pub fn init(gpa: Allocator, mapCount: u32) !Self {
    const maps = try gpa.alloc(loadmap, mapCount);
    @memset(maps, .empty);
    return .{
        .loadmaps = maps,
    };
}

pub fn deinit(self: *Self, gpa: Allocator) void {
    for (self.loadmaps) |*value| {
        value.free();
    }
    gpa.free(self.loadmaps);
}

pub fn addMap(self: *Self, map: loadmap, index: u32) void {
    assert(index < self.loadmaps.len);

    self.loadmaps[index] = map;
}

pub fn load(self: *Self, ctx: *const resource.ResourceCtx, index: u32, pos: cglm.vec2) !void {
    assert(index < self.loadmaps.len);

    try self.loadmaps[index].loadResource(ctx, pos);
}
