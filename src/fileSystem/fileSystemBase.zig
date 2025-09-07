const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const std = @import("std");
const assert = std.debug.assert;
const tables = @import("tables");

const ContentPath = tables.ContentPath;
const ImageLoadParameter = tables.ImageLoadParameter;

var db: ?*sqlite.sqlite3 = null;
var ContentPathT: ContentPath = undefined;
var ImageLoadParameterT: ImageLoadParameter = undefined;

fn getRelativePath(fileName: []const u8, result: []u8) !void {
    var ptrs: [1]*anyopaque = undefined;
    ptrs[0] = @ptrCast(result.ptr);

    var types = [_]sqlDB.innerType{.TEXT};
    // std.log.info("{*} {d}", .{ fileName.ptr, fileName.len });

    ContentPathT.get("RelativePath", null, "FileName = ?", .{fileName}, &ptrs, &types) catch |err| {
        std.log.err("err {s} {s} fileName:{s}", .{ @errorName(err), result, fileName });
    };
}

pub fn init(databaseName: []const u8) void {
    const res = sqlite.sqlite3_open(@ptrCast(databaseName.ptr), @ptrCast(&db));
    assert(res == sqlite.SQLITE_OK);

    ContentPathT = ContentPath.init(db.?);
    ImageLoadParameterT = ImageLoadParameter.init(db.?);
}

pub fn getFile(fileName: []const u8, cwd: std.fs.Dir) !std.fs.File {
    var buffer = [_]u8{0} ** 256;

    try getRelativePath(fileName, &buffer);
    const ptr = @as([*c]u8, buffer[0..256]);
    const len = std.mem.len(ptr);

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

pub fn getFileType(name: []const u8) sqlDB.sqliteError!FileType {
    var res: i64 = 0;
    var ptrs: [1]*anyopaque = undefined;
    ptrs[0] = @ptrCast(&res);

    var types = [_]sqlDB.innerType{.INTEGER};

    try ContentPathT.get("FileType", null, "FileName = ?", .{name}, &ptrs, &types);

    return @enumFromInt(res);
}

const vk = @cImport(@cInclude("vulkan/vulkan.h"));

pub const PipelineShaderInfo = struct {
    const Self = @This();

    const binding = struct {
        set: u32,
        binding: u32,
        descriptorCount: u32,
        descriptorType: vk.VkDescriptorType,
    };

    file: std.fs.File,
    fileSize: u64,
    entryName: [64:0]u8,
    stage: vk.VkShaderStageFlags,
    setCount: u32,
    bindingCount: u32,
    bindings: ?[]binding,
    pushConstantSize: u64,

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        if (self.bindings) |mem| {
            allocator.free(mem);
        }
    }
};

pub fn deinit() void {
    _ = sqlite.sqlite3_close(db.?);
}
