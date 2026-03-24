const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const std = @import("std");
const global = @import("global");
const assert = std.debug.assert;
const tables = @import("tables");
const base = @import("fileSystemBase.zig");
const vk = @cImport(@cInclude("vulkan/vulkan.h"));
const tracy = @import("tracy");

pub fn init() void {
    const zone = tracy.initZone(@src(), .{ .name = "init sqlite database" });
    defer zone.deinit();

    base.init(global.databaseName);
}

pub fn getFile(id: i32) !std.fs.File {
    const zone = tracy.initZone(@src(), .{ .name = "open file from database" });
    defer zone.deinit();

    return base.getFile(id, std.fs.cwd());
}

pub const imageLoad = struct {
    file: std.fs.File,
    format: vk.VkFormat,
    tiling: vk.VkImageTiling,
    usage: vk.VkImageUsageFlags,
    properties: vk.VkMemoryPropertyFlags,
};

pub fn getImageLoadParam(id: i32) !imageLoad {
    const zone = tracy.initZone(@src(), .{ .name = "get image load parameter" });
    defer zone.deinit();

    const res = try base.getImageLoadParam(id);
    const ptr = @as([*c]u8, @constCast(&res.relativePath));
    const len = std.mem.len(ptr);

    std.log.debug("file {s}", .{res.relativePath});

    return imageLoad{
        .file = try std.fs.cwd().openFile(res.relativePath[0..len], .{}),
        .format = res.format,
        .tiling = res.tiling,
        .usage = res.usage,
        .properties = res.properties,
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
