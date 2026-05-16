const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const std = @import("std");
const assert = std.debug.assert;
const tables = @import("tables");
const vertexStruct = @import("vertexStruct");
const fileNameID = @import("fileNameID.zig");
const Types = @import("types");

pub const comptimeGetID = fileNameID.comptimeGetID;
pub const getID = fileNameID.getID;
pub const MaxID = fileNameID.MaxID;

const ContentPath = tables.ContentPath;
const ImageLoadParameter = tables.ImageLoadParameter;
const ModelLoadParameter = tables.ModelLoadParameter;

fn assertEqual(a: c_int, b: c_int) void {
    std.log.debug("a {d}", .{a});
    std.debug.assert(a == b);
}

fn getRelativePath(id: i64, result: []u8, db: ?*sqlite.sqlite3) !void {
    var ContentPathT = ContentPath.init(db);
    var ptrs: [1]*anyopaque = undefined;
    ptrs[0] = @ptrCast(result.ptr);

    var types = [_]sqlDB.innerType{.TEXT};
    // std.log.info("{*} {d}", .{ fileName.ptr, fileName.len });

    ContentPathT.get("RelativePath", null, "ID = ?", .{id}, &ptrs, &types) catch |err| {
        std.log.err("err {s} {s} ID{d} ", .{ @errorName(err), result, id });
    };
}

fn retryNtimes(io: std.Io, times: u32, comptime function: anytype, args: anytype) !void {
    var i: u32 = 0;
    while (i < times) : (i += 1) {
        const res = function(
            args.@"0",
            args.@"1",
            args.@"2",
            args.@"3",
        );

        if (res == sqlite.SQLITE_OK) {
            break;
        } else if (res == sqlite.SQLITE_BUSY) {
            continue;
        } else {
            return sqlDB.sqliteError.StepError;
        }

        try std.Io.sleep(io, .fromSeconds(1), .real);
    }
}

var mutex: std.Io.Mutex = .init;

pub fn init(io: std.Io, databaseName: []const u8, db: [*c]?*sqlite.sqlite3) void {
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);

    var disk_db: ?*sqlite.sqlite3 = null;
    var backup: ?*sqlite.sqlite3_backup = null;

    var res = sqlite.sqlite3_open_v2(
        @ptrCast(databaseName.ptr),
        @ptrCast(&disk_db),
        sqlite.SQLITE_OPEN_READWRITE | sqlite.SQLITE_OPEN_CREATE,
        null,
    );
    defer _ = sqlite.sqlite3_close_v2(disk_db);
    assertEqual(res, sqlite.SQLITE_OK);

    const uri = "file:memdb1?mode=memory&cache=shared";
    res = sqlite.sqlite3_open_v2(
        // ":memory:",
        @ptrCast(uri),
        db,
        sqlite.SQLITE_OPEN_READWRITE | sqlite.SQLITE_OPEN_CREATE | sqlite.SQLITE_OPEN_URI,
        null,
    );
    assertEqual(res, sqlite.SQLITE_OK);

    backup = sqlite.sqlite3_backup_init(db.*, "main", disk_db, "main");
    assert(backup != null);

    res = sqlite.sqlite3_backup_step(backup, -1);
    defer _ = sqlite.sqlite3_backup_finish(backup);
    assertEqual(res, sqlite.SQLITE_DONE);
}

pub fn initManyDb(io: std.Io, databaseName: []const u8, openTimes: u32, rwSqlite: [*c]?*sqlite.sqlite3, allocator: std.mem.Allocator) ![]?*sqlite.sqlite3 {
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);

    _ = sqlite.sqlite3_config(sqlite.SQLITE_CONFIG_MULTITHREAD);

    const dbs = try allocator.alloc(?*sqlite.sqlite3, openTimes);

    var disk_db: ?*sqlite.sqlite3 = null;
    var backup: ?*sqlite.sqlite3_backup = null;

    var res = sqlite.sqlite3_open_v2(
        @ptrCast(databaseName.ptr),
        @ptrCast(&disk_db),
        sqlite.SQLITE_OPEN_READONLY,
        null,
    );
    defer _ = sqlite.sqlite3_close_v2(disk_db);

    const uri = "file:memdb1?mode=memory&cache=shared";
    res = sqlite.sqlite3_open_v2(
        @ptrCast(uri),
        @ptrCast(rwSqlite),
        sqlite.SQLITE_OPEN_READWRITE | sqlite.SQLITE_OPEN_CREATE | sqlite.SQLITE_OPEN_URI,
        null,
    );
    assertEqual(res, sqlite.SQLITE_OK);

    backup = sqlite.sqlite3_backup_init(rwSqlite.*, "main", disk_db, "main");
    assert(backup != null);

    res = sqlite.sqlite3_backup_step(backup, -1);
    assertEqual(res, sqlite.SQLITE_DONE);

    _ = sqlite.sqlite3_backup_finish(backup);

    for (dbs) |*dbb| {
        res = sqlite.sqlite3_open_v2(
            uri,
            @ptrCast(dbb),
            sqlite.SQLITE_OPEN_READONLY | sqlite.SQLITE_OPEN_URI,
            null,
        );
        assertEqual(res, sqlite.SQLITE_OK);
    }

    return dbs;
}

pub fn getFile(io: std.Io, id: i64, cwd: std.Io.Dir, db: ?*sqlite.sqlite3) !std.Io.File {
    var buffer = [_]u8{0} ** 256;

    try getRelativePath(id, &buffer, db);
    const ptr = @as([*c]u8, buffer[0..256]);
    const len = std.mem.len(ptr);

    // std.log.debug("open file {s}", .{buffer[0..len]});

    return cwd.openFile(io, buffer[0..len], .{});
}

pub const FileType = Types.FileType;

pub fn getFileType(id: i32, db: ?*sqlite.sqlite3) sqlDB.sqliteError!FileType {
    var ContentPathT = ContentPath.init(db);

    var res: i64 = 0;
    var ptrs: [1]*anyopaque = undefined;
    ptrs[0] = @ptrCast(&res);

    var types = [_]sqlDB.innerType{.INTEGER};

    try ContentPathT.get("FileType", null, "ID = ?", .{id}, &ptrs, &types);

    return @enumFromInt(res);
}

const vk = @import("vulkan");

// pub const PipelineShaderInfo = struct {
//     const Self = @This();

//     const binding = struct {
//         set: u32,
//         binding: u32,
//         descriptorCount: u32,
//         descriptorType: vk.VkDescriptorType,
//     };

//     file: std.fs.File,
//     fileSize: u64,
//     entryName: [64:0]u8,
//     stage: vk.VkShaderStageFlags,
//     setCount: u32,
//     bindingCount: u32,
//     bindings: ?[]binding,
//     pushConstantSize: u64,

//     pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
//         if (self.bindings) |mem| {
//             allocator.free(mem);
//         }
//     }
// };

pub const Image = struct {
    format: vk.VkFormat,
    tiling: vk.VkImageTiling,
    usage: vk.VkImageUsageFlags,
    properties: vk.VkMemoryPropertyFlags,
};

const imageLoad = struct {
    relativePath: [256]u8,
    image: Image,
};

pub fn getImageLoadParam(id: i32, db: ?*sqlite.sqlite3) !imageLoad {
    const fType = try getFileType(id, db);
    switch (fType) {
        .PNG => {
            var ImageLoadParameterT = ImageLoadParameter.init(db);

            var ptrs: [5]*anyopaque = undefined;
            var buffer = [_]u8{0} ** 256;
            var format: vk.VkFormat = vk.VK_FORMAT_UNDEFINED;
            var tiling: vk.VkImageTiling = vk.VK_IMAGE_TILING_OPTIMAL;
            var usage: vk.VkImageUsageFlags = undefined;
            var properties: vk.VkMemoryPropertyFlags = undefined;
            ptrs[0] = @ptrCast(&buffer);
            ptrs[1] = @ptrCast(&format);
            ptrs[2] = @ptrCast(&tiling);
            ptrs[3] = @ptrCast(&usage);
            ptrs[4] = @ptrCast(&properties);

            var types = [_]sqlDB.innerType{ .TEXT, .INTEGER32, .INTEGER32, .INTEGER32, .INTEGER32 };

            try ImageLoadParameterT.get("RelativePath,Format,Tiling,Usage,Properties", null, "ID = ?", .{id}, &ptrs, &types);

            return imageLoad{
                .image = .{
                    .format = format,
                    .tiling = tiling,
                    .usage = usage,
                    .properties = properties,
                },
                .relativePath = buffer,
            };
        },
        else => {
            return error.fileTypeError;
        },
    }
}

pub const Mesh = struct {
    verticesSize: u64,
    meshletsSize: u64,
    meshletVerticesSize: u64,
    meshletTrianglesSize: u64,
    vertexType: vertexStruct.VertexType,
};

const meshLoad = struct {
    relativePath: [256]u8,
    mesh: Mesh,
};

pub fn getMeshLoadParam(id: i32, db: ?*sqlite.sqlite3) !meshLoad {
    const fType = try getFileType(id);
    switch (fType) {
        .VTX => {
            var ModelLoadParameterT = ModelLoadParameter.init(db);

            var ptrs: [6]*anyopaque = undefined;
            var buffer = [_]u8{0} ** 256;
            var vertexType: u32 = @intFromEnum(vertexStruct.VertexType.none);
            var verticesSize: u64 = 0;
            var meshletsSize: u64 = 0;
            var meshletVerticesSize: u64 = 0;
            var meshletTrianglesSize: u64 = 0;

            ptrs[0] = @ptrCast(&buffer);
            ptrs[1] = @ptrCast(&vertexType);
            ptrs[2] = @ptrCast(&verticesSize);
            ptrs[3] = @ptrCast(&meshletsSize);
            ptrs[4] = @ptrCast(&meshletVerticesSize);
            ptrs[5] = @ptrCast(&meshletTrianglesSize);

            var types = [_]sqlDB.innerType{ .TEXT, .INTEGER32, .INTEGER, .INTEGER, .INTEGER, .INTEGER };

            try ModelLoadParameterT.get(
                "RelativePath,VertexType,VerticesSize,MeshletsSize,MeshletVerticesSize,MeshletTrianglesSize",
                null,
                "ID = ?",
                .{id},
                &ptrs,
                &types,
            );

            return meshLoad{
                .relativePath = buffer,
                .mesh = .{
                    .vertexType = @enumFromInt(vertexType),
                    .meshletsSize = meshletsSize,
                    .meshletTrianglesSize = meshletTrianglesSize,
                    .meshletVerticesSize = meshletVerticesSize,
                    .verticesSize = verticesSize,
                },
            };
        },
        else => {
            return error.fileTypeError;
        },
    }
}

pub fn deinit(databaseName: []const u8, db: ?*sqlite.sqlite3) void {
    var disk_db: ?*sqlite.sqlite3 = null;
    var backup: ?*sqlite.sqlite3_backup = null;

    var res = sqlite.sqlite3_open(@ptrCast(databaseName.ptr), @ptrCast(&disk_db));
    defer _ = sqlite.sqlite3_close(disk_db);
    assert(res == sqlite.SQLITE_OK);

    backup = sqlite.sqlite3_backup_init(disk_db, "main", db, "main");
    assert(backup != null);

    res = sqlite.sqlite3_backup_step(backup, -1);
    defer _ = sqlite.sqlite3_backup_finish(backup);
    assert(res == sqlite.SQLITE_DONE);

    _ = sqlite.sqlite3_close(db.?);
}

pub fn deinitManyDB(
    databaseName: []const u8,
    rwSqlite: ?*sqlite.sqlite3,
    dbs: []?*sqlite.sqlite3,
    allocator: std.mem.Allocator,
) void {
    for (dbs) |value| {
        _ = sqlite.sqlite3_close_v2(value);
    }

    allocator.free(dbs);

    deinit(databaseName, rwSqlite);
}
