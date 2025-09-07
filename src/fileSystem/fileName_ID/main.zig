const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const tables = @import("tables");
const std = @import("std");
const builtin = @import("builtin");

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

const ContentPath = tables.ContentPath;

var ContentPathT: ContentPath = undefined;

const kv = struct {
    fileName: [128]u8,
    ID: i64,
};

var gpa: std.mem.Allocator = undefined;
var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
pub fn main() !void {
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

    var types = [_]sqlDB.innerType{ .INTEGER, .TEXT };
    var kvs: [1000]kv = undefined;
    @memset(kvs[0..kvs.len], kv{ .ID = -1, .fileName = std.mem.zeroes([128]u8) });
    var ptrs: [1000][]*anyopaque = undefined;
    var arena = std.heap.ArenaAllocator.init(gpa);

    for (0..kvs.len) |i| {
        ptrs[i] = try arena.allocator().alloc(*anyopaque, 2);
        errdefer arena.deinit();
        ptrs[i][0] = @ptrCast(&kvs[i].ID);
        ptrs[i][1] = @ptrCast(&kvs[i].fileName);
    }
    defer arena.deinit();

    try ContentPathT.gets("ID,FileName", null, null, .{}, ptrs[0..kvs.len], &types);

    for (kvs) |value| {
        if (value.ID == -1) break;
        std.log.debug("{s} {d}", .{ value.fileName, value.ID });
    }
}
