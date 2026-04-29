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

const ContentPath = tables.ContentPath;
const ImageLoadParameter = tables.ImageLoadParameter;
const ModelLoadParameter = tables.ModelLoadParameter;

var db: ?*sqlite.sqlite3 = null;
var ContentPathT: ContentPath = undefined;
var ImageLoadParameterT: ImageLoadParameter = undefined;
var ModelLoadParameterT: ModelLoadParameter = undefined;

fn getRelativePath(id: i64, result: []u8) !void {
    var ptrs: [1]*anyopaque = undefined;
    ptrs[0] = @ptrCast(result.ptr);

    var types = [_]sqlDB.innerType{.TEXT};
    // std.log.info("{*} {d}", .{ fileName.ptr, fileName.len });

    ContentPathT.get("RelativePath", null, "ID = ?", .{id}, &ptrs, &types) catch |err| {
        std.log.err("err {s} {s} ID{d} ", .{ @errorName(err), result, id });
    };
}

pub fn init(databaseName: []const u8) void {
    var disk_db: ?*sqlite.sqlite3 = null;
    var backup: ?*sqlite.sqlite3_backup = null;

    var res = sqlite.sqlite3_open(@ptrCast(databaseName.ptr), @ptrCast(&disk_db));
    defer _ = sqlite.sqlite3_close(disk_db);
    assert(res == sqlite.SQLITE_OK);

    res = sqlite.sqlite3_open(":memory:", @ptrCast(&db));
    assert(res == sqlite.SQLITE_OK);

    backup = sqlite.sqlite3_backup_init(db, "main", disk_db, "main");
    assert(backup != null);

    res = sqlite.sqlite3_backup_step(backup, -1);
    defer _ = sqlite.sqlite3_backup_finish(backup);
    assert(res == sqlite.SQLITE_DONE);

    ContentPathT = ContentPath.init(db.?);
    ImageLoadParameterT = ImageLoadParameter.init(db.?);
    ModelLoadParameterT = ModelLoadParameter.init(db.?);
}

pub fn getFile(io: std.Io, id: i64, cwd: std.Io.Dir) !std.Io.File {
    var buffer = [_]u8{0} ** 256;

    try getRelativePath(id, &buffer);
    const ptr = @as([*c]u8, buffer[0..256]);
    const len = std.mem.len(ptr);

    // std.log.debug("open file {s}", .{buffer[0..len]});

    return cwd.openFile(io, buffer[0..len], .{});
}

pub const FileType = Types.FileType;

pub fn getFileType(id: i32) sqlDB.sqliteError!FileType {
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

pub fn getImageLoadParam(id: i32) !imageLoad {
    const fType = try getFileType(id);
    switch (fType) {
        .PNG => {
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

pub fn getMeshLoadParam(id: i32) !meshLoad {
    const fType = try getFileType(id);
    switch (fType) {
        .VTX => {
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

pub fn deinit(databaseName: []const u8) void {
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
