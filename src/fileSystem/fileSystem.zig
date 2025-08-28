const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const std = @import("std");
const global = @import("global");
const assert = std.debug.assert;

const ContentPath = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ContentPath (ID TEXT PRIMARY KEY,  ParentID TEXT,  RelativePath TEXT NOT NULL UNIQUE,  FileName TEXT,  TYPE INTEGER, FileSize INTEGER, ContentHash BLOB, ModifiedTime INTEGER, LastSeenTime INTEGER, FileType INTEGER);",
    "ContentPath",
    false,
);
const ImageLoadParameter = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ImageLoadParameter (FileName TEXT PRIMARY KEY, ContentHash BLOB UNIQUE, RelativePath TEXT UNIQUE, FileID TEXT, FOREIGN KEY(FileID) REFERENCES ContentPath(ID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ImageLoadParameter",
    false,
);
const ShaderLoadParameter = sqlDB.Table(
    "CREATE TABLE IF NOT EXISTS ShaderLoadParameter (FileName TEXT PRIMARY KEY, ContentHash BLOB UNIQUE, RelativePath TEXT UNIQUE, FileSize INTEGER" ++
        ", EntryName TEXT, Stage INTEGER, BindingCount INTEGER, Bindings BLOB, PushConstantSize INTEGER" ++
        ", FileID TEXT, FOREIGN KEY(FileID) REFERENCES ContentPath(ID) ON DELETE SET NULL ON UPDATE CASCADE);",
    "ShaderLoadParameter",
    false,
);

var db: ?*sqlite.sqlite3 = null;
var ContentPathT: ContentPath = undefined;
var ImageLoadParameterT: ImageLoadParameter = undefined;
var ShaderLoadParameterT: ShaderLoadParameter = undefined;

fn getRelativePath(fileName: []const u8, result: []u8) !void {
    var ptrs: [1]*anyopaque = undefined;
    ptrs[0] = @ptrCast(result.ptr);

    var types = [_]sqlDB.innerType{.TEXT};
    // std.log.info("{*} {d}", .{ fileName.ptr, fileName.len });

    ContentPathT.get("RelativePath", "FileName = ?", .{fileName}, &ptrs, &types) catch |err| {
        std.log.err("err {s} {s} fileName:{s}", .{ @errorName(err), result, fileName });
    };
}

pub fn init() void {
    const res = sqlite.sqlite3_open(@ptrCast(global.databaseName), @ptrCast(&db));
    assert(res == sqlite.SQLITE_OK);

    ContentPathT = ContentPath.init(db.?);
    ImageLoadParameterT = ImageLoadParameter.init(db.?);
    ShaderLoadParameterT = ShaderLoadParameter.init(db.?);
}

pub fn getFile(fileName: []const u8) !std.fs.File {
    var buffer = [_]u8{0} ** 256;

    try getRelativePath(fileName, &buffer);
    const ptr = @as([*c]u8, buffer[0..256]);
    const len = std.mem.len(ptr);

    return global.cwd.openFile(buffer[0..len], .{});
}

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
    bindingCount: u32,
    bindings: ?[]binding,
    pushConstantSize: u64,

    pub fn deinit(self: *Self) void {
        if (self.bindings) |mem| {
            global.gpa.free(mem);
        }
    }
};

pub fn getShaderLoadParameter(name: []const u8) !PipelineShaderInfo {
    const fileType = try getFileType(name);
    if (fileType == .SPV) {
        var res: PipelineShaderInfo = undefined;
        @memset(res.entryName[0..64], 0);
        var path = [_:0]u8{0} ** 256;
        var ptrs: [6]*anyopaque = undefined;
        ptrs[0] = @ptrCast(&path);
        ptrs[1] = @ptrCast(&res.fileSize);
        ptrs[2] = @ptrCast(&res.entryName);
        ptrs[3] = @ptrCast(&res.stage);
        ptrs[4] = @ptrCast(&res.bindingCount);
        ptrs[5] = @ptrCast(&res.pushConstantSize);

        var types = [_]sqlDB.innerType{ .TEXT, .INTEGER, .TEXT, .INTEGER32, .INTEGER32, .INTEGER };

        try ShaderLoadParameterT.get(
            "RelativePath,FileSize,EntryName,Stage,BindingCount,PushConstantSize",
            "FileName = ?",
            .{name},
            &ptrs,
            &types,
        );

        if (res.bindingCount > 0) {
            res.bindings = try global.gpa.alloc(PipelineShaderInfo.binding, res.bindingCount);
            var blob = sqlDB.BLOBForGet{
                .data = @ptrCast(res.bindings.?.ptr),
                .len = @sizeOf(PipelineShaderInfo.binding) * res.bindings.?.len,
            };
            var pptrs: [1]*anyopaque = undefined;
            pptrs[0] = @ptrCast(&blob);
            var typess = [_]sqlDB.innerType{.BLOB};

            try ShaderLoadParameterT.get("Bindings", "FileName = ?", .{name}, &pptrs, &typess);
        } else {
            res.bindings = null;
        }

        const ptr = @as([*c]u8, path[0..256]);
        const len = std.mem.len(ptr);

        return PipelineShaderInfo{
            .fileSize = res.fileSize,
            .entryName = res.entryName,
            .stage = res.stage,
            .bindingCount = res.bindingCount,
            .bindings = res.bindings,
            .pushConstantSize = res.pushConstantSize,
            .file = try global.cwd.openFile(path[0..len], .{}),
        };
    }
    return error.NotShader;
}

pub fn deinit() void {
    _ = sqlite.sqlite3_close(db.?);
}
