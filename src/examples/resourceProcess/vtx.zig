const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const global = @import("global");

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
const Buffer_t = VkStruct.Buffer_t;
const ExternalCommands = @import("processRender").externalCommands;
const Commands = @import("processRender").commands;
const mesh = @import("mesh");

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

const ResourceError = resource.ResourceError;

pub const VTX_Reader = struct {
    const Self = @This();

    pub const Ctx = struct {
        meshes: *mesh,
    };

    pub const Child = struct {
        pub const Parent = VTX_Reader;

        sizes: [4]u64,
        stride: u32,

        pub fn free(self: *Child, gpa: Allocator) void {
            _ = self;
            _ = gpa;
        }
    };

    pub fn read(
        comptime fType: ProcessType,
        ctx: *const resource.ResourceCtx,
        sqlite: sqlite3,
        fileID: u32,
        buffer_ts: ?[]Buffer_t,
        commands: *ExternalCommands,
        child: *Child,
    ) ResourceError!resource.ReaderReturnType {
        _ = fType;

        const io = ctx.io;
        const gpa = ctx.gpa;
        const vulkan = ctx.vulkan;
        const handles = ctx.handles;

        const res = file.getMeshLoadParam(io, fileID, sqlite) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        defer res.file.close(io);

        const stat = res.file.stat(io) catch return ResourceError.Unavaliable;

        var buffer = [_]u8{0} ** 256;
        var fileReader = res.file.reader(io, &buffer);
        var content = fileReader.interface.readAlloc(gpa, stat.size) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
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

        const verticesStagingBuffer = vulkan.createBufferByUsage(
            vertices.len,
            0,
            .staging,
            false,
            null,
        ) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        errdefer vulkan.destroyBuffer(verticesStagingBuffer);
        vulkan.buffers.copyDataToMapped(verticesStagingBuffer, 0, u8, vertices);

        const meshletStagingBuffer = vulkan.createBufferByUsage(
            meshlets.len,
            0,
            .staging,
            false,
            null,
        ) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        errdefer vulkan.destroyBuffer(meshletStagingBuffer);
        vulkan.buffers.copyDataToMapped(meshletStagingBuffer, 0, u8, meshlets);

        const meshletVerticesStagingBuffer = vulkan.createBufferByUsage(
            meshletVertices.len,
            0,
            .staging,
            false,
            null,
        ) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        errdefer vulkan.destroyBuffer(meshletVerticesStagingBuffer);
        vulkan.buffers.copyDataToMapped(meshletVerticesStagingBuffer, 0, u8, meshletVertices);

        const meshletTrianglesStagingBuffer = vulkan.createBufferByUsage(
            meshletTriangles.len,
            0,
            .staging,
            false,
            null,
        ) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        errdefer vulkan.destroyBuffer(meshletTrianglesStagingBuffer);
        vulkan.buffers.copyDataToMapped(meshletTrianglesStagingBuffer, 0, u8, meshletTriangles);

        const sizes = [_]u64{
            res.mesh.meshletsSize,
            res.mesh.verticesSize,
            res.mesh.meshletVerticesSize,
            res.mesh.meshletTrianglesSize,
        };

        child.sizes = sizes;
        child.stride = @intCast(stride);

        var buffers = [_]VkStruct.Buffer_t{
            meshletStagingBuffer,
            verticesStagingBuffer,
            meshletVerticesStagingBuffer,
            meshletTrianglesStagingBuffer,
        };

        for (0..4) |i| {
            const bufferAndOffset = vulkan.buffers.createVirtualBuffer(
                buffer_ts.?[i],
                0,
                sizes[i],
                16,
                handles,
            ) catch return ResourceError.Unavaliable;

            var copyRegion = [1]vk.VkBufferCopy2{.{
                .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
                .pNext = null,
                .srcOffset = 0,
                .dstOffset = bufferAndOffset.offset,
                .size = sizes[i],
            }};

            commands.externalCommand(.{
                .copyBuffer = .{
                    .srcBuffer = buffers[i],
                    .dstBuffer = bufferAndOffset.buffer,
                    .regions = &copyRegion,
                },
            }) catch return ResourceError.Unavaliable;
            buffers[i] = bufferAndOffset.buffer;
        }

        return .{ .rType = .render };
    }

    pub fn renderLoad(
        io: Io,
        gpa: Allocator,
        vulkan: *VkStruct,
        commands: *Commands,
        uctx: *Ctx,
        handle: Handle,
        pointer: *Child,
    ) !u32 {
        _ = io;
        _ = gpa;
        _ = vulkan;
        _ = handle;
        _ = commands;

        const index = uctx.meshes.addMesh(
            pointer.sizes[0],
            pointer.sizes[1],
            pointer.sizes[2],
            pointer.sizes[3],
            pointer.stride,
        ) catch return Handles.Invalid;

        return index;
    }
};
