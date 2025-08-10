const sqlite = @cImport(@cInclude("sqlite3/sqlite3.h"));
const std = @import("std");

const sqliteError = error{SQLError};

const innerType = enum {
    INTEGER,
    TEXT,
    BLOB,
};

fn stringToType(comptime str: []const u8) innerType {
    if (std.mem.eql(u8, str, "INTEGER")) {
        return innerType.INTEGER;
    } else if (std.mem.eql(u8, str, "TEXT")) {
        return innerType.TEXT;
    } else if (std.mem.eql(u8, str, "BLOB")) {
        return innerType.BLOB;
    } else {
        @compileError(std.fmt.comptimePrint("unsupported type {s}", .{str}));
    }
}

const param = struct { paramName: []const u8, paramType: innerType };

const ParamsPack = struct {
    ps: [64]param,
    count: u32,
};
const BLOB = struct {
    data: [*]const u8,
    len: c_int,
};

fn getParamFromSQL(comptime SQL: []const u8, comptime skipID: bool) ParamsPack {
    if (SQL.len == 0) {
        @compileError("invalid SQL");
    }
    // const FOREIGN = "FOREIGN";
    var params: [64]param = undefined;
    var paramsCount: u32 = 0;

    var space = std.mem.splitAny(u8, SQL, "()");
    _ = space.next();
    const sen = space.next();
    if (sen == null) {
        @compileError("invalid SQL");
    }

    // @compileLog(std.fmt.comptimePrint("{s}", .{sen.?}));

    var sen_space = std.mem.splitSequence(u8, sen.?, ",");
    var sen_space_space: [64]std.mem.SplitIterator(u8, .sequence) = undefined;
    var sen_space_space_count: u32 = 0;
    var skip = skipID;
    var addSkip = false;

    while (sen_space.next()) |bb| {
        // @compileLog(std.fmt.comptimePrint("{s}", .{bb}));

        sen_space_space[sen_space_space_count] = std.mem.splitSequence(u8, bb, " ");

        var count: u32 = 0;
        while (sen_space_space[sen_space_space_count].next()) |bbb| {
            @setEvalBranchQuota(2000);
            if (bbb.len == 0) continue;

            if (paramsCount == 0) {
                if (skip) {
                    _ = sen_space_space[sen_space_space_count].next();
                    const pri = sen_space_space[sen_space_space_count].next().?;

                    if (std.mem.eql(u8, pri, "PRIMARY")) {
                        // @compileLog(std.fmt.comptimePrint("{s}", .{pri}));
                        skip = false;
                        addSkip = true;
                        break;
                    }
                }
            }

            if (count == 0) {
                if (std.mem.eql(u8, bbb, "FOREIGN")) {
                    addSkip = true;
                    break;
                }
                params[paramsCount].paramName = bbb;
            } else if (count == 1) {
                params[paramsCount].paramType = stringToType(bbb);
            }
            count += 1;

            if (count == 2) break;
        }
        // @compileLog(std.fmt.comptimePrint("{s} {s}", .{ params[paramsCount].paramName, params[paramsCount].paramType }));
        if (addSkip) {
            addSkip = false;
        } else {
            paramsCount += 1;
        }
        sen_space_space_count += 1;
    }

    return ParamsPack{ .ps = params, .count = paramsCount };
}

// std.builtin.Type.Struct;
fn createInsertStruct(comptime pack: ParamsPack) type {
    var fileds: [64]std.builtin.Type.StructField = undefined;
    var fieldsCount: u32 = 0;

    for (pack.ps[0..pack.count]) |para| {
        fileds[fieldsCount].name = std.fmt.comptimePrint("{s}", .{para.paramName});
        // @compileLog(std.fmt.comptimePrint("{s}", .{fileds[fieldsCount].name}));
        fileds[fieldsCount].type = ty: {
            switch (para.paramType) {
                .BLOB => {
                    break :ty BLOB;
                },
                .INTEGER => {
                    break :ty i64;
                },
                .TEXT => {
                    break :ty [*]const u8;
                },
            }
        };
        fileds[fieldsCount].default_value_ptr = null;
        fileds[fieldsCount].is_comptime = false;
        fileds[fieldsCount].alignment = 0;
        fieldsCount += 1;
        // @compileLog(std.fmt.comptimePrint("count {d}", .{fieldsCount}));
    }

    return @Type(.{
        .@"struct" = .{
            .layout = .auto,
            .backing_integer = null,
            .fields = fileds[0..fieldsCount],
            .decls = &.{},
            .is_tuple = false,
        },
    });
}

pub fn Table(comptime SQL: []const u8, comptime tableName: []const u8, comptime skipID: bool) type {
    return struct {
        const Self = @This();
        const CreateSQL = SQL;

        const Params = getParamFromSQL(SQL, skipID);
        const insertStruct: type = createInsertStruct(Params);

        db: *sqlite.sqlite3,
        tableName: []const u8 = tableName,

        pub fn init(db: *sqlite.sqlite3) Self {
            return Self{ .db = db };
        }

        pub fn createTable(self: *Self) sqliteError!void {
            if (sqlite.sqlite3_exec(self.db, @ptrCast(SQL.ptr), null, null, null) != sqlite.SQLITE_OK) {
                std.log.err("create table {s} failed", .{self.tableName});
                return sqliteError.SQLError;
            }
        }

        pub fn exist(self: *Self) bool {
            const expr = std.fmt.comptimePrint("SELECT name FROM sqlite_master WHERE TYPE='table' AND name='{s}';", .{tableName});
            var stmt: ?*sqlite.sqlite3_stmt = null;

            prepare_v2(self.db, @ptrCast(expr), -1, @ptrCast(&stmt), null) catch |err| {
                std.log.err("{s}", .{@errorName(err)});
            };
            defer _ = sqlite.sqlite3_finalize(stmt);

            if (sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) return true;

            return false;
        }

        pub fn insert(self: *Self, T: insertStruct) !void {
            const ssql = comptime blk: {
                var buffer = [_]u8{0} ** 256;
                var bufferq = [_]u8{0} ** 64;
                var p1 = std.io.fixedBufferStream(buffer[0..buffer.len]);
                var pq = std.io.fixedBufferStream(bufferq[0..bufferq.len]);
                var writer = p1.writer();
                var writerq = pq.writer();
                var writeCount: usize = 0;
                var writeqCount: usize = 0;

                for (0..Params.count) |i| {
                    writeCount += try writer.write(Params.ps[i].paramName);
                    writeqCount += try writerq.write("?");
                    if (i != Params.count - 1) {
                        writeCount += try writer.write(", ");
                        writeqCount += try writerq.write(", ");
                    }
                }

                break :blk std.fmt.comptimePrint("INSERT INTO {s} ({s}) VALUES ({s});", .{
                    tableName,
                    buffer[0..writeCount],
                    bufferq[0..writeqCount],
                });
            };
            std.log.warn("{s}", .{ssql});

            var stmt: ?*sqlite.sqlite3_stmt = null;
            try prepare_v2(self.db, @ptrCast(ssql), -1, @ptrCast(&stmt), null);
            defer _ = sqlite.sqlite3_finalize(stmt);

            inline for (Params.ps[0..Params.count], 0..Params.count) |pp, i| {
                std.log.info("cast c_int {d}", .{@as(c_int, @intCast(i))});
                switch (pp.paramType) {
                    .INTEGER => {
                        _ = sqlite.sqlite3_bind_int64(stmt, @intCast(i + 1), @field(T, pp.paramName));
                    },
                    .BLOB => {
                        _ = sqlite.sqlite3_bind_blob(stmt, @intCast(i + 1), @field(T, pp.paramName).data, @field(T, pp.paramName).len, sqlite.SQLITE_STATIC);
                    },
                    .TEXT => {
                        const res = sqlite.sqlite3_bind_text(stmt, @intCast(i + 1), @field(T, pp.paramName), -1, sqlite.SQLITE_STATIC);
                        if (res != sqlite.SQLITE_OK) {
                            std.log.err("text {s}", .{sqlite.sqlite3_errmsg(self.db)});
                        }
                    },
                }
                // _ = i;
            }
            // _ = T;

            if (sqlite.sqlite3_step(stmt) != sqlite.SQLITE_DONE) {
                std.log.err("{s}", .{sqlite.sqlite3_errmsg(self.db)});
                return sqliteError.SQLError;
            }
        }

        fn prepare_v2(db: ?*sqlite.sqlite3, zSql: [*c]const u8, nByte: c_int, ppStmt: [*c]?*sqlite.sqlite3_stmt, pzTail: [*c][*c]const u8) !void {
            if (sqlite.sqlite3_prepare_v2(db, zSql, nByte, ppStmt, pzTail) != sqlite.SQLITE_OK) {
                std.log.warn("failed to prepare stmt\n {s}", .{sqlite.sqlite3_errmsg(db)});
                return sqliteError.SQLError;
            }
        }
    };
}

const AliasName = Table(
    "CREATE TABLE IF NOT EXISTS AliasNamePair (ID INTEGER PRIMARY KEY AUTOINCREMENT, Alias TEXT NOT NULL UNIQUE, Name TEXT);",
    "AliasNamePair",
    true,
);
const ContentPath = Table(
    "CREATE TABLE IF NOT EXISTS ContentPath (ID TEXT PRIMARY KEY,  ParentID TEXT,  RelativePath TEXT NOT NULL UNIQUE,  FileName TEXT,  TYPE INTEGER, FileSize INTEGER, ContentHash BLOB, ModifiedTime INTEGER, LastSeenTime INTEGER, FileType INTEGER);",
    "ContentPath",
    false,
);
const ImageLoadParameter = Table(
    "CREATE TABLE IF NOT EXISTS ImageLoadParameter ( ID INTEGER PRIMARY KEY AUTOINCREMENT, FileName TEXT UNIQUE, InnerName TEXT UNIQUE, ContentHash BLOB UNIQUE, FileID TEXT, FOREIGN KEY(FileID) REFERENCES contentPath(ID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ImageLoadParameter",
    true,
);

pub fn main() !void {
    var db: ?*sqlite.sqlite3 = null;
    if (sqlite.sqlite3_open("test.db", @ptrCast(&db)) != sqlite.SQLITE_OK) return sqliteError.SQLError;
    defer _ = sqlite.sqlite3_close(db);

    var tableTest = AliasName.init(db.?);
    try tableTest.createTable();
    var t2 = ContentPath.init(db.?);
    var t3 = ImageLoadParameter.init(db.?);
    try t2.createTable();
    try t3.createTable();
    std.debug.assert(tableTest.exist());

    try tableTest.insert(.{ .Alias = "alias1", .Name = "name1" });
    try t2.insert(.{
        .ID = "adfasdfdas",
        .ParentID = "aaaa",
        .RelativePath = "a",
        .FileName = "aa",
        .TYPE = 2,
        .FileSize = 12452345,
        .ContentHash = BLOB{ .data = "aaa", .len = 3 },
        .ModifiedTime = 874567845,
        .LastSeenTime = 634564235234,
        .FileType = 3,
    });
    try t3.insert(.{
        .FileName = "a",
        .InnerName = "b",
        .ContentHash = BLOB{ .data = "a", .len = 1 },
        .FileID = "c",
    });
}
