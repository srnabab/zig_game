const std = @import("std");
const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;

const tables = @import("tables");
const Types = @import("types");

pub const iterateFolder = @import("iterateFolder.zig");
pub const judgeFileType = iterateFolder.judgeFileType;
pub const UUID = iterateFolder.UUID;
pub const innerType = sqlDB.innerType;

const assert = std.debug.assert;

const ContentPath = tables.ContentPath;
const ImageLoadParameter = tables.ImageLoadParameter;
const ModelLoadParameter = tables.ModelLoadParameter;
const ShaderPipelineGraphNode = tables.ShaderPipelineGraphNode;
const ShaderPipelineGraphEdge = tables.ShaderPipelineGraphEdge;

pub const FileType = Types.FileType;
pub const NodeType = Types.NodeType;

const tableNames = [_][]const u8{ "ImageLoadParameter", "ModelLoadParameter" };
const CreateTriggerContentPathOnInsertInsertIntoSubTable = tt: {
    var buffer = [_]u8{0} ** 10240;
    var writer = std.Io.Writer.fixed(&buffer);

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
                        "FOR EACH ROW WHEN NEW.FileType={d} BEGIN INSERT INTO ImageLoadParameter (ID,FileName,ContentHash,RelativePath,FileUUID) VALUES " ++
                        "(NEW.ID,NEW.FileName,NEW.ContentHash,NEW.RelativePath,NEW.UUID) ON CONFLICT(FileName,ContentHash) DO UPDATE SET " ++
                        "ID = NEW.ID, FileUUID = NEW.UUID, FileName = NEW.FileName, ContentHash = NEW.ContentHash, RelativePath = NEW.RelativePath; END;",
                    .{ tableNames[0], field.value },
                )) catch |err| {
                    @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
                };
            },
            .VTX => {
                count += writer.write(std.fmt.comptimePrint(
                    "CREATE TRIGGER IF NOT EXISTS insertInto{s} AFTER INSERT ON ContentPath " ++
                        "FOR EACH ROW WHEN NEW.FileType={d} BEGIN INSERT INTO ModelLoadParameter (ID,FileName,ContentHash,RelativePath,FileUUID) VALUES " ++
                        "(NEW.ID,NEW.FileName,NEW.ContentHash,NEW.RelativePath,NEW.UUID) ON CONFLICT(FileName,ContentHash) DO UPDATE SET " ++
                        "ID = NEW.ID, FileUUID = NEW.UUID, FileName = NEW.FileName, ContentHash = NEW.ContentHash, RelativePath = NEW.RelativePath; END;",
                    .{ tableNames[1], field.value },
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

const createUniqueIndexFileNameAndContentHash = cu: {
    var buffer = [_]u8{0} ** 10240;
    var writer = std.Io.Writer.fixed(&buffer);
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
    var writer = std.Io.Writer.fixed(&buffer);
    var count: usize = 0;

    for (tableNames) |name| {
        count += writer.write(std.fmt.comptimePrint(
            "CREATE TRIGGER IF NOT EXISTS onDeleteUpdataRelativePath{s} AFTER DELETE ON ContentPath FOR EACH ROW " ++
                "WHEN OLD.ContentHash IS NOT NULL BEGIN UPDATE {s} SET RelativePath = NULL,FileUUID = NULL WHERE ContentHash = OLD.ContentHash; END;",
            .{ name, name },
        )) catch |err| {
            @compileError(std.fmt.comptimePrint("{s}", .{@errorName(err)}));
        };
    }

    break :cto std.fmt.comptimePrint("{s}", .{buffer});
};

const createTriggerOnInsertContentPathCheckContentHash =
    "CREATE TRIGGER IF NOT EXISTS onInsertUpdateContentPath BEFORE INSERT ON ContentPath FOR EACH ROW BEGIN " ++
    "DELETE FROM ContentPath WHERE ContentHash = NEW.ContentHash; END;";

fn getTableIndexForFileType(ft: FileType) ?u32 {
    return switch (ft) {
        .PNG => 0,
        .VTX => 1,
        else => null,
    };
}

const createTriggerOnUpdateContentPathUpdateOrInsertTables = ct: {
    var buffer = [_]u8{0} ** 20480;
    var writer = std.Io.Writer.fixed(&buffer);
    var count: usize = 0;

    for (tableNames, 0..) |tableName, idx| {
        var id_list_buffer = [_]u8{0} ** 20480;
        var id_list_writer = std.Io.Writer.fixed(&id_list_buffer);
        var first = true;

        for (@typeInfo(FileType).@"enum".fields) |field| {
            const val = @as(FileType, @enumFromInt(field.value));
            if (getTableIndexForFileType(val)) |i| {
                if (i == idx) {
                    if (!first) _ = id_list_writer.write(", ") catch unreachable;
                    _ = id_list_writer.write(std.fmt.comptimePrint("{d}", .{field.value})) catch unreachable;
                    first = false;
                }
            }
        }

        const id_list = id_list_writer.buffered();
        if (id_list.len == 0) continue;

        count += writer.write(std.fmt.comptimePrint(
            "CREATE TRIGGER IF NOT EXISTS onUpdateContentPathUpdateOrInsertTables{s} AFTER UPDATE OF " ++
                "ID, FileName, ContentHash, RelativePath, FileType ON ContentPath FOR EACH ROW " ++
                "WHEN NEW.FileType IN ({s}) BEGIN INSERT INTO {s} (ID,FileName,ContentHash,RelativePath) VALUES " ++
                "(NEW.ID,NEW.FileName,NEW.ContentHash,NEW.RelativePath) ON CONFLICT(FileName,ContentHash) DO UPDATE SET " ++
                "ID = NEW.ID, RelativePath = NEW.RelativePath " ++
                "WHERE FileUUID = NEW.UUID; END;",
            .{ tableName, id_list, tableName },
        )) catch unreachable;

        count += writer.write(std.fmt.comptimePrint(
            "CREATE TRIGGER IF NOT EXISTS insertInto{s} AFTER INSERT ON ContentPath " ++
                "FOR EACH ROW WHEN NEW.FileType IN ({s}) BEGIN INSERT INTO {s} (ID,FileName,ContentHash,RelativePath,FileUUID) VALUES " ++
                "(NEW.ID,NEW.FileName,NEW.ContentHash,NEW.RelativePath,NEW.UUID) ON CONFLICT(FileName,ContentHash) DO UPDATE SET " ++
                "ID = NEW.ID, FileUUID = NEW.UUID, FileName = NEW.FileName, ContentHash = NEW.ContentHash, RelativePath = NEW.RelativePath; END;",
            .{ tableName, id_list, tableName },
        )) catch unreachable;
    }

    break :ct std.fmt.comptimePrint("{s}", .{buffer});
};

pub const AutoCommitter = struct {
    last_activity: i64,
    db_conn: *Self,
    io: std.Io,
    is_active: bool,
    unsaved: bool = false,
    wait: i64 = 2000,

    pub fn init(db: *Self, io: std.Io, wait: i64) AutoCommitter {
        return .{
            .last_activity = std.Io.Timestamp.now(io, .real).toMilliseconds(),
            .db_conn = db,
            .io = io,
            .is_active = false,
            .wait = wait,
        };
    }

    pub fn activate(self: *AutoCommitter) void {
        self.is_active = true;
        self.poke();
        self.db_conn.beginTransaction();
    }

    pub fn poke(self: *AutoCommitter) void {
        self.last_activity = std.Io.Timestamp.now(self.io, .real).toMilliseconds();
        // std.log.debug("poke", .{});
    }

    // 后台异步监控任务
    pub fn runMonitor(self: *AutoCommitter) !void {
        errdefer self.db_conn.rollback();
        while (self.is_active) {
            const now = std.Io.Timestamp.now(self.io, .real).toMilliseconds();
            const diff = now - self.last_activity;

            if (diff >= self.wait) {
                // std.log.debug("run commit", .{});
                self.db_conn.commit();
                self.is_active = false; // 提交后关闭监控
                break;
            } else {
                // std.log.debug("hang", .{});
                try self.io.sleep(.fromMilliseconds(self.wait - diff), .real);
            }
        }
    }
};

const Self = @This();

db: ?*sqlite.sqlite3 = null,
ContentPathT: ContentPath = undefined,
ImageLoadParameterT: ImageLoadParameter = undefined,
ModelLoadParameterT: ModelLoadParameter = undefined,
ShaderPipelineGraphNodeT: ShaderPipelineGraphNode = undefined,
ShaderPipelineGraphEdgeT: ShaderPipelineGraphEdge = undefined,
contentPathExist: bool = false,
dbPath: []const u8,

pub fn init(allocator: std.mem.Allocator, dbPath: []const u8) !*Self {
    const self = try allocator.create(Self);

    var disk_db: ?*sqlite.sqlite3 = null;
    var backup: ?*sqlite.sqlite3_backup = null;
    var res = sqlite.sqlite3_open(dbPath.ptr, @ptrCast(&disk_db));
    defer _ = sqlite.sqlite3_close(disk_db);
    assert(res == sqlite.SQLITE_OK);

    res = sqlite.sqlite3_open(":memory:", @ptrCast(&self.db));
    assert(res == sqlite.SQLITE_OK);

    backup = sqlite.sqlite3_backup_init(self.db, "main", disk_db, "main");
    assert(backup != null);

    res = sqlite.sqlite3_backup_step(backup, -1);
    _ = sqlite.sqlite3_backup_finish(backup);
    assert(res == sqlite.SQLITE_DONE);

    self.ContentPathT = ContentPath.init(self.db.?);
    self.contentPathExist = self.ContentPathT.exist();
    try self.ContentPathT.createTable();
    self.ImageLoadParameterT = ImageLoadParameter.init(self.db.?);
    try self.ImageLoadParameterT.createTable();
    self.ModelLoadParameterT = ModelLoadParameter.init(self.db.?);
    try self.ModelLoadParameterT.createTable();
    executeSQL(createUniqueIndexFileNameAndContentHash, self.db.?);
    executeSQL(createTriggerOnInsertContentPathCheckContentHash, self.db.?);
    executeSQL(createTriggerOnDeleteContentPathUpdateTablesRelativePathWhereSameContentHash, self.db.?);
    executeSQL(createTriggerOnUpdateContentPathUpdateOrInsertTables, self.db.?);

    self.ShaderPipelineGraphNodeT = ShaderPipelineGraphNode.init(self.db.?);
    try self.ShaderPipelineGraphNodeT.createTable();
    self.ShaderPipelineGraphEdgeT = ShaderPipelineGraphEdge.init(self.db.?);
    try self.ShaderPipelineGraphEdgeT.createTable();

    self.dbPath = dbPath;

    return self;
}

pub fn beginTransaction(self: *Self) void {
    // std.log.debug("begin transaction", .{});
    _ = sqlite.sqlite3_exec(self.db, "BEGIN TRANSACTION", null, null, null);
}

pub fn rollback(self: *Self) void {
    // std.log.debug("rollback", .{});
    _ = sqlite.sqlite3_exec(self.db, "ROLLBACK;", null, null, null);
}

pub fn commit(self: *Self) void {
    // std.log.debug("commit", .{});
    _ = sqlite.sqlite3_exec(self.db, "COMMIT;", null, null, null);
}

pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
    self.saveToDrive();

    _ = sqlite.sqlite3_close(self.db.?);

    allocator.destroy(self);

    std.log.debug("database deinit", .{});
}

fn executeSQL(SQL: []const u8, db_: *sqlite.sqlite3) void {
    const res = sqlite.sqlite3_exec(db_, @ptrCast(SQL.ptr), null, null, null);

    if (res != sqlite.SQLITE_OK) {
        std.log.err("{s}\n{s}", .{ sqlite.sqlite3_errmsg(db_), SQL });
    }
}

pub fn processFolder(self: *Self, content: std.Io.Dir, io: std.Io, allocator: std.mem.Allocator) !void {
    self.beginTransaction();
    errdefer self.rollback();
    defer self.commit();
    try iterateFolder.processContentFolder(
        content,
        io,
        .{
            .db = self.db,
            .ContentPath = self.ContentPathT,
            .ImageLoadParameter = self.ImageLoadParameterT,
            .ModelLoadParameter = self.ModelLoadParameterT,
            .ShaderPipelineGraphEdgeT = self.ShaderPipelineGraphEdgeT,
            .ShaderPipelineGraphNodeT = self.ShaderPipelineGraphNodeT,
            .contentPathExist = self.contentPathExist,
        },
        allocator,
    );
}

pub fn saveToDrive(self: *Self) void {
    var disk_db: ?*sqlite.sqlite3 = null;
    var backup: ?*sqlite.sqlite3_backup = null;

    var res = sqlite.sqlite3_open(self.dbPath.ptr, @ptrCast(&disk_db));
    defer _ = sqlite.sqlite3_close(disk_db);
    if (res != sqlite.SQLITE_OK) {
        std.log.err("\n{s}\n", .{sqlite.sqlite3_errmsg(disk_db)});
    }

    backup = sqlite.sqlite3_backup_init(disk_db, "main", self.db, "main");
    if (backup == null) {
        std.log.err("\n{s}\n", .{sqlite.sqlite3_errmsg(disk_db)});
    }

    res = sqlite.sqlite3_backup_step(backup, -1);
    defer _ = sqlite.sqlite3_backup_finish(backup);
    if (res != sqlite.SQLITE_DONE) {
        std.log.err("\n{s}\n", .{sqlite.sqlite3_errmsg(disk_db)});
    }
}
