const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const std = @import("std");
const assert = std.debug.assert;
const tables = @import("tables");
const fileNameID = @import("fileNameID.zig");

pub const comptimeGetID = fileNameID.comptimeGetID;
pub const getID = fileNameID.getID;

const ContentPath = tables.ContentPath;
const ImageLoadParameter = tables.ImageLoadParameter;

var db: ?*sqlite.sqlite3 = null;
var ContentPathT: ContentPath = undefined;
var ImageLoadParameterT: ImageLoadParameter = undefined;

fn getRelativePath(id: i64, result: []u8) !void {
    var ptrs: [1]*anyopaque = undefined;
    ptrs[0] = @ptrCast(result.ptr);

    var types = [_]sqlDB.innerType{.TEXT};
    // std.log.info("{*} {d}", .{ fileName.ptr, fileName.len });

    ContentPathT.get("RelativePath", null, "ID = ?", .{id}, &ptrs, &types) catch |err| {
        std.log.err("err {s} {s} ID{d} ", .{ @errorName(err), result, id });
    };
}

pub fn init(databaseName: []const u8) void {
    var disk_db: ?*sqlite.sqlite3 = null;
    var backup: ?*sqlite.sqlite3_backup = null;

    var res = sqlite.sqlite3_open(@ptrCast(databaseName.ptr), @ptrCast(&disk_db));
    defer _ = sqlite.sqlite3_close(disk_db);
    assert(res == sqlite.SQLITE_OK);

    res = sqlite.sqlite3_open(":memory:", @ptrCast(&db));
    assert(res == sqlite.SQLITE_OK);

    backup = sqlite.sqlite3_backup_init(db, "main", disk_db, "main");
    assert(backup != null);

    res = sqlite.sqlite3_backup_step(backup, -1);
    defer _ = sqlite.sqlite3_backup_finish(backup);
    assert(res == sqlite.SQLITE_DONE);

    ContentPathT = ContentPath.init(db.?);
    ImageLoadParameterT = ImageLoadParameter.init(db.?);
}

pub fn getFile(id: i64, cwd: std.fs.Dir) !std.fs.File {
    var buffer = [_]u8{0} ** 256;

    try getRelativePath(id, &buffer);
    const ptr = @as([*c]u8, buffer[0..256]);
    const len = std.mem.len(ptr);

    std.log.debug("open file {s}", .{buffer[0..len]});

    return cwd.openFile(buffer[0..len], .{});
}

pub const FileType = enum {
    DIR,
    OBJ,
    MTL,
    PNG,
    TSDI,
    TSD,
    TTF,
    WAV,
    SPV,
    TXT,
    HASHTABLE,
    UNKNOWN,
};

pub fn getFileType(id: i32) sqlDB.sqliteError!FileType {
    var res: i64 = 0;
    var ptrs: [1]*anyopaque = undefined;
    ptrs[0] = @ptrCast(&res);

    var types = [_]sqlDB.innerType{.INTEGER};

    try ContentPathT.get("FileType", null, "ID = ?", .{id}, &ptrs, &types);

    return @enumFromInt(res);
}

const vk = @cImport(@cInclude("vulkan/vulkan.h"));

// pub const PipelineShaderInfo = struct {
//     const Self = @This();

//     const binding = struct {
//         set: u32,
//         binding: u32,
//         descriptorCount: u32,
//         descriptorType: vk.VkDescriptorType,
//     };

//     file: std.fs.File,
//     fileSize: u64,
//     entryName: [64:0]u8,
//     stage: vk.VkShaderStageFlags,
//     setCount: u32,
//     bindingCount: u32,
//     bindings: ?[]binding,
//     pushConstantSize: u64,

//     pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
//         if (self.bindings) |mem| {
//             allocator.free(mem);
//         }
//     }
// };

const imageLoad = struct {
    relativePath: [256]u8,
    format: vk.VkFormat,
    tiling: vk.VkImageTiling,
    usage: vk.VkImageUsageFlags,
    properties: vk.VkMemoryPropertyFlags,
};

pub fn getImageLoadParam(id: i32) !imageLoad {
    const fType = try getFileType(id);
    switch (fType) {
        .PNG => {
            var ptrs: [5]*anyopaque = undefined;
            var buffer = [_]u8{0} ** 256;
            var format: vk.VkFormat = vk.VK_FORMAT_UNDEFINED;
            var tiling: vk.VkImageTiling = vk.VK_IMAGE_TILING_OPTIMAL;
            var usage: vk.VkImageUsageFlags = undefined;
            var properties: vk.VkMemoryPropertyFlags = undefined;
            ptrs[0] = @ptrCast(&buffer);
            ptrs[1] = @ptrCast(&format);
            ptrs[2] = @ptrCast(&tiling);
            ptrs[3] = @ptrCast(&usage);
            ptrs[4] = @ptrCast(&properties);

            var types = [_]sqlDB.innerType{ .TEXT, .INTEGER32, .INTEGER32, .INTEGER32, .INTEGER32 };

            try ImageLoadParameterT.get("RelativePath,Format,Tiling,Usage,Properties", null, "ID = ?", .{id}, &ptrs, &types);

            return imageLoad{
                .format = format,
                .tiling = tiling,
                .usage = usage,
                .properties = properties,
                .relativePath = buffer,
            };
        },
        else => {
            return error.fileTypeError;
        },
    }
}

pub fn deinit(databaseName: []const u8) void {
    var disk_db: ?*sqlite.sqlite3 = null;
    var backup: ?*sqlite.sqlite3_backup = null;

    var res = sqlite.sqlite3_open(@ptrCast(databaseName.ptr), @ptrCast(&disk_db));
    defer _ = sqlite.sqlite3_close(disk_db);
    assert(res == sqlite.SQLITE_OK);

    backup = sqlite.sqlite3_backup_init(disk_db, "main", db, "main");
    assert(backup != null);

    res = sqlite.sqlite3_backup_step(backup, -1);
    defer _ = sqlite.sqlite3_backup_finish(backup);
    assert(res == sqlite.SQLITE_DONE);

    _ = sqlite.sqlite3_close(db.?);
}
