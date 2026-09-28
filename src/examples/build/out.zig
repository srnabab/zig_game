const std = @import("std");
const Config = @import("config.zig").Config;

// import all customStruct
const vertices = @import("vertices.zig");
const meshInstance = @import("meshInstance.zig");
const mesh = @import("mesh.zig");
const passGroupMapping = @import("passGroupMapping.zig");
const renderData = @import("renderData.zig");

const Entry = struct {
    name: []const u8,
    build: fn (Config) *std.Build.Module,
};

/// add all customStruct to here\
/// pub fn build(cfg: Config) *std.Build.Module {}
pub const list = [_]Entry{
    .{ .name = vertices.name, .build = vertices.build },
    .{ .name = meshInstance.name, .build = meshInstance.build },
    .{ .name = mesh.name, .build = mesh.build },
    .{ .name = passGroupMapping.name, .build = passGroupMapping.build },
    .{ .name = renderData.name, .build = renderData.build },
};

/// engine will use this
pub fn build(cfg: Config) void {
    inline for (list) |l| {
        _ = l.build(cfg);
    }
}
