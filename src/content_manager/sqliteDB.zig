const sqlite = @cImport(@cInclude("sqlite3/sqlite3.h"));
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const std = @import("std");

const sqliteError = error{SQLError};

pub const innerType = enum {
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

fn isCompileTimeString(comptime T: type) bool {
    const info = @typeInfo(T);

    // 1. 必须是一个指针
    // @compileLog("1");
    if (info != .pointer) return false;

    // 2. 指针必须是 const
    // @compileLog("2");
    if (info.pointer.is_const == false) return false;

    // 获取指针指向的类型
    const ArrayType = info.pointer.child;
    const array_info = @typeInfo(ArrayType);

    // 3. 指针指向的必须是一个数组
    // @compileLog("3");
    if (array_info != .array) return false;

    // 4. 数组的元素类型必须是 u8
    // @compileLog("4");
    if (array_info.array.child != u8) return false;

    // 5. 数组必须有一个哨兵
    // @compileLog("5");
    const sentinel = array_info.array.sentinel() orelse return false;

    // 6. 哨兵的值必须是 0
    // @compileLog("6");
    if (sentinel != 0) return false;

    // @compileLog("7");
    return true;
}

const param = struct { paramName: []const u8, paramType: innerType };

const ParamsPack = struct {
    ps: [64]param,
    count: u32,
};
pub const BLOB = struct {
    data: [*]const u8,
    len: c_int,
};
pub const VOID_ = struct {
    data: [*]u8,
    len: usize,
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
                    break :ty ?BLOB;
                },
                .INTEGER => {
                    break :ty i64;
                },
                .TEXT => {
                    break :ty ?[*]u8;
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

            prepare_v2(self.db, @ptrCast(expr), -1, @ptrCast(&stmt), null);
            defer _ = sqlite.sqlite3_finalize(stmt);

            if (sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) return true;

            return false;
        }

        pub fn insert(self: *Self, T: insertStruct) void {
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
            // std.log.info("{s}", .{ssql});

            var stmt: ?*sqlite.sqlite3_stmt = null;
            prepare_v2(self.db, @ptrCast(ssql), -1, @ptrCast(&stmt), null);
            defer _ = sqlite.sqlite3_finalize(stmt);

            inline for (Params.ps[0..Params.count], 0..Params.count) |pp, i| {
                // std.log.info("cast c_int {d}", .{@as(c_int, @intCast(i))});
                switch (pp.paramType) {
                    .INTEGER => {
                        _ = sqlite.sqlite3_bind_int64(stmt, @intCast(i + 1), @field(T, pp.paramName));
                    },
                    .BLOB => {
                        if (@field(T, pp.paramName)) |b| {
                            _ = sqlite.sqlite3_bind_blob(stmt, @intCast(i + 1), b.data, b.len, sqlite.SQLITE_STATIC);
                        } else {
                            _ = sqlite.sqlite3_bind_blob(stmt, @intCast(i + 1), null, 0, sqlite.SQLITE_STATIC);
                        }
                    },
                    .TEXT => {
                        const res = sqlite.sqlite3_bind_text(stmt, @intCast(i + 1), @field(T, pp.paramName), -1, sqlite.SQLITE_STATIC);
                        if (res != sqlite.SQLITE_OK) {
                            std.log.err("text {s}", .{sqlite.sqlite3_errmsg(self.db)});
                        }
                    },
                }
            }

            if (sqlite.sqlite3_step(stmt) != sqlite.SQLITE_DONE) {
                std.log.err("{s}", .{sqlite.sqlite3_errmsg(self.db)});
            }
        }

        pub fn update(self: *Self, comptime targets: []const u8, comptime constraint: []const u8, values: anytype) void {
            const ArgsType = @TypeOf(values);
            const args_type_info = @typeInfo(ArgsType);
            if (args_type_info != .@"struct") {
                @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));
            }

            const fields_info = args_type_info.@"struct".fields;

            @setEvalBranchQuota(2000000);
            // comptime var arg_state: std.fmt.ArgState = .{ .args_len = fields_info.len };
            // comptime var ia = 0;

            const ssql = comptime ss: {
                var buffer = [_]u8{0} ** 4096;
                var bu = std.io.fixedBufferStream(buffer[0..buffer.len]);
                var writer = bu.writer();
                var count: usize = 0;

                var li = std.mem.splitSequence(u8, targets, ",");

                while (li.next()) |name| {
                    count += writer.write(std.fmt.comptimePrint("{s} = ?", .{name})) catch |err| {
                        @compileError(std.fmt.comptimePrint("err: {s}", .{@errorName(err)}));
                    };

                    count += writer.write(std.fmt.comptimePrint(", ", .{})) catch |err| {
                        @compileError(std.fmt.comptimePrint("err: {s}", .{@errorName(err)}));
                    };
                }

                break :ss std.fmt.comptimePrint("UPDATE {s} SET {s} WHERE {s};", .{ tableName, buffer[0 .. count - 2], constraint });
            };
            std.log.info("{s}", .{ssql});

            var stmt: ?*sqlite.sqlite3_stmt = null;
            prepare_v2(self.db, @ptrCast(ssql), -1, @ptrCast(&stmt), null);
            defer _ = sqlite.sqlite3_finalize(stmt);

            inline for (0..fields_info.len) |i| {
                const ii: c_int = @intCast(i + 1);
                std.log.info("cast c_int {d}", .{ii});

                switch (fields_info[i].type) {
                    i64 => {
                        _ = sqlite.sqlite3_bind_int64(stmt, ii, @field(values, fields_info[i].name));
                    },
                    BLOB => {
                        _ = sqlite.sqlite3_bind_blob(
                            stmt,
                            ii,
                            @field(values, fields_info[i].name).data,
                            @field(values, fields_info[i].name).len,
                            sqlite.SQLITE_STATIC,
                        );
                    },
                    else => {
                        const yes: bool = comptime l: {
                            break :l isCompileTimeString(fields_info[i].type);
                        };
                        if (yes) {
                            const res = sqlite.sqlite3_bind_text(
                                stmt,
                                ii,
                                @field(values, fields_info[i].name),
                                -1,
                                sqlite.SQLITE_STATIC,
                            );
                            if (res != sqlite.SQLITE_OK) {
                                std.log.err("text {s} ({s})", .{ sqlite.sqlite3_errmsg(self.db), @field(values, fields_info[i].name) });
                            }
                        } else {
                            // @compileLog("sss");
                            @compileError(std.fmt.comptimePrint("unsupported type {s} {}", .{ @typeName(fields_info[i].type), yes }));
                        }
                    },
                }
            }

            _ = sqlite.sqlite3_step(stmt);
        }

        pub fn delete(self: *Self, comptime constraint: []const u8, values: anytype) void {
            const ArgsType = @TypeOf(values);
            const args_type_info = @typeInfo(ArgsType);
            if (args_type_info != .@"struct") {
                @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));
            }

            const fields_info = args_type_info.@"struct".fields;

            @setEvalBranchQuota(2000000);
            // comptime var arg_state: std.fmt.ArgState = .{ .args_len = fields_info.len };
            // comptime var ia = 0;

            const ssql = comptime ss: {
                break :ss std.fmt.comptimePrint("DELETE FROM {s} WHERE {s};", .{ tableName, constraint });
            };
            std.log.info("{s}", .{ssql});

            var stmt: ?*sqlite.sqlite3_stmt = null;
            prepare_v2(self.db, @ptrCast(ssql), -1, @ptrCast(&stmt), null);
            defer _ = sqlite.sqlite3_finalize(stmt);

            inline for (0..fields_info.len) |i| {
                const ii: c_int = @intCast(i + 1);
                std.log.info("cast c_int {d}", .{ii});

                switch (fields_info[i].type) {
                    i64 => {
                        _ = sqlite.sqlite3_bind_int64(stmt, ii, @field(values, fields_info[i].name));
                    },
                    BLOB => {
                        _ = sqlite.sqlite3_bind_blob(
                            stmt,
                            ii,
                            @field(values, fields_info[i].name).data,
                            @field(values, fields_info[i].name).len,
                            sqlite.SQLITE_STATIC,
                        );
                    },
                    else => {
                        const yes: bool = comptime l: {
                            break :l isCompileTimeString(fields_info[i].type);
                        };
                        if (yes) {
                            const res = sqlite.sqlite3_bind_text(
                                stmt,
                                ii,
                                @field(values, fields_info[i].name),
                                -1,
                                sqlite.SQLITE_STATIC,
                            );
                            if (res != sqlite.SQLITE_OK) {
                                std.log.err("text {s} ({s})", .{ sqlite.sqlite3_errmsg(self.db), @field(values, fields_info[i].name) });
                            }
                        } else {
                            // @compileLog("sss");
                            @compileError(std.fmt.comptimePrint("unsupported type {s} {}", .{ @typeName(fields_info[i].type), yes }));
                        }
                    },
                }
            }

            _ = sqlite.sqlite3_step(stmt);
        }

        pub fn get(self: *Self, comptime targets: []const u8, comptime constraint: []const u8, values: anytype, getValues: []*anyopaque, types: []innerType) !void {
            if (getValues.len != types.len) {
                return sqliteError.SQLError;
            }

            const ArgsType = @TypeOf(values);
            const args_type_info = @typeInfo(ArgsType);
            if (args_type_info != .@"struct") {
                @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));
            }

            const fields_info = args_type_info.@"struct".fields;

            @setEvalBranchQuota(2000000);

            const ssql = comptime ss: {
                break :ss std.fmt.comptimePrint("SELECT {s} FROM {s} WHERE {s};", .{ targets, tableName, constraint });
            };
            std.log.info("{s}", .{ssql});

            var stmt: ?*sqlite.sqlite3_stmt = null;
            prepare_v2(self.db, @ptrCast(ssql), -1, @ptrCast(&stmt), null);
            defer _ = sqlite.sqlite3_finalize(stmt);

            inline for (0..fields_info.len) |i| {
                const ii: c_int = @intCast(i + 1);
                std.log.info("cast c_int {d}", .{ii});

                switch (fields_info[i].type) {
                    i64 => {
                        _ = sqlite.sqlite3_bind_int64(stmt, ii, @field(values, fields_info[i].name));
                    },
                    i32 => {
                        _ = sqlite.sqlite3_bind_int64(stmt, ii, @field(values, fields_info[i].name));
                    },
                    BLOB => {
                        _ = sqlite.sqlite3_bind_blob(
                            stmt,
                            ii,
                            @field(values, fields_info[i].name).data,
                            @field(values, fields_info[i].name).len,
                            sqlite.SQLITE_STATIC,
                        );
                    },
                    else => {
                        const yes: bool = comptime l: {
                            break :l isCompileTimeString(fields_info[i].type);
                        };
                        if (yes) {
                            const res = sqlite.sqlite3_bind_text(
                                stmt,
                                ii,
                                @field(values, fields_info[i].name),
                                -1,
                                sqlite.SQLITE_STATIC,
                            );
                            if (res != sqlite.SQLITE_OK) {
                                std.log.err("text {s} ({s})", .{ sqlite.sqlite3_errmsg(self.db), @field(values, fields_info[i].name) });
                            }
                        } else {
                            // @compileLog("sss");
                            @compileError(std.fmt.comptimePrint("unsupported type {s} {}", .{ @typeName(fields_info[i].type), yes }));
                        }
                    },
                }
            }

            const res = sqlite.sqlite3_step(stmt);
            if (res != sqlite.SQLITE_ROW) {
                return sqliteError.SQLError;
            }

            for (0..types.len) |i| {
                const ii: c_int = @intCast(i);

                switch (types[i]) {
                    .INTEGER => {
                        //     const ptr = @as(*i32, @ptrCast(getValues[i]));
                        //     ptr = @as(i32, sqlite.sqlite3_column_int(stmt, i));
                        // },
                        // => {
                        const ptr = @as(*i64, @alignCast(@ptrCast(getValues[i])));
                        ptr.* = @as(i64, sqlite.sqlite3_column_int64(stmt, ii));
                    },
                    .TEXT => {
                        const ptr = @as([*]u8, @alignCast(@ptrCast(getValues[i])));
                        const str = sqlite.sqlite3_column_text(stmt, ii);
                        const len = sdl.SDL_strlen(str);
                        @memcpy(ptr, str[0..len]);
                    },
                    .BLOB => {
                        const ptr = @as(*VOID_, @alignCast(@ptrCast(getValues[i]))).*;
                        const str = @as([*]u8, @ptrCast(@constCast(sqlite.sqlite3_column_blob(stmt, ii).?)));
                        @memcpy(ptr.data, str[0..ptr.len]);
                    },
                }
            }
        }

        fn prepare_v2(db: ?*sqlite.sqlite3, zSql: [*c]const u8, nByte: c_int, ppStmt: [*c]?*sqlite.sqlite3_stmt, pzTail: [*c][*c]const u8) void {
            if (sqlite.sqlite3_prepare_v2(db, zSql, nByte, ppStmt, pzTail) != sqlite.SQLITE_OK) {
                std.log.warn("failed to prepare stmt\n {s}", .{sqlite.sqlite3_errmsg(db)});
                // return sqliteError.SQLError;
            }
        }
    };
}
