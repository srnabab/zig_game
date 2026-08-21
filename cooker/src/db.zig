const std = @import("std");
const Io = std.Io;

const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;

const tables = @import("tables");
const Types = @import("types");
pub const resourceProcess = @import("resourceProcess");

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

pub const FileType = resourceProcess.ProcessType;
pub const NodeType = Types.NodeType;

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

customTablePack: resourceProcess.CustomTablePack = undefined,
// ImageLoadParameterT: ImageLoadParameter = undefined,
// ModelLoadParameterT: ModelLoadParameter = undefined,

ShaderPipelineGraphNodeT: ShaderPipelineGraphNode = undefined,
ShaderPipelineGraphEdgeT: ShaderPipelineGraphEdge = undefined,
contentPathExist: bool = false,
dbPath: []const u8,

fn log_callback(_: *anyopaque, iErrCode: c_int, zMsg: [*c]u8) callconv(.c) void {
    std.log.debug("[SQLite LOG {d}]: {s}\n", .{ iErrCode, zMsg });
}

pub fn init(io: Io, allocator: std.mem.Allocator, content: Io.Dir, dbPath: []const u8) !*Self {
    const self = try allocator.create(Self);

    var disk_db: ?*sqlite.sqlite3 = null;
    var backup: ?*sqlite.sqlite3_backup = null;
    var res = sqlite.sqlite3_open(dbPath.ptr, @ptrCast(&disk_db));
    defer _ = sqlite.sqlite3_close(disk_db);
    try sqlDB.checkRes(disk_db.?, res);

    _ = sqlite.sqlite3_config(sqlite.SQLITE_CONFIG_LOG, log_callback);
    res = sqlite.sqlite3_open(":memory:", @ptrCast(&self.db));
    assert(res == sqlite.SQLITE_OK);

    backup = sqlite.sqlite3_backup_init(self.db, "main", disk_db, "main");
    assert(backup != null);

    res = sqlite.sqlite3_backup_step(backup, -1);
    _ = sqlite.sqlite3_backup_finish(backup);
    assert(res == sqlite.SQLITE_DONE);

    _ = sqlite.sqlite3_extended_result_codes(self.db, 1);

    self.ContentPathT = .init(self.db.?);
    self.contentPathExist = self.ContentPathT.exist();
    try self.ContentPathT.createTable();

    const customInfo = @typeInfo(resourceProcess.CustomTablePack);
    inline for (customInfo.@"struct".fields) |value| {
        @field(self.customTablePack, value.name) = .init(self.db.?);
        try @field(self.customTablePack, value.name).createTable();
    }
    // self.ImageLoadParameterT = ImageLoadParameter.init(self.db.?);
    // try self.ImageLoadParameterT.createTable();
    // self.ModelLoadParameterT = ModelLoadParameter.init(self.db.?);
    // try self.ModelLoadParameterT.createTable();

    // executeSQL(createUniqueIndexFileNameAndContentHash, self.db.?);
    // executeSQL(createTriggerOnInsertContentPathCheckContentHash, self.db.?);
    // executeSQL(createTriggerOnDeleteContentPathUpdateTablesRelativePathWhereSameContentHash, self.db.?);
    // executeSQL(createTriggerOnUpdateContentPathUpdateOrInsertTables, self.db.?);

    inline for (resourceProcess.Triggers) |value| {
        executeSQL(value, self.db.?);
    }

    self.ShaderPipelineGraphNodeT = ShaderPipelineGraphNode.init(self.db.?);
    try self.ShaderPipelineGraphNodeT.createTable();
    self.ShaderPipelineGraphEdgeT = ShaderPipelineGraphEdge.init(self.db.?);
    try self.ShaderPipelineGraphEdgeT.createTable();

    self.dbPath = dbPath;

    try iterateFolder.init(.{
        .contentPathExist = true,
        .ContentPathT = self.ContentPathT,
        .db = self.db,
        .customTablePack = self.customTablePack,
        .ShaderPipelineGraphEdgeT = self.ShaderPipelineGraphEdgeT,
        .ShaderPipelineGraphNodeT = self.ShaderPipelineGraphNodeT,
    }, io, allocator, content);

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
            .ContentPathT = self.ContentPathT,
            .ImageLoadParameterT = self.ImageLoadParameterT,
            .ModelLoadParameterT = self.ModelLoadParameterT,
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
