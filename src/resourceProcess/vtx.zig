const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const assert = std.debug.assert;

const vk = @import("vulkan");
const tables = @import("tables");
const resourceProcess = @import("../resourceProcess.zig");
const PreProcessParm = resourceProcess.PreProcessParm;
const db = @import("db");
const hash = @import("blake_hash");
const sqlDB = @import("sqlDb");
const ProcessType = resourceProcess.ProcessType;

const judgeFileTypeByContent = resourceProcess.judgeFileTypeByContent;

pub const VTX_Mem = struct {
    vType: u32,
    verticeBytesLen: u64,
    meshletsBytesLen: u64,
    meshletVerticesBytesLen: u64,
    meshletTrianglesBytesLen: u64,
    fileUUID: []const u8,
    hash: hash.ReturnType,
};

// var fileDbParamMap = resourceProcess.fileDbParamMap;

pub const VTX_Cooker = struct {
    pub const TableName = "ModelLoadParameterT";
    pub const Enable = true;
    const TableType = tables.ModelLoadParameter;

    pub fn preProcess(
        io: Io,
        gpa: Allocator,
        dir: Io.Dir,
        parmas: *PreProcessParm,
        Table: *TableType,
    ) !void {
        _ = io;
        _ = dir;

        const mem = resourceProcess.fileDbParamMap.get(parmas.fileName) orelse return;
        assert(@sizeOf(VTX_Mem) == mem.len);

        defer {
            if (resourceProcess.fileDbParamMap.getEntry(parmas.fileName)) |e| {
                gpa.free(e.value_ptr.*);
                gpa.free(e.key_ptr.*);
            }
        }

        const p = std.mem.bytesToValue(VTX_Mem, mem.ptr);

        try Table.update(
            "VertexType,VerticesSize,MeshletsSize,MeshletVerticesSize,MeshletTrianglesSize,ParentModelFile",
            "ContentHash = ?",
            .{
                p.vType,
                p.verticeBytesLen,
                p.meshletsBytesLen,
                p.meshletVerticesBytesLen,
                p.meshletTrianglesBytesLen,
                p.fileUUID,
                sqlDB.BLOB{ .data = &p.hash, .len = hash.blake3.BLAKE3_OUT_LEN },
            },
        );
    }

    pub fn preProcess2(
        io: Io,
        gpa: Allocator,
        contentFolderPath: []const u8,
        fileName: [:0]u8,
        content: []const u8,
        fullPath: [:0]u8,
        database: *db,
    ) !void {
        _ = io;
        _ = gpa;
        _ = contentFolderPath;
        _ = fileName;
        _ = content;
        _ = fullPath;
        _ = database;
    }

    pub fn judgeFileType2(content: []u8, fType: ProcessType) ProcessType {
        _ = content;

        return fType;
    }
};
