const sqlite = @cImport(@cInclude("sqlite3/sqlite3.h"));
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const std = @import("std");
const sqlDB = @import("sqliteDB.zig");

const AliasName = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS AliasNamePair (ID INTEGER PRIMARY KEY AUTOINCREMENT, Alias TEXT NOT NULL UNIQUE, Name TEXT);",
    "AliasNamePair",
    true,
);
const ContentPath = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ContentPath (ID TEXT PRIMARY KEY,  ParentID TEXT,  RelativePath TEXT NOT NULL UNIQUE,  FileName TEXT,  TYPE INTEGER, FileSize INTEGER, ContentHash BLOB, ModifiedTime INTEGER, LastSeenTime INTEGER, FileType INTEGER);",
    "ContentPath",
    false,
);
const ImageLoadParameter = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ImageLoadParameter ( ID INTEGER PRIMARY KEY AUTOINCREMENT, FileName TEXT UNIQUE, InnerName TEXT UNIQUE, ContentHash BLOB UNIQUE, FileID TEXT, FOREIGN KEY(FileID) REFERENCES contentPath(ID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ImageLoadParameter",
    true,
);

pub fn main() !void {
    var db: ?*sqlite.sqlite3 = null;
    if (sqlite.sqlite3_open("test.db", @ptrCast(&db)) != sqlite.SQLITE_OK) return error.SQLError;
    defer _ = sqlite.sqlite3_close(db);

    var tableTest = AliasName.init(db.?);
    try tableTest.createTable();
    var t2 = ContentPath.init(db.?);
    var t3 = ImageLoadParameter.init(db.?);
    try t2.createTable();
    try t3.createTable();
    std.debug.assert(tableTest.exist());

    var a: u32 = 128;
    a += 1;

    tableTest.insert(.{ .Alias = "alias1", .Name = "name1" });
    t2.insert(.{
        .ID = "asdfdas",
        .ParentID = "aaaa",
        .RelativePath = "aasdf",
        .FileName = "aabb",
        .TYPE = a,
        .FileSize = 12452345,
        .ContentHash = sqlDB.BLOB{ .data = "asa", .len = 3 },
        .ModifiedTime = 874567845,
        .LastSeenTime = 634564235234,
        .FileType = 3,
    });
    t3.insert(.{
        .FileName = "a",
        .InnerName = "b",
        .ContentHash = sqlDB.BLOB{ .data = "a", .len = 1 },
        .FileID = "c",
    });
    t3.update("Filename,FileID", "InnerName = ?", .{ "ffff", "cccc", "b" });
    var tt1 = [_]u8{0} ** 16;
    var tt2 = [_]u8{0} ** 16;

    var sss: [2]*anyopaque = undefined;
    var types = [2]sqlDB.innerType{ .TEXT, .TEXT };
    sss[0] = @ptrCast(&tt1);
    sss[1] = @ptrCast(&tt2);

    try t3.get(
        "FileName,FileID",
        "InnerName = ?",
        .{"b"},
        &sss,
        &types,
    );

    std.log.info("filename: {s}, fileid {s}", .{ tt1, tt2 });

    var sss2: [1]*anyopaque = undefined;
    var types2 = [1]sqlDB.innerType{.BLOB};
    var ddd = [1]u8{0};
    var getad = sqlDB.VOID_{ .data = &ddd, .len = 1 };
    sss2[0] = &getad;
    try t3.get("ContentHash", "InnerName = ?", .{"b"}, &sss2, &types2);
    std.log.info("filename: {s}", .{ddd});
    // t3.delete("InnerName = ?", .{"b"});
}
