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
    ID: i32,
};

pub fn main(init: std.process.Init) !void {
    const start = std.Io.Timestamp.now(init.io, .real).toNanoseconds();

    const gpa = init.gpa;

    var it = try init.minimal.args.iterateAllocator(gpa);
    defer it.deinit();

    var root: [256:0]u8 = undefined;

    const realPath = it.next().?;
    const outputPath = it.next().?;
    // std.log.info("outputPath: {s}", .{outputPath});
    @memset(root[0..root.len], 0);

    std.mem.copyForwards(u8, &root, realPath);

    const index = std.mem.lastIndexOf(u8, &root, slash) orelse 0;
    @memset(root[index..root.len], 0);

    const cwd = try std.Io.Dir.openDirAbsolute(init.io, &root, .{});
    try std.process.setCurrentDir(init.io, cwd);

    var db: ?*sqlite.sqlite3 = null;
    if (sqlite.sqlite3_open("Content.db", @ptrCast(&db)) != sqlite.SQLITE_OK) return error.SQLError;
    defer _ = sqlite.sqlite3_close(db);

    ContentPathT = ContentPath.init(db.?);

    var types = [_]sqlDB.innerType{ .INTEGER32, .TEXT };
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

    const file = try std.Io.Dir.createFileAbsolute(init.io, outputPath, .{ .read = true });
    defer file.close(init.io);

    var buffer = [_]u8{0} ** 102400;
    const content = "const std = @import(\"std\");\n\nconst FileNameIdHashMap = map: {\nconst KV = struct {\n[]const u8,i64,\n};\nconst list = [_]KV{\n";
    var writer = std.Io.Writer.fixed(&buffer);
    _ = try writer.write(content);
    for (kvs) |value| {
        // std.log.info("name: {s}, ID: {d}", .{ value.fileName, value.ID });
        var sBuffer = [_]u8{0} ** 256;
        if (value.ID == -1) break;
        const cPtr = @as([*c]u8, @constCast(&value.fileName));
        const nameLen = std.mem.len(cPtr);
        const cc = try std.fmt.bufPrint(&sBuffer, ".{{ \"{s}\", {d} }},\n", .{ value.fileName[0..nameLen], value.ID });

        _ = try writer.write(cc);
    }
    const end = "};\n\nbreak: map std.StaticStringMap(i32).initComptime(list);\n};\n";
    _ = try writer.write(end);

    const func = " \n\n\npub fn comptimeGetID(comptime fileName: []const u8) i32 {\ncomptime {\n" ++ "return FileNameIdHashMap.get(fileName) orelse @compileError(\"not found\");\n}\n}\n\n" ++ "pub fn getID(fileName: []const u8) i32 {" ++ "    return FileNameIdHashMap.get(fileName) orelse std.debug.panic(\"ilegal name\", .{}); }";
    _ = try writer.write(func);

    const cPtr = @as([*c]u8, &buffer);
    const nameLen = std.mem.len(cPtr);

    // _ = try file.write(buffer[0..nameLen]);
    var buffer2 = [_]u8{0} ** 256;
    var fileWriter = file.writer(init.io, &buffer2);
    _ = try fileWriter.interface.write(buffer[0..nameLen]);
    try fileWriter.interface.flush();

    const endTime = std.Io.Timestamp.now(init.io, .real).toNanoseconds();

    std.log.info("create file name to id map time: {d}ms", .{@as(f128, @floatFromInt(endTime - start)) / @as(f128, @floatFromInt(std.time.ns_per_ms))});
}
