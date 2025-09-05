const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const std = @import("std");
const builtin = @import("builtin");
const UUID = @import("UUID.zig");
const hash = @import("blake_hash.zig");
const reflect = @import("reflect");
const tables = @import("tables.zig");

const ContentPath = tables.ContentPath;
const ImageLoadParameter = tables.ImageLoadParameter;

const tableNames = [_][]const u8{"ImageLoadParameter"};

const CreateTriggerContentPathOnInsertInsertIntoSubTable = tt: {
    var buffer = [_]u8{0} ** 10240;
    var st = std.io.fixedBufferStream(&buffer);
    var writer = st.writer();
    var count: usize = 0;

    for (@typeInfo(FileType).@"enum".fields) |field| {
        switch (@as(FileType, @enumFromInt(field.value))) {
            // .SPV => {
            //     count += writer.write(std.fmt.comptimePrint(
            //         "CREATE TRIGGER IF NOT EXISTS insertInto{s} AFTER INSERT ON ContentPath " ++
            //             " FOR EACH ROW WHEN NEW.FileType={d} BEGIN INSERT INTO ShaderLoadParameter (FileName,ContentHash,RelativePath,FileSize,FileID) VALUES " ++
            //             "(NEW.FileName,NEW.ContentHash,NEW.RelativePath,NEW.FileSize,NEW.ID) ON CONFLICT(FileName,ContentHash) DO UPDATE SET " ++
            //             "FileID = NEW.ID, FileName = NEW.FileName, ContentHash = NEW.ContentHash, RelativePath = NEW.RelativePath, FileSize = NEW.FileSize; END;",
            //         .{ tableNames[1], field.value },
            //     )) catch |err| {
            //         @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
            //     };
            // },
            .PNG => {
                count += writer.write(std.fmt.comptimePrint(
                    "CREATE TRIGGER IF NOT EXISTS insertInto{s} AFTER INSERT ON ContentPath " ++
                        "FOR EACH ROW WHEN NEW.FileType={d} BEGIN INSERT INTO ImageLoadParameter (FileName,ContentHash,RelativePath,FileID) VALUES " ++
                        "(NEW.FileName,NEW.ContentHash,NEW.RelativePath,NEW.ID) ON CONFLICT(FileName,ContentHash) DO UPDATE SET " ++
                        "FileID = NEW.ID, FileName = NEW.FileName, ContentHash = NEW.ContentHash, RelativePath = NEW.RelativePath; END;",
                    .{ tableNames[0], field.value },
                )) catch |err| {
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

const createTriggerOnUpdateCascadeBetweenContentPathAndTablesOnRelativePath = ct: {
    var buffer = [_]u8{0} ** 10240;
    var st = std.io.fixedBufferStream(&buffer);
    var writer = st.writer();
    var count: usize = 0;

    for (tableNames) |name| {
        count += writer.write(std.fmt.comptimePrint(
            "CREATE TRIGGER IF NOT EXISTS cascadeRelativePath{s} AFTER UPDATE OF RelativePath ON ContentPath " ++
                "FOR EACH ROW WHEN OLD.RelativePath IS NOT NEW.RelativePath BEGIN UPDATE {s} SET RelativePath = NEW.RelativePath WHERE FileID = NEW.ID; END;",
            .{ name, name },
        )) catch |err| {
            @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
        };
    }

    break :ct std.fmt.comptimePrint("{s}", .{buffer});
};

const createUniqueIndexFileNameAndContentHash = cu: {
    var buffer = [_]u8{0} ** 10240;
    var st = std.io.fixedBufferStream(&buffer);
    var writer = st.writer();
    var count: usize = 0;

    for (tableNames) |name| {
        count += writer.write(
            std.fmt.comptimePrint("CREATE UNIQUE INDEX IF NOT EXISTS index{s}FileNameHashTable ON {s}(FileName,ContentHash);", .{ name, name }),
        ) catch |err| {
            @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
        };
    }

    break :cu std.fmt.comptimePrint("{s}", .{buffer});
};

const createTriggerOnDeleteContentPathUpdateTablesRelativePathWhereSameContentHash = cto: {
    var buffer = [_]u8{0} ** 10240;
    var st = std.io.fixedBufferStream(&buffer);
    var writer = st.writer();
    var count: usize = 0;

    for (tableNames) |name| {
        count += writer.write(std.fmt.comptimePrint(
            "CREATE TRIGGER IF NOT EXISTS onDeleteUpdataRelativePath{s} AFTER DELETE ON ContentPath FOR EACH ROW " ++
                "WHEN OLD.ContentHash IS NOT NULL BEGIN UPDATE {s} SET RelativePath = NULL,FileID = NULL WHERE ContentHash = OLD.ContentHash; END;",
            .{ name, name },
        )) catch |err| {
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
        std.log.err("{s}\n{s}", .{ sqlite.sqlite3_errmsg(db), SQL });
    }
}

fn updateLoadParameter(tp: FileType, cc: std.fs.File.Stat, content: []const u8, fileName: []const u8) !void {
    _ = cc;
    _ = content;
    _ = fileName;
    switch (tp) {
        else => {},
    }
}

fn nameToFileType(name: []const u8) FileType {
    return FileTypeHashTable.get(name) orelse FileType.UNKNOWN;
}

fn getDbModifiedTime(comptime where_clause: []const u8, params: anytype) !i64 {
    var modifiedTime: i64 = -1;
    var getValues: [1]*anyopaque = .{@ptrCast(&modifiedTime)};
    var types = [_]sqlDB.innerType{.INTEGER};

    ContentPathT.get("ModifiedTime", where_clause, params, &getValues, &types) catch |err| switch (err) {
        sqlDB.sqliteError.SQLError => return err,
        // 如果没找到，就返回 -1
        sqlDB.sqliteError.StepError, sqlDB.sqliteError.Empty => return -1,
    };
    return modifiedTime;
}

fn processFile(
    dir: std.fs.Dir,
    name: []const u8,
    rPZ: []const u8,
    parentID: []const u8,
    fileModifiedTime: i64,
    pathModifiedTime: i64,
) !void {
    const time: i64 = @truncate(std.time.nanoTimestamp());
    var tempFile = try dir.openFile(name, .{});
    defer tempFile.close();

    const metadata = try tempFile.stat();
    const currentModifiedTime: i64 = @truncate(metadata.mtime);

    if (fileModifiedTime == -1) {
        // 新文件：插入新记录
        var uuidBuffer = [_]u8{0} ** UUID.len;
        try UUID.createNewUUID(&uuidBuffer);
        const index = std.mem.lastIndexOf(u8, name, ".") orelse name.len;
        const fType = nameToFileType(name[index..]);
        // try ContentPathInsertFile(&uuidBuffer, parentID.ptr, rPZ.ptr, name, time, fType, dir);

        var content = try gpa.alloc(u8, metadata.size);
        defer gpa.free(content);
        _ = try tempFile.readAll(content);

        var hashh = hash.blake3HashContent(content[0..metadata.size]);

        try ContentPathT.insert(.{
            .ID = @constCast(&uuidBuffer),
            .ParentID = @constCast(parentID.ptr),
            .RelativePath = @constCast(rPZ.ptr),
            .FileName = @constCast(name.ptr),
            .TYPE = @intFromEnum(metadata.kind),
            .FileSize = @intCast(metadata.size),
            .ContentHash = sqlDB.BLOB{ .data = &hashh, .len = hash.blake3.BLAKE3_OUT_LEN },
            .ModifiedTime = @as(i64, @truncate(metadata.mtime)),
            .LastSeenTime = time,
            .FileType = @intFromEnum(fType),
        });

        try updateLoadParameter(fType, metadata, content, name);
    } else {
        const isModified = (currentModifiedTime != fileModifiedTime);
        if (pathModifiedTime == -1) {
            // 文件被移动：更新路径和父ID
            if (isModified) {
                const content = try gpa.alloc(u8, metadata.size);
                defer gpa.free(content);
                _ = try tempFile.readAll(content);

                var contentHash = hash.blake3HashContent(content);
                // const contentHash = try hashFileContent(&tempFile, metadata.size());
                try ContentPathT.update(
                    "RelativePath,ParentID,ModifiedTime,LastSeenTime,ContentHash",
                    "FileName = ?",
                    .{ rPZ, parentID, currentModifiedTime, time, sqlDB.BLOB{ .data = &contentHash, .len = contentHash.len }, name },
                );

                const index = std.mem.lastIndexOf(u8, name, ".") orelse name.len;
                const fType = nameToFileType(name[index..]);

                try updateLoadParameter(fType, metadata, content, name);
            } else {
                try ContentPathT.update("RelativePath,ParentID,LastSeenTime", "FileName = ?", .{ rPZ, parentID, time, name });
            }
        } else {
            // 已存在的文件：只更新时间和内容哈希（如果需要）
            if (isModified) {
                const content = try gpa.alloc(u8, metadata.size);
                defer gpa.free(content);
                _ = try tempFile.readAll(content);

                var contentHash = hash.blake3HashContent(content);

                try ContentPathT.update(
                    "ModifiedTime,LastSeenTime,ContentHash",
                    "FileName = ?",
                    .{ currentModifiedTime, time, sqlDB.BLOB{ .data = &contentHash, .len = contentHash.len }, name },
                );

                const index = std.mem.lastIndexOf(u8, name, ".") orelse name.len;
                const fType = nameToFileType(name[index..]);

                try updateLoadParameter(fType, metadata, content, name);
            } else {
                try ContentPathT.update("LastSeenTime", "FileName = ?", .{ time, name });
            }
        }
    }
}

// 辅助函数：计算文件哈希
fn hashFileContent(file: *std.fs.File, size: u64) !sqlDB.BLOB {
    const content = try gpa.alloc(u8, size);
    defer gpa.free(content);
    _ = try file.readAll(content);
    var contentHash = hash.blake3HashContent(content);
    return sqlDB.BLOB{ .data = &contentHash, .len = hash.blake3.BLAKE3_OUT_LEN };
}

fn processDirectory(
    dir: std.fs.Dir,
    name: []const u8,
    rPZ: []const u8,
    parentID: []const u8,
    fileModifiedTime: i64,
    pathModifiedTime: i64,
) anyerror!void {
    const time: i64 = @truncate(std.time.nanoTimestamp());
    var tempDir = try dir.openDir(name, .{ .iterate = true });
    defer tempDir.close();

    const metadata = try tempDir.stat();
    const currentModifiedTime: i64 = @truncate(metadata.mtime);
    var currentID: [UUID.len]u8 = undefined;

    if (fileModifiedTime == -1) {
        // 新目录：插入记录并获取新ID
        try UUID.createNewUUID(&currentID);
        try ContentPathT.insert(.{
            .ID = &currentID,
            .ParentID = @constCast(parentID.ptr),
            .RelativePath = @constCast(rPZ.ptr),
            .FileName = @constCast(name.ptr),
            .TYPE = @intFromEnum(metadata.kind),
            .FileSize = @intCast(metadata.size),
            .ContentHash = null,
            .ModifiedTime = currentModifiedTime,
            .LastSeenTime = time,
            .FileType = @intFromEnum(FileType.DIR),
        });
    } else {
        const isModified = (currentModifiedTime != fileModifiedTime);
        if (pathModifiedTime == -1) {
            // 目录被移动：更新路径和父ID
            if (isModified) {
                try ContentPathT.update("RelativePath,ParentID,ModifiedTime,LastSeenTime", "FileName = ?", .{ rPZ, parentID, currentModifiedTime, time, name });
            } else {
                try ContentPathT.update("RelativePath,ParentID,LastSeenTime", "FileName = ?", .{ rPZ, parentID, time, name });
            }
        } else {
            // 已存在的目录：更新时间
            if (isModified) {
                try ContentPathT.update("ModifiedTime,LastSeenTime", "FileName = ?", .{ currentModifiedTime, time, name });
            } else {
                try ContentPathT.update("LastSeenTime", "FileName = ?", .{ time, name });
            }
        }
        // 对于已存在的目录，需要获取其ID以进行递归
        var ptrs = [_]*anyopaque{&currentID};
        var types = [_]sqlDB.innerType{.TEXT};
        try ContentPathT.get("ID", "RelativePath = ?", .{rPZ}, &ptrs, &types);
    }

    // 对子目录进行递归
    try iterateFolderUpdate(tempDir, rPZ, &currentID);
}

fn iterateFolderUpdate(dir: std.fs.Dir, dirName: []const u8, parentID: []const u8) !void {
    var contentIt = dir.iterate();
    while (try contentIt.next()) |entry| {
        var relativePathBuffer = [_]u8{0} ** 256;
        const rPZ = try std.fmt.bufPrintZ(&relativePathBuffer, "{s}{s}{s}", .{ dirName, slash, entry.name });

        var bufferZ = [_]u8{0} ** 128;
        const nameZ = try std.fmt.bufPrintZ(&bufferZ, "{s}", .{entry.name});

        // 提前获取两种可能存在的时间戳
        const fileModifiedTime = try getDbModifiedTime("FileName = ?", .{nameZ});
        const pathModifiedTime = try getDbModifiedTime("RelativePath = ?", .{rPZ});

        switch (entry.kind) {
            .file => try processFile(dir, nameZ, rPZ, parentID, fileModifiedTime, pathModifiedTime),
            .directory => try processDirectory(dir, nameZ, rPZ, parentID, fileModifiedTime, pathModifiedTime),
            else => {},
        }
    }
}

var ContentPathT: ContentPath = undefined;
var ImageLoadParameterT: ImageLoadParameter = undefined;

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
    std.log.info("exe: {s}", .{rootExe});

    var root: [256:0]u8 = undefined;

    const realPath = it.next();
    @memset(root[0..root.len], 0);

    if (realPath) |rootPath| {
        std.mem.copyForwards(u8, &root, rootPath);
    } else {
        std.mem.copyForwards(u8, &root, rootExe);
    }

    const index = std.mem.lastIndexOf(u8, &root, slash) orelse 0;
    @memset(root[index..root.len], 0);

    std.log.info("path: {s}", .{root});

    var cwd = try std.fs.openDirAbsolute(&root, .{});
    try cwd.setAsCwd();

    var db: ?*sqlite.sqlite3 = null;
    if (sqlite.sqlite3_open("Content.db", @ptrCast(&db)) != sqlite.SQLITE_OK) return error.SQLError;
    defer _ = sqlite.sqlite3_close(db);

    ContentPathT = ContentPath.init(db.?);
    const exist = ContentPathT.exist();
    try ContentPathT.createTable();
    ImageLoadParameterT = ImageLoadParameter.init(db.?);
    try ImageLoadParameterT.createTable();
    executeSQL(createUniqueIndexFileNameAndContentHash, db.?);
    executeSQL(createTriggerOnInsertContentPathCheckContentHash, db.?);
    executeSQL(CreateTriggerContentPathOnInsertInsertIntoSubTable, db.?);
    executeSQL(createTriggerOnUpdateCascadeBetweenContentPathAndTablesOnContentHash, db.?);
    executeSQL(createTriggerOnDeleteContentPathUpdateTablesRelativePathWhereSameContentHash, db.?);
    executeSQL(createTriggerOnUpdateCascadeBetweenContentPathAndTablesOnRelativePath, db.?);

    var content = try cwd.openDir("Content", .{ .iterate = true });
    defer content.close();

    var buffer = [_]u8{0} ** UUID.len;
    const time: i64 = @truncate(std.time.nanoTimestamp());

    if (exist) {
        const cc = try content.stat();
        var modifiedTime: i64 = 0;

        var getValues: [2]*anyopaque = undefined;
        getValues[0] = @ptrCast(&buffer);
        getValues[1] = @ptrCast(&modifiedTime);
        var types = [_]sqlDB.innerType{ .TEXT, .INTEGER };

        try ContentPathT.get("ID,ModifiedTime", "RelativePath = ?", .{"Content"}, &getValues, &types);
        // std.log.info("{s}", .{buffer});

        if (cc.mtime != @as(i128, @intCast(modifiedTime))) {
            try ContentPathT.update("ModifiedTime,LastSeenTime", "ID = ?", .{ modifiedTime, time, buffer });
            std.log.info("update", .{});
        } else {
            try ContentPathT.update("LastSeenTime", "ID = ?", .{ time, buffer });
        }
    } else {
        const cc = try content.stat();
        try UUID.createNewUUID(&buffer);

        try ContentPathT.insert(.{
            .ID = &buffer,
            .ParentID = null,
            .RelativePath = @constCast("Content"),
            .FileName = @constCast("Content"),
            .TYPE = @intFromEnum(cc.kind),
            .FileSize = @intCast(cc.size),
            .ContentHash = null,
            .ModifiedTime = @as(i64, @truncate(cc.mtime)),
            .LastSeenTime = @as(i64, @truncate(time)),
            .FileType = @intFromEnum(FileType.DIR),
        });
    }

    try iterateFolderUpdate(content, "Content", &buffer);

    try ContentPathT.delete("LastSeenTime < ?", .{time});

    const end = std.time.nanoTimestamp();

    std.log.info("time: {d}", .{@as(f128, @floatFromInt(@divTrunc((end - start), std.time.ns_per_ms)))});
}
