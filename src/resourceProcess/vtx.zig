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

const file = @import("fileSystem");
const sqlite3 = ?*file.sqlite.sqlite3;
const VkStruct = @import("video");
const Handles = @import("handle");
const Handle = Handles.Handle;
const mstd = @import("ms_std");
const MutexArray = mstd.MutexArray;
const resource = @import("resource");
const Resource = resource.Resource;
const vertexStruct = @import("vertexStruct");

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

pub const VTX_Reader = struct {
    pub fn processResource(
        comptime fType: ProcessType,
        io: Io,
        gpa: Allocator,
        sqlite: sqlite3,
        vulkan: *VkStruct,
        fileID: i32,
        handle: Handle,
        resourceArray: *MutexArray(Resource),
    ) !void {
        _ = fType;
        const res = file.getMeshLoadParam(io, fileID, sqlite) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return err;
        };
        defer res.file.close(io);

        const stat = try res.file.stat(io);

        var buffer = [_]u8{0} ** 256;
        var fileReader = res.file.reader(io, &buffer);
        var content = fileReader.interface.readAlloc(gpa, stat.size) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return err;
        };
        defer gpa.free(content);

        const stride = l: {
            var size: usize = 0;
            switch (res.mesh.vertexType) {
                inline else => |t| {
                    size = @sizeOf(vertexStruct.enumToType(t));
                },
            }
            break :l size;
        };

        const vertexCount = res.mesh.verticesSize / stride;
        _ = vertexCount;
        // std.log.debug("vertex count {d}", .{vertexCount});

        const meshletsStart = res.mesh.verticesSize;
        const meshletVerticesStart = res.mesh.meshletsSize + meshletsStart;
        const meshletTrianglesStart = res.mesh.meshletVerticesSize + meshletVerticesStart;
        const end = res.mesh.meshletTrianglesSize + meshletTrianglesStart;

        const vertices = content[0..meshletsStart];
        const meshlets = content[meshletsStart..meshletVerticesStart];
        const meshletVertices = content[meshletVerticesStart..meshletTrianglesStart];
        const meshletTriangles = content[meshletTrianglesStart..end];

        // for (meshletTriangles) |value| {
        //     std.log.debug("value {d}", .{value});
        // }

        const stagingBuffer0 = vulkan.createBufferByUsage(
            vertices.len,
            0,
            .staging,
            false,
        ) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return err;
        };
        errdefer vulkan.destroyBuffer(stagingBuffer0);
        vulkan.buffers.copyDataToMapped(stagingBuffer0, 0, u8, vertices);

        const stagingBuffer1 = vulkan.createBufferByUsage(
            meshlets.len,
            0,
            .staging,
            false,
        ) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return err;
        };
        errdefer vulkan.destroyBuffer(stagingBuffer1);
        vulkan.buffers.copyDataToMapped(stagingBuffer1, 0, u8, meshlets);

        const stagingBuffer2 = vulkan.createBufferByUsage(
            meshletVertices.len,
            0,
            .staging,
            false,
        ) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return err;
        };
        errdefer vulkan.destroyBuffer(stagingBuffer2);
        vulkan.buffers.copyDataToMapped(stagingBuffer2, 0, u8, meshletVertices);

        const stagingBuffer3 = vulkan.createBufferByUsage(
            meshletTriangles.len,
            0,
            .staging,
            false,
        ) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return err;
        };
        errdefer vulkan.destroyBuffer(stagingBuffer3);
        vulkan.buffers.copyDataToMapped(stagingBuffer3, 0, u8, meshletTriangles);

        {
            try resourceArray.mutex.lock(io);
            defer resourceArray.mutex.unlock(io);
            const ptr = resourceArray.array.addOne() catch |err| {
                std.log.err("{s}", .{@errorName(err)});
                return err;
            };
            ptr.* = .{ .mesh = .{
                .fileID = @intCast(fileID),
                .vertexStride = @intCast(stride),
                .handle = handle,
                .meshletStagingBuffer = stagingBuffer1,
                .verticesStagingBuffer = stagingBuffer0,
                .meshletVerticesStagingBuffer = stagingBuffer2,
                .meshletTrianglesStagingBuffer = stagingBuffer3,
                .meshletSize = @intCast(res.mesh.meshletsSize),
                .verticesSize = @intCast(res.mesh.verticesSize),
                .meshletVerticesSize = @intCast(res.mesh.meshletVerticesSize),
                .meshletTrianglesSize = @intCast(res.mesh.meshletTrianglesSize),
            } };
        }
    }
};
