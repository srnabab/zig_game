const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const std = @import("std");
const global = @import("global");
const assert = std.debug.assert;
const tables = @import("tables");
const base = @import("fileSystemBase.zig");
const vk = @import("vulkan");
const tracy = @import("tracy");

pub fn init() void {
    const zone = tracy.initZone(@src(), .{ .name = "init sqlite database" });
    defer zone.deinit();

    base.init(global.databaseName);
}

pub fn getFile(io: std.Io, id: i32) !std.Io.File {
    const zone = tracy.initZone(@src(), .{ .name = "open file from database" });
    defer zone.deinit();

    return base.getFile(io, id, std.Io.Dir.cwd());
}

pub const imageLoad = struct {
    file: std.Io.File,
    image: base.Image,
};

pub fn getImageLoadParam(io: std.Io, id: i32) !imageLoad {
    const zone = tracy.initZone(@src(), .{ .name = "get image load parameter" });
    defer zone.deinit();

    const res = try base.getImageLoadParam(id);
    const ptr = @as([*c]u8, @constCast(&res.relativePath));
    const len = std.mem.len(ptr);

    // std.log.debug("file {s}", .{res.relativePath});

    return imageLoad{
        .file = try std.Io.Dir.cwd().openFile(io, res.relativePath[0..len], .{}),
        .image = res.image,
    };
}

pub const meshLoad = struct {
    file: std.Io.File,
    mesh: base.Mesh,
};

pub fn getMeshLoadParam(io: std.Io, id: i32) !meshLoad {
    const zone = tracy.initZone(@src(), .{ .name = "get mesh load parameter" });
    defer zone.deinit();

    const res = try base.getMeshLoadParam(id);
    const ptr = @as([*c]u8, @constCast(&res.relativePath));
    const len = std.mem.len(ptr);

    // std.log.debug("file {s}", .{res.relativePath});

    return meshLoad{
        .file = try std.Io.Dir.cwd().openFile(io, res.relativePath[0..len], .{}),
        .mesh = res.mesh,
    };
}

pub const comptimeGetID = base.comptimeGetID;
pub const getID = base.getID;

const FileType = base.FileType;

pub fn getFileType(name: []const u8) sqlDB.sqliteError!FileType {
    return base.getFileType(name);
}

pub fn deinit() void {
    const zone = tracy.initZone(@src(), .{ .name = "deinit sqlite database" });
    defer zone.deinit();

    base.deinit(global.databaseName);
}
