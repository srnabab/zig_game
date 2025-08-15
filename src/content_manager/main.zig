const sqlite = @cImport(@cInclude("sqlite3/sqlite3.h"));
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const std = @import("std");
const builtin = @import("builtin");
const sqlDB = @import("sqliteDB.zig");
const UUID = @import("UUID.zig");
const hash = @import("blake_hash.zig");

const AliasNamePair = sqlDB.Table(
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
    "CREATE TABLE IF NOT EXISTS ImageLoadParameter (FileName TEXT PRIMARY KEY, ContentHash BLOB UNIQUE, FileID TEXT, FOREIGN KEY(FileID) REFERENCES ContentPath(ID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ImageLoadParameter",
    true,
);
const ShaderLoadParameter = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ShaderLoadParameter (FileName TEXT PRIMARY KEY, ContentHash BLOB UNIQUE, RelativePath TEXT NOT NULL UNIQUE, FileSize INTEGER, FileID TEXT, FOREIGN KEY(FileID) REFERENCES ContentPath(ID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ShaderLoadParameter",
    false,
);

const tableNames = [_][]const u8{ "ImageLoadParameter", "ShaderLoadParameter" };

const CreateTriggerContentPathOnInsertInsertIntoSubTable = tt: {
    var buffer = [_]u8{0} ** 10240;
    var st = std.io.fixedBufferStream(&buffer);
    var writer = st.writer();
    var count: usize = 0;

    for (@typeInfo(FileType).@"enum".fields) |field| {
        switch (@as(FileType, @enumFromInt(field.value))) {
            .SPV => {
                count += writer.write(std.fmt.comptimePrint("CREATE TRIGGER IF NOT EXISTS insertInto{s} AFTER INSERT ON ContentPath FOR EACH ROW WHEN NEW.FileType={d} BEGIN " ++
                    "INSERT INTO ShaderLoadParameter (FileName,ContentHash,RelativePath,FileSize,FileID) VALUES " ++
                    "(NEW.FileName,NEW.ContentHash,NEW.RelativePath,NEW.FileSize,NEW.ID); END;", .{ tableNames[1], field.value })) catch |err| {
                    @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
                };
            },
            .PNG => {
                count += writer.write(std.fmt.comptimePrint("CREATE TRIGGER IF NOT EXISTS insertInto{s} AFTER INSERT ON ContentPath FOR EACH ROW WHEN NEW.FileType={d} BEGIN " ++
                    "INSERT INTO ImageLoadParameter (FileName,ContentHash,FileID) VALUES (NEW.FileName,NEW.ContentHash,NEW.ID);  END;", .{ tableNames[0], field.value })) catch |err| {
                    @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
                };
            },
            else => {
                continue;
            },
        }
    }

    break :tt std.fmt.comptimePrint("{s}", .{buffer});
};

const createTriggerOnUpdateCascadeBetweenContentPathAndTablesOnContentHash = ct: {
    var buffer = [_]u8{0} ** 10240;
    var st = std.io.fixedBufferStream(&buffer);
    var writer = st.writer();
    var count: usize = 0;

    for (tableNames) |name| {
        count += writer.write(std.fmt.comptimePrint("CREATE TRIGGER IF NOT EXISTS cascadeContentHash{s} AFTER UPDATE OF ContentHash ON ContentPath " ++
            "FOR EACH ROW BEGIN UPDATE {s} SET ContentHash = NEW.ContentHash WHERE FileID = OLD.ID; END;", .{ name, name })) catch |err| {
            @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
        };
    }

    break :ct std.fmt.comptimePrint("{s}", .{buffer});
};

const createTriggerOnInsertContentPathUpdateTablesFileIDWhereSameContentHash = cto: {
    var buffer = [_]u8{0} ** 10240;
    var st = std.io.fixedBufferStream(&buffer);
    var writer = st.writer();
    var count: usize = 0;

    for (tableNames) |name| {
        count += writer.write(std.fmt.comptimePrint("CREATE TRIGGER IF NOT EXISTS onInsertUpdataFileID{s} AFTER INSERT ON ContentPath FOR EACH ROW " ++
            "WHEN NEW.ContentHash IS NOT NULL BEGIN UPDATE {s} SET FileID = NEW.ID, FileName = NEW.FileName WHERE ContentHash = NEW.ContentHash " ++
            " OR FileName = NEW.FileName; END;", .{ name, name })) catch |err| {
            @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
        };
    }

    break :cto std.fmt.comptimePrint("{s}", .{buffer});
};

const createTriggerOnInsertContentPathCheckContentHash = "CREATE TRIGGER IF NOT EXISTS onInsertUpdateContentPath BEFORE INSERT ON ContentPath FOR EACH ROW BEGIN " ++
    "DELETE FROM ContentPath WHERE ContentHash = NEW.ContentHash; END;";

const ShaderLoad = struct { subPath: []const u8, len: usize };

const FileData = union {
    shader: ShaderLoad,
};

const FileType = enum {
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

const slash = sl: {
    switch (builtin.os.tag) {
        .windows => {
            break :sl "\\";
        },
        .linux => {
            break :sl "/";
        },
        else => {
            @compileError("unsupported");
        },
    }
};

const FileTypeHashTable = map: {
    const maptype = std.StaticStringMap(FileType);
    // var buffer = [_]u8{0} ** 10240;
    // var all: std.heap.FixedBufferAllocator = .init(buffer);
    // var allocator = all.allocator();
    const KV = struct {
        []const u8,
        FileType,
    };
    const list = [_]KV{
        .{ "", FileType.DIR },
        .{ ".obj", FileType.OBJ },
        .{ ".mtl", FileType.MTL },
        .{ ".png", FileType.PNG },
        .{ ".tsdI", FileType.TSDI },
        .{ ".tsd", FileType.TSD },
        .{ ".ttf", FileType.TTF },
        .{ ".wav", FileType.WAV },
        .{ ".spv", FileType.SPV },
        .{ ".txt", FileType.TXT },
    };

    const maps = maptype.initComptime(list);
    break :map maps;
};

fn executeSQL(SQL: []const u8, db: *sqlite.sqlite3) void {
    const res = sqlite.sqlite3_exec(db, @ptrCast(SQL.ptr), null, null, null);

    if (res != sqlite.SQLITE_OK) {
        std.log.err("{s}", .{sqlite.sqlite3_errmsg(db)});
    }
}

fn nameToFileType(name: []const u8) FileType {
    return FileTypeHashTable.get(name) orelse FileType.UNKNOWN;
}

fn iterateFolderUpdate(dir: std.fs.Dir, dirName: []const u8, parentID: []const u8) !void {
    var contentIt = dir.iterate();
    while (contentIt.next() catch |err| blk: {
        std.log.err("{s}", .{@errorName(err)});
        break :blk null;
    }) |tt| {
        var bufferZ = [_]u8{0} ** 128;
        const nameZ = try std.fmt.bufPrintZ(&bufferZ, "{s}", .{tt.name});

        var relativePathBuffer = [_]u8{0} ** 256;
        const rPZ = try std.fmt.bufPrintZ(&relativePathBuffer, "{s}{s}{s}", .{ dirName, slash, tt.name });
        const rpLen = rPZ.len;

        const time: i64 = @truncate(std.time.nanoTimestamp());
        var fileModifiedTime: i64 = -1;
        var pathModifiedTime: i64 = -1;

        var getValues: [1]*anyopaque = undefined;
        getValues[0] = @ptrCast(&fileModifiedTime);
        var types = [_]sqlDB.innerType{.INTEGER};

        ContentPathT.get("ModifiedTime", "FileName = ?", .{nameZ}, &getValues, &types) catch |err| switch (err) {
            sqlDB.sqliteError.SQLError => {
                return err;
            },
            sqlDB.sqliteError.StepError => {
                fileModifiedTime = -1;
            },
            sqlDB.sqliteError.Empty => {},
        };
        // sdl.SDL_Log(@ptrCast(tt.name.ptr));
        // std.log.info("tt.name {s} {d} len{d}", .{ tt.name, fileModifiedTime, tt.name.len });

        getValues[0] = @ptrCast(&pathModifiedTime);
        ContentPathT.get("ModifiedTime", "RelativePath = ?", .{relativePathBuffer}, &getValues, &types) catch |err| switch (err) {
            sqlDB.sqliteError.SQLError => {
                return err;
            },
            sqlDB.sqliteError.StepError => {
                pathModifiedTime = -1;
            },
            else => {},
        };

        if (fileModifiedTime == -1) {
            var UUIDbuffer = [_]u8{0} ** UUID.len;
            try UUID.createNewUUID(&UUIDbuffer);

            switch (tt.kind) {
                .file => {
                    const index = std.mem.lastIndexOf(u8, tt.name, ".") orelse 0;

                    var file = try dir.openFile(tt.name, .{});
                    defer file.close();

                    var cc = try file.metadata();
                    const content = try gpa.alloc(u8, cc.size());
                    defer gpa.free(content);

                    _ = try file.readAll(content);
                    const hashh = hash.blake3HashContent(content);

                    try ContentPathT.insert(.{
                        .ID = &UUIDbuffer,
                        .ParentID = @constCast(parentID.ptr),
                        .RelativePath = &relativePathBuffer,
                        .FileName = @constCast(nameZ.ptr),
                        .TYPE = @intFromEnum(cc.kind()),
                        .FileSize = @intCast(cc.size()),
                        .ContentHash = sqlDB.BLOB{ .data = &hashh, .len = hash.blake3.BLAKE3_OUT_LEN },
                        .ModifiedTime = @as(i64, @truncate(cc.modified())),
                        .LastSeenTime = @as(i64, @truncate(time)),
                        .FileType = @intFromEnum(nameToFileType(tt.name[index..tt.name.len])),
                    });
                },
                .directory => {
                    var tempDir = try dir.openDir(tt.name, .{ .iterate = true });
                    defer tempDir.close();

                    var cc = try tempDir.metadata();

                    try ContentPathT.insert(.{
                        .ID = &UUIDbuffer,
                        .ParentID = @constCast(parentID.ptr),
                        .RelativePath = &relativePathBuffer,
                        .FileName = @constCast(nameZ.ptr),
                        .TYPE = @intFromEnum(cc.kind()),
                        .FileSize = @intCast(cc.size()),
                        .ContentHash = null,
                        .ModifiedTime = @as(i64, @truncate(cc.modified())),
                        .LastSeenTime = @as(i64, @truncate(time)),
                        .FileType = @intFromEnum(FileType.DIR),
                    });

                    try iterateFolderUpdate(tempDir, relativePathBuffer[0..rpLen], &UUIDbuffer);
                },
                else => {},
            }
        } else if (pathModifiedTime == -1) {
            switch (tt.kind) {
                .directory => {
                    var tempDir = try dir.openDir(tt.name, .{ .iterate = true });
                    defer tempDir.close();

                    var cc = try tempDir.metadata();
                    const modifiedTime: i64 = @truncate(cc.modified());

                    if (modifiedTime != fileModifiedTime) {
                        try ContentPathT.update("RelativePath,ParentID,ModifiedTime,LastSeenTime", "FileName = ?", .{
                            relativePathBuffer,
                            parentID,
                            modifiedTime,
                            time,
                            tt.name,
                        });
                    } else {
                        try ContentPathT.update("RelativePath,ParentID,LastSeenTime", "FileName = ?", .{ relativePathBuffer, parentID, time, tt.name });
                    }

                    var pID = [_]u8{0} ** UUID.len;
                    var ptrs = [_]*anyopaque{&pID};
                    var typesa = [_]sqlDB.innerType{.TEXT};

                    try ContentPathT.get("ID", "RelativePath = ?", .{relativePathBuffer}, &ptrs, &typesa);

                    try iterateFolderUpdate(tempDir, relativePathBuffer[0..rpLen], &pID);
                },
                .file => {
                    var tempFile = try dir.openFile(tt.name, .{});
                    defer tempFile.close();

                    var cc = try tempFile.metadata();
                    const modifiedTime: i64 = @truncate(cc.modified());

                    if (modifiedTime != fileModifiedTime) {
                        const content = try gpa.alloc(u8, cc.size());
                        defer gpa.free(content);

                        _ = try tempFile.readAll(content);
                        var contentHash = hash.blake3HashContent(content);

                        try ContentPathT.update("RelativePath,ParentID,ModifiedTime,LastSeenTime,ContentHash", "FileName = ?", .{
                            relativePathBuffer,
                            parentID,
                            modifiedTime,
                            time,
                            sqlDB.BLOB{ .data = &contentHash, .len = hash.blake3.BLAKE3_OUT_LEN },
                            tt.name,
                        });
                    } else {
                        try ContentPathT.update("RelativePath,ParentID,LastSeenTime", "FileName = ?", .{ relativePathBuffer, parentID, time, tt.name });
                    }
                },
                else => {},
            }
        } else {
            switch (tt.kind) {
                .file => {
                    var tempFile = try dir.openFile(tt.name, .{});
                    defer tempFile.close();

                    var cc = try tempFile.metadata();
                    const modifiedTime: i64 = @truncate(cc.modified());

                    if (modifiedTime != fileModifiedTime) {
                        const content = try gpa.alloc(u8, cc.size());
                        defer gpa.free(content);

                        _ = try tempFile.readAll(content);
                        var contentHash = hash.blake3HashContent(content);

                        try ContentPathT.update("ModifiedTime,LastSeenTime,ContentHash", "FileName = ?", .{
                            modifiedTime,
                            time,
                            sqlDB.BLOB{ .data = &contentHash, .len = hash.blake3.BLAKE3_OUT_LEN },
                            tt.name,
                        });
                    } else {
                        try ContentPathT.update("LastSeenTime", "FileName = ?", .{ time, tt.name });
                    }
                },
                .directory => {
                    var tempDir = try dir.openDir(tt.name, .{ .iterate = true });
                    defer tempDir.close();

                    var cc = try tempDir.metadata();
                    const modifiedTime: i64 = @truncate(cc.modified());

                    if (modifiedTime != fileModifiedTime) {
                        try ContentPathT.update("ModifiedTime,LastSeenTime", "FileName = ?", .{ modifiedTime, time, tt.name });
                    } else {
                        try ContentPathT.update("LastSeenTime", "FileName = ?", .{ time, tt.name });
                    }

                    var pID = [_]u8{0} ** UUID.len;
                    var ptrs = [_]*anyopaque{&pID};
                    var typesa = [_]sqlDB.innerType{.TEXT};

                    try ContentPathT.get("ID", "RelativePath = ?", .{relativePathBuffer}, &ptrs, &typesa);

                    try iterateFolderUpdate(tempDir, relativePathBuffer[0..rpLen], &pID);
                },
                else => {},
            }
        }
    }
}

fn iterateFolderInsert(dir: std.fs.Dir, dirName: []const u8, parentID: []const u8) !void {
    var contentIt = dir.iterate();
    while (contentIt.next() catch |err| blk: {
        std.log.err("{s}", .{@errorName(err)});
        break :blk null;
    }) |tt| {
        // std.log.info("{s}{s}{s}", .{ dirName, slash, tt.name });
        var bufferZ = [_]u8{0} ** 128;
        const nameZ = try std.fmt.bufPrintZ(&bufferZ, "{s}", .{tt.name});

        var relativePathBuffer = [_]u8{0} ** 256;
        const rPZ = try std.fmt.bufPrintZ(&relativePathBuffer, "{s}{s}{s}", .{ dirName, slash, tt.name });
        const rpLen = rPZ.len;

        var UUIDbuffer = [_]u8{0} ** 38;
        try UUID.createNewUUID(&UUIDbuffer);

        const time = std.time.nanoTimestamp();

        switch (tt.kind) {
            .file => {
                const index = std.mem.lastIndexOf(u8, tt.name, ".") orelse 0;

                var tempFile = try dir.openFile(tt.name, .{});
                defer tempFile.close();

                var cc = try tempFile.metadata();
                var content = try gpa.alloc(u8, cc.size());
                defer gpa.free(content);
                _ = try tempFile.readAll(content);

                var hashh = hash.blake3HashContent(content[0..cc.size()]);

                try ContentPathT.insert(.{
                    .ID = &UUIDbuffer,
                    .ParentID = @constCast(parentID.ptr),
                    .RelativePath = &relativePathBuffer,
                    .FileName = @constCast(nameZ.ptr),
                    .TYPE = @intFromEnum(cc.kind()),
                    .FileSize = @intCast(cc.size()),
                    .ContentHash = sqlDB.BLOB{ .data = &hashh, .len = hash.blake3.BLAKE3_OUT_LEN },
                    .ModifiedTime = @as(i64, @truncate(cc.modified())),
                    .LastSeenTime = @as(i64, @truncate(time)),
                    .FileType = @intFromEnum(nameToFileType(tt.name[index..tt.name.len])),
                });
            },
            .directory => {
                var tempDir = try dir.openDir(tt.name, .{ .iterate = true });
                defer tempDir.close();

                var cc = try tempDir.metadata();

                try ContentPathT.insert(.{
                    .ID = &UUIDbuffer,
                    .ParentID = @constCast(parentID.ptr),
                    .RelativePath = &relativePathBuffer,
                    .FileName = @constCast(nameZ.ptr),
                    .TYPE = @intFromEnum(cc.kind()),
                    .FileSize = @intCast(cc.size()),
                    .ContentHash = null,
                    .ModifiedTime = @as(i64, @truncate(cc.modified())),
                    .LastSeenTime = @as(i64, @truncate(time)),
                    .FileType = @intFromEnum(FileType.DIR),
                });

                try iterateFolderInsert(tempDir, relativePathBuffer[0..rpLen], &UUIDbuffer);
            },
            else => {
                return error.unsupported;
            },
        }
    }
}

var ContentPathT: ContentPath = undefined;
var AliasNamePairT: AliasNamePair = undefined;
var ImageLoadParameterT: ImageLoadParameter = undefined;
var ShaderLoadParameterT: ShaderLoadParameter = undefined;

var gpa: std.mem.Allocator = undefined;
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
    const start = std.time.nanoTimestamp();

    gpa, const is_debug = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };

    var it = try std.process.argsWithAllocator(gpa);
    defer it.deinit();

    const rootExe = it.next().?;
    std.log.info("{s}", .{rootExe});

    var root: [256:0]u8 = undefined;
    @memset(root[0..root.len], 0);
    std.mem.copyForwards(u8, &root, rootExe);

    const index = std.mem.lastIndexOf(u8, &root, slash) orelse 0;
    @memset(root[index..root.len], 0);

    std.log.info("{s}", .{root});

    var cwd = try std.fs.openDirAbsolute(&root, .{});
    try cwd.setAsCwd();

    var db: ?*sqlite.sqlite3 = null;
    if (sqlite.sqlite3_open("Content.db", @ptrCast(&db)) != sqlite.SQLITE_OK) return error.SQLError;
    defer _ = sqlite.sqlite3_close(db);

    ContentPathT = ContentPath.init(db.?);
    const exist = ContentPathT.exist();
    try ContentPathT.createTable();
    AliasNamePairT = AliasNamePair.init(db.?);
    try AliasNamePairT.createTable();
    ImageLoadParameterT = ImageLoadParameter.init(db.?);
    try ImageLoadParameterT.createTable();
    ShaderLoadParameterT = ShaderLoadParameter.init(db.?);
    try ShaderLoadParameterT.createTable();
    executeSQL(createTriggerOnInsertContentPathCheckContentHash, db.?);
    executeSQL(CreateTriggerContentPathOnInsertInsertIntoSubTable, db.?);
    executeSQL(createTriggerOnInsertContentPathUpdateTablesFileIDWhereSameContentHash, db.?);
    executeSQL(createTriggerOnUpdateCascadeBetweenContentPathAndTablesOnContentHash, db.?);

    var content = try cwd.openDir("Content", .{ .iterate = true });
    defer content.close();

    if (exist) {
        const cc = try content.metadata();
        const time = std.time.nanoTimestamp();
        var modifiedTime: i64 = 0;
        var buffer = [_]u8{0} ** UUID.len;

        var getValues: [2]*anyopaque = undefined;
        getValues[0] = @ptrCast(&buffer);
        getValues[1] = @ptrCast(&modifiedTime);
        var types = [_]sqlDB.innerType{ .TEXT, .INTEGER };

        try ContentPathT.get("ID,ModifiedTime", "RelativePath = ?", .{"Content"}, &getValues, &types);
        // std.log.info("{s}", .{buffer});

        if (cc.modified() != @as(i128, @intCast(modifiedTime))) {
            try ContentPathT.update("ModifiedTime,LastSeenTime", "ID = ?", .{ modifiedTime, @as(i64, @truncate(time)), buffer });
            std.log.info("update", .{});
        } else {
            try ContentPathT.update("LastSeenTime", "ID = ?", .{ @as(i64, @truncate(time)), buffer });
        }

        try iterateFolderUpdate(content, "Content", &buffer);
    } else {
        const cc = try content.metadata();
        const time = std.time.nanoTimestamp();
        var buffer = [_]u8{0} ** UUID.len;
        try UUID.createNewUUID(&buffer);

        try ContentPathT.insert(.{
            .ID = &buffer,
            .ParentID = null,
            .RelativePath = @constCast("Content"),
            .FileName = @constCast("Content"),
            .TYPE = @intFromEnum(cc.kind()),
            .FileSize = @intCast(cc.size()),
            .ContentHash = null,
            .ModifiedTime = @as(i64, @truncate(cc.modified())),
            .LastSeenTime = @as(i64, @truncate(time)),
            .FileType = @intFromEnum(FileType.DIR),
        });

        try iterateFolderInsert(content, "Content", &buffer);
    }

    const end = std.time.nanoTimestamp();

    std.log.info("time: {d}", .{@as(f128, @floatFromInt(@divTrunc((end - start), std.time.ns_per_ms)))});
}
