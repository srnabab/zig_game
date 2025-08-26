const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const std = @import("std");
const global = @import("global");
const assert = std.debug.assert;

const ContentPath = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ContentPath (ID TEXT PRIMARY KEY,  ParentID TEXT,  RelativePath TEXT NOT NULL UNIQUE,  FileName TEXT,  TYPE INTEGER, FileSize INTEGER, ContentHash BLOB, ModifiedTime INTEGER, LastSeenTime INTEGER, FileType INTEGER);",
    "ContentPath",
    false,
);
const ImageLoadParameter = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ImageLoadParameter (FileName TEXT PRIMARY KEY, ContentHash BLOB UNIQUE, RelativePath TEXT UNIQUE, FileID TEXT, FOREIGN KEY(FileID) REFERENCES ContentPath(ID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ImageLoadParameter",
    false,
);
const ShaderLoadParameter = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ShaderLoadParameter (FileName TEXT PRIMARY KEY, ContentHash BLOB UNIQUE, RelativePath TEXT UNIQUE, FileSize INTEGER" ++
        ", EntryName TEXT, Stage INTEGER, BindingCount INTEGER, Bindings BLOB, PushConstantSize INTEGER" ++
        ", FileID TEXT, FOREIGN KEY(FileID) REFERENCES ContentPath(ID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ShaderLoadParameter",
    false,
);

var db: ?*sqlite.sqlite3 = null;
var ContentPathT: ContentPath = undefined;
var ImageLoadParameterT: ImageLoadParameter = undefined;
var ShaderLoadParameterT: ShaderLoadParameter = undefined;

fn getRelativePath(fileName: []const u8, result: []u8) !void {
    var ptrs: [1]*anyopaque = undefined;
    ptrs[0] = @ptrCast(result.ptr);

    var types = [_]sqlDB.innerType{.TEXT};
    // std.log.info("{*} {d}", .{ fileName.ptr, fileName.len });

    ContentPathT.get("RelativePath", "FileName = ?", .{fileName}, &ptrs, &types) catch |err| {
        std.log.err("err {s} {s} fileName:{s}", .{ @errorName(err), result, fileName });
    };
}

pub fn init() void {
    const res = sqlite.sqlite3_open(@ptrCast(global.databaseName), @ptrCast(&db));
    assert(res == sqlite.SQLITE_OK);

    ContentPathT = ContentPath.init(db.?);
    ImageLoadParameterT = ImageLoadParameter.init(db.?);
    ShaderLoadParameterT = ShaderLoadParameter.init(db.?);
}

pub fn getFile(fileName: []const u8) !std.fs.File {
    var buffer = [_]u8{0} ** 256;

    try getRelativePath(fileName, &buffer);
    const ptr = @as([*c]u8, buffer[0..256]);
    const len = std.mem.len(ptr);

    return global.cwd.openFile(buffer[0..len], .{});
}

pub fn deinit() void {
    _ = sqlite.sqlite3_close(db.?);
}
