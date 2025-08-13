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
                count += writer.write(std.fmt.comptimePrint("CREATE TRIGGER insertInto{s} AFTER INSERT ON ContentPath FOR EACH ROW WHEN NEW.FileType={d} BEGIN " ++
                    "INSERT INTO ShaderLoadParameter (FileName,ContentHash,RelativePath,FileSize,FileID) VALUES " ++
                    "(NEW.FileName,NEW.ContentHash,NEW.RelativePath,NEW.FileSize,NEW.ID); END;", .{ tableNames[1], field.value })) catch |err| {
                    @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
                };
            },
            .PNG => {
                count += writer.write(std.fmt.comptimePrint("CREATE TRIGGER insertInto{s} AFTER INSERT ON ContentPath FOR EACH ROW WHEN NEW.FileType={d} BEGIN " ++
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

fn iterateFolderUpdate(dir: std.fs.Dir, dirName: []const u8) !void {
    var contentIt = dir.iterate();
    while (contentIt.next() catch |err| blk: {
        std.log.err("{s}", .{@errorName(err)});
        break :blk null;
    }) |tt| {
        var relativePath = [_]u8{0} ** 256;
        std.fmt.bufPrintZ(&relativePath, "{s}{s}{s}", .{ dirName, slash, tt.name });

        var buffer = [_]u8{0} ** 256;
        try UUID.createNewUUID(&buffer);

        switch (tt.kind) {
            .file => {
                continue;
            },
            .directory => {
                var tempDir = try dir.openDir(tt.name, .{ .iterate = true });
                defer tempDir.close();
                try iterateFolderInsert(tempDir, tt.name);
            },
            else => {
                return error.unsupported;
            },
        }
    }
}

fn iterateFolderInsert(dir: std.fs.Dir, dirName: []const u8, parentID: []const u8) !void {
    var contentIt = dir.iterate();
    while (contentIt.next() catch |err| blk: {
        std.log.err("{s}", .{@errorName(err)});
        break :blk null;
    }) |tt| {
        std.log.info("{s}{s}{s}", .{ dirName, slash, tt.name });
        var bufferZ = [_]u8{0} ** 128;
        const nameZ = try std.fmt.bufPrintZ(&bufferZ, "{s}", .{tt.name});

        var relativePathBuffer = [_]u8{0} ** 256;
        _ = try std.fmt.bufPrintZ(&relativePathBuffer, "{s}{s}{s}", .{ dirName, slash, tt.name });

        var buffer = [_]u8{0} ** 256;
        try UUID.createNewUUID(&buffer);

        switch (tt.kind) {
            .file => {
                const index = std.mem.lastIndexOf(u8, tt.name, ".") orelse 0;

                var tempFile = try dir.openFile(tt.name, .{});
                defer tempFile.close();

                var cc = try tempFile.metadata();
                const time = std.time.nanoTimestamp();
                var content = try gpa.alloc(u8, cc.size());
                defer gpa.free(content);
                _ = try tempFile.readAll(content);

                var hashh = hash.blake3HashContent(content[0..cc.size()]);

                ContentPathT.insert(.{
                    .ID = &buffer,
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

                var UUIDBuffer = [_]u8{0} ** UUID.len;
                try UUID.createNewUUID(&UUIDBuffer);

                const time = std.time.nanoTimestamp();

                ContentPathT.insert(.{
                    .ID = &UUIDBuffer,
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

                try iterateFolderInsert(tempDir, tt.name, &UUIDBuffer);
            },
            else => {
                return error.unsupported;
            },
        }
    }
}

// fn insertFileTypeTable(file_type: FileType) !void {
//     switch (file_type) {
//         .SPV => {
//             ShaderLoadParameter.insert(.{.Fil})
//         }
//     }
// }

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
    executeSQL(CreateTriggerContentPathOnInsertInsertIntoSubTable, db.?);
    std.log.info("{s}", .{CreateTriggerContentPathOnInsertInsertIntoSubTable});

    var content = try cwd.openDir("Content", .{ .iterate = true });
    defer content.close();

    if (exist) {
        // try iterateFolderInsert(content, "Content");
    } else {
        const cc = try content.metadata();
        const time = std.time.nanoTimestamp();
        var buffer = [_]u8{0} ** UUID.len;
        try UUID.createNewUUID(&buffer);

        ContentPathT.insert(.{
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
