const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const std = @import("std");
const assert = std.debug.assert;
const tables = @import("tables");

const ContentPath = tables.ContentPath;
const ImageLoadParameter = tables.ImageLoadParameter;

var db: ?*sqlite.sqlite3 = null;
var ContentPathT: ContentPath = undefined;
var ImageLoadParameterT: ImageLoadParameter = undefined;

fn getRelativePath(fileName: []const u8, result: []u8) !void {
    var ptrs: [1]*anyopaque = undefined;
    ptrs[0] = @ptrCast(result.ptr);

    var types = [_]sqlDB.innerType{.TEXT};
    // std.log.info("{*} {d}", .{ fileName.ptr, fileName.len });

    ContentPathT.get("RelativePath", "FileName = ?", .{fileName}, &ptrs, &types) catch |err| {
        std.log.err("err {s} {s} fileName:{s}", .{ @errorName(err), result, fileName });
    };
}

pub fn init(databaseName: []const u8) void {
    const res = sqlite.sqlite3_open(@ptrCast(databaseName.ptr), @ptrCast(&db));
    assert(res == sqlite.SQLITE_OK);

    ContentPathT = ContentPath.init(db.?);
    ImageLoadParameterT = ImageLoadParameter.init(db.?);
}

pub fn getFile(fileName: []const u8, cwd: std.fs.Dir) !std.fs.File {
    var buffer = [_]u8{0} ** 256;

    try getRelativePath(fileName, &buffer);
    const ptr = @as([*c]u8, buffer[0..256]);
    const len = std.mem.len(ptr);

    return cwd.openFile(buffer[0..len], .{});
}

pub const FileType = enum {
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

pub fn getFileType(name: []const u8) sqlDB.sqliteError!FileType {
    var res: i64 = 0;
    var ptrs: [1]*anyopaque = undefined;
    ptrs[0] = @ptrCast(&res);

    var types = [_]sqlDB.innerType{.INTEGER};

    try ContentPathT.get("FileType", "FileName = ?", .{name}, &ptrs, &types);

    return @enumFromInt(res);
}

const vk = @cImport(@cInclude("vulkan/vulkan.h"));

pub const PipelineShaderInfo = struct {
    const Self = @This();

    const binding = struct {
        set: u32,
        binding: u32,
        descriptorCount: u32,
        descriptorType: vk.VkDescriptorType,
    };

    file: std.fs.File,
    fileSize: u64,
    entryName: [64:0]u8,
    stage: vk.VkShaderStageFlags,
    setCount: u32,
    bindingCount: u32,
    bindings: ?[]binding,
    pushConstantSize: u64,

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        if (self.bindings) |mem| {
            allocator.free(mem);
        }
    }
};

// pub fn getShaderLoadParameter(name: []const u8, allocator: std.mem.Allocator, cwd: std.fs.Dir) !PipelineShaderInfo {
//     const fileType = try getFileType(name);
//     if (fileType == .SPV) {
//         var res: PipelineShaderInfo = undefined;
//         @memset(res.entryName[0..64], 0);
//         var path = [_:0]u8{0} ** 256;
//         var ptrs: [7]*anyopaque = undefined;
//         ptrs[0] = @ptrCast(&path);
//         ptrs[1] = @ptrCast(&res.fileSize);
//         ptrs[2] = @ptrCast(&res.entryName);
//         ptrs[3] = @ptrCast(&res.stage);
//         ptrs[4] = @ptrCast(&res.bindingCount);
//         ptrs[5] = @ptrCast(&res.pushConstantSize);
//         ptrs[6] = @ptrCast(&res.setCount);

//         var types = [_]sqlDB.innerType{ .TEXT, .INTEGER, .TEXT, .INTEGER32, .INTEGER32, .INTEGER, .INTEGER32 };

//         try ShaderLoadParameterT.get(
//             "RelativePath,FileSize,EntryName,Stage,BindingCount,PushConstantSize,SetCount",
//             "FileName = ?",
//             .{name},
//             &ptrs,
//             &types,
//         );

//         if (res.bindingCount > 0) {
//             res.bindings = try allocator.alloc(PipelineShaderInfo.binding, res.bindingCount);
//             var blob = sqlDB.BLOBForGet{
//                 .data = @ptrCast(res.bindings.?.ptr),
//                 .len = @sizeOf(PipelineShaderInfo.binding) * res.bindings.?.len,
//             };
//             var pptrs: [1]*anyopaque = undefined;
//             pptrs[0] = @ptrCast(&blob);
//             var typess = [_]sqlDB.innerType{.BLOB};

//             try ShaderLoadParameterT.get("Bindings", "FileName = ?", .{name}, &pptrs, &typess);
//         } else {
//             res.bindings = null;
//         }

//         const ptr = @as([*c]u8, path[0..256]);
//         const len = std.mem.len(ptr);

//         return PipelineShaderInfo{
//             .fileSize = res.fileSize,
//             .entryName = res.entryName,
//             .stage = res.stage,
//             .setCount = res.setCount,
//             .bindingCount = res.bindingCount,
//             .bindings = res.bindings,
//             .pushConstantSize = res.pushConstantSize,
//             .file = try cwd.openFile(path[0..len], .{}),
//         };
//     }
//     return error.NotShader;
// }

pub fn deinit() void {
    _ = sqlite.sqlite3_close(db.?);
}
