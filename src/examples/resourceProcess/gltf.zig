const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const assert = std.debug.assert;

const tables = @import("tables");

const resourceProcess = @import("../resourceProcess.zig");
const PreProcessParm = resourceProcess.PreProcessParm;
const ProcessType = resourceProcess.ProcessType;

const judgeFileTypeByContent = resourceProcess.judgeFileTypeByContent;

const vtx = @import("vtx.zig");

const db = @import("db");
const cgltf = @import("cgltf");
const vertexStruct = @import("vertexStruct");
const meshopt = @import("meshopt");
const hash = @import("blake_hash");
const sqlDB = @import("sqlDb");
const UUID = @import("UUID");

const VTX_Mem = vtx.VTX_Mem;

const SceneFileName = resourceProcess.SceneFileName;

pub const GLTF = "glTF";

// var SceneJson = resourceProcess.SceneJson;
// var SceneNameStringMap = resourceProcess.SceneNameStringMap;
// var SceneNodeNames = resourceProcess.SceneNodeNames;

// var fileDbParamMap = resourceProcess.fileDbParamMap;
// var contentFolder = resourceProcess.contentFolder;

pub const GLTF_Cooker = struct {
    pub const TableName = "ModelLoadParameterT";
    pub const Enable = true;

    const TableType = tables.ModelLoadParameter;

    pub fn preProcess(
        io: Io,
        gpa: Allocator,
        dir: Io.Dir,
        parmas: *PreProcessParm,
        // rpZ: []const u8,
        // slash: []const u8,
        // parentID: []const u8,
        // SceneJson: void,
        // SceneNameStringMap: void,
        // SceneNodeNames: void,
        ModelLoadParameterT: *TableType,
    ) !void {
        _ = ModelLoadParameterT;
        std.log.debug("file name {s}", .{parmas.fileName});
        var res = try cgltf.loadGltfFile(parmas.content, gpa);
        defer res.arenaAllocator.deinit();

        // const arena = SceneJson.arena.allocator();

        for (res.primitives) |value| {
            const vertex_opted = try optimizeVertex(value.vertex, value.index, gpa);

            // const vertex = @as([*]vertexStruct.Vertex_f3pf3nf3tf2u, @ptrCast(@alignCast(vertex_opted.remap.vertices)))[0..vertex_opted.remap.newVertexCount];
            // for (vertex) |i| {
            //     std.log.debug("{d} {d} {d}", .{ i.position[0], i.position[1], i.position[2] });
            // }

            // for (vertex_opted.remap.indices) |i| {
            //     std.log.debug("{d}", .{i});
            // }

            defer {
                gpa.free(vertex_opted.remap.indices);
                const vertices = @as([*]u8, @ptrCast(@alignCast(vertex_opted.remap.vertices)))[0..vertex_opted.remap.totalVerticesSize];
                gpa.free(vertices);
            }
            const meshlets = try meshopt.clusterization(
                @ptrCast(@alignCast(vertex_opted.remap.vertices)),
                vertex_opted.remap.newVertexCount,
                vertex_opted.remap.vertexSize,
                vertex_opted.remap.indices,
                gpa,
            );
            defer {
                gpa.free(meshlets.meshlets);
                gpa.free(meshlets.meshlet_vertices);
                gpa.free(meshlets.meshlet_triangles);
            }

            const indicesBytes: []u8 = std.mem.sliceAsBytes(vertex_opted.remap.indices);
            const verticeBytes: []u8 =
                std.mem.sliceAsBytes(@as([*]u8, @ptrCast(@alignCast(vertex_opted.remap.vertices)))[0 .. vertex_opted.remap.newVertexCount * vertex_opted.remap.vertexSize]);
            const meshletsBytes: []u8 = std.mem.sliceAsBytes(meshlets.meshlets);
            const meshletVerticesBytes: []u8 = std.mem.sliceAsBytes(meshlets.meshlet_vertices);
            const meshletTrianglesBytes: []u8 = std.mem.sliceAsBytes(meshlets.meshlet_triangles);
            var meshMem = try gpa.alloc(
                u8,
                indicesBytes.len + meshletsBytes.len + meshletVerticesBytes.len + meshletTrianglesBytes.len + verticeBytes.len,
            );
            defer gpa.free(meshMem);

            {
                const meshletsStart = verticeBytes.len;
                const meshletVerticesStart = meshletsStart + meshletsBytes.len;
                const meshletTrianglesStart = meshletVerticesStart + meshletVerticesBytes.len;
                const indicesStart = meshletTrianglesStart + meshletTrianglesBytes.len;

                @memcpy(meshMem[0..meshletsStart], verticeBytes);
                @memcpy(meshMem[meshletsStart..meshletVerticesStart], meshletsBytes);
                @memcpy(meshMem[meshletVerticesStart..meshletTrianglesStart], meshletVerticesBytes);
                @memcpy(meshMem[meshletTrianglesStart..indicesStart], meshletTrianglesBytes);
                @memcpy(meshMem[indicesStart..], indicesBytes);
            }

            const hashh = hash.blake3HashContent(meshMem);

            var buffer = [_:0]u8{0} ** 256;
            const primFileName = try std.fmt.bufPrintZ(&buffer, "{s}.vtx", .{value.name});
            checkGltfPrimitiveName(parmas.ContentPathT, value.name) catch {
                var blob: sqlDB.BLOBForGet = undefined;
                var anys = [_]*anyopaque{&blob};
                var types = [_]sqlDB.innerType{.BLOB};

                parmas.ContentPathT.get(
                    "ContentHash",
                    null,
                    "FileName = ?",
                    .{primFileName},
                    &anys,
                    &types,
                ) catch return;

                const same = std.mem.eql(u8, &hashh, blob.data[0..blob.len]);
                if (same) return;
            };

            var primFile = try dir.createFile(io, primFileName, .{
                .read = true,
                .truncate = true,
            });
            defer primFile.close(io);

            var primFileWriter = primFile.writer(io, &buffer);
            try primFileWriter.interface.writeAll(meshMem);

            const uuidBuffer = try gpa.alloc(u8, UUID.len);

            var anys = [_]*anyopaque{@ptrCast(uuidBuffer.ptr)};
            var types = [_]sqlDB.innerType{.TEXT};

            parmas.ContentPathT.get(
                "UUID",
                null,
                "FileName = ?",
                .{parmas.fileName},
                &anys,
                &types,
            ) catch return;

            const primFileParm = try gpa.alloc(u8, @sizeOf(VTX_Mem));

            var ptr = VTX_Mem{
                .vType = @as(u32, @intFromEnum(vertex_opted.vType)),
                .verticeBytesLen = verticeBytes.len,
                .meshletsBytesLen = meshletsBytes.len,
                .meshletVerticesBytesLen = meshletVerticesBytes.len,
                .meshletTrianglesBytesLen = meshletTrianglesBytes.len,
                .fileUUID = uuidBuffer,
                .hash = hashh,
            };
            @memcpy(primFileParm, std.mem.asBytes(&ptr));

            const dupePrimFileName = try gpa.dupeZ(u8, primFileName);

            try resourceProcess.fileDbParamMap.put(dupePrimFileName, primFileParm);
        }

        const arena = resourceProcess.SceneJson.arena.allocator();
        const initSceneCount = resourceProcess.SceneJson.value.?.len;
        var sceneAdd: usize = 0;
        var currentIndex: usize = initSceneCount + sceneAdd;
        for (res.scenes) |scene| {
            const scene_name = try arena.dupe(u8, scene.name);
            const getRes = try resourceProcess.SceneNameStringMap.getOrPut(scene_name);

            var scenePtr: *cgltf.Scene = undefined;

            if (getRes.found_existing) {
                currentIndex = getRes.value_ptr.*;

                scenePtr = &resourceProcess.SceneJson.value.?[currentIndex];
            } else {
                currentIndex = initSceneCount + sceneAdd;

                resourceProcess.SceneJson.value = try arena.realloc(resourceProcess.SceneJson.value.?, initSceneCount + sceneAdd + 1);
                scenePtr = &resourceProcess.SceneJson.value.?[currentIndex];

                getRes.value_ptr.* = @intCast(currentIndex);

                resourceProcess.SceneNodeNames = try arena.realloc(resourceProcess.SceneNodeNames, initSceneCount + sceneAdd + 1);
                resourceProcess.SceneNodeNames[currentIndex] = .init(arena);

                scenePtr.nodes = &.{};
                scenePtr.name = scene_name;

                sceneAdd += 1;
            }

            const initNodeCount = scenePtr.nodes.len;
            var nodeAdd: usize = 0;

            for (scene.nodes, 0..) |node, j| {
                _ = j;
                const node_name = try arena.dupe(u8, node.name);
                const node_getRes = try resourceProcess.SceneNodeNames[currentIndex].getOrPut(node_name);

                var nodePtr: *cgltf.Node = undefined;

                if (node_getRes.found_existing) {
                    nodePtr = &scenePtr.nodes[node_getRes.value_ptr.*];
                } else {
                    scenePtr.nodes = try arena.realloc(scenePtr.nodes, initNodeCount + nodeAdd + 1);
                    nodePtr = &scenePtr.nodes[initNodeCount + nodeAdd];

                    node_getRes.value_ptr.* = @intCast(initNodeCount + nodeAdd);

                    nodePtr.primitiveNames = &.{};
                    nodePtr.name = node_name;
                    nodePtr.transform = node.transform;

                    nodeAdd += 1;
                }

                const initPrimitiveCount = nodePtr.primitiveNames.len;

                var primNameMap = std.StringHashMap(void).init(arena);
                defer primNameMap.deinit();

                for (nodePtr.primitiveNames, 0..) |primName, k| {
                    _ = k;
                    try primNameMap.put(primName, {});
                }

                var primAdd: usize = 0;

                for (node.primitiveNames, 0..) |primName, k| {
                    _ = k;
                    const primNameGetRes = try primNameMap.getOrPut(primName);

                    if (primNameGetRes.found_existing) {
                        return;
                    } else {
                        nodePtr.primitiveNames = try arena.realloc(
                            nodePtr.primitiveNames,
                            initPrimitiveCount + primAdd + 1,
                        );

                        nodePtr.primitiveNames[primAdd + initPrimitiveCount] = try arena.dupe(u8, primName);

                        primAdd += 1;
                    }
                }
            }
        }
        try saveSceneJson(io, resourceProcess.contentFolder);
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
        _ = fType;
        if (std.mem.eql(u8, content[0..GLTF.len], @constCast(GLTF))) {
            return .GLTF;
        }
        return judgeFileTypeByContent(content);
    }

    fn optimizeVertex(vertex: vertexStruct.Vertex, index: []u32, allocator: std.mem.Allocator) !struct {
        remap: meshopt.remapReturn,
        vType: vertexStruct.VertexType,
    } {
        const vertexInfo = cgltf.unpackVertex(vertex);
        std.log.debug("count {d}, size {d}", .{ vertexInfo.vertexCount, vertexInfo.vertexSize });

        const analyze1 = meshopt.analyzeVertex(
            index,
            @ptrCast(@alignCast(vertexInfo.vertices)),
            vertexInfo.vertexCount,
            vertexInfo.vertexSize,
        );
        std.log.debug("acmr {d}, atvr {d}, overfetch {d}, overdraw {d}", .{
            analyze1.vertexCache.acmr,
            analyze1.vertexCache.atvr,
            analyze1.vertexFetch.overfetch,
            analyze1.overdraw.overdraw,
        });

        const res2 = try meshopt.generateVertexRemap(
            index,
            vertexInfo.vertices,
            vertexInfo.vertexCount,
            vertexInfo.vertexSize,
            allocator,
        );
        defer {
            allocator.free(res2.indices);
            const vertices = @as([*]u8, @ptrCast(@alignCast(res2.vertices)))[0 .. res2.newVertexCount * vertexInfo.vertexSize];
            allocator.free(vertices);
        }

        const res3 = try meshopt.vertexOptimization(
            res2.indices,
            @ptrCast(@alignCast(res2.vertices)),
            res2.newVertexCount,
            vertexInfo.vertexSize,
            allocator,
        );
        // defer {
        //     allocator.free(res3.indices);
        //     const vertices = @as([*]u8, @ptrCast(@alignCast(res3.vertices)))[0 .. res2.vertexCount * vertexInfo.vertexSize];
        //     allocator.free(vertices);
        // }

        const analyze2 = meshopt.analyzeVertex(
            res3.indices,
            @ptrCast(@alignCast(res3.vertices)),
            res3.newVertexCount,
            vertexInfo.vertexSize,
        );
        std.log.debug("acmr {d}, atvr {d}, overfetch {d}, overdraw {d}", .{
            analyze2.vertexCache.acmr,
            analyze2.vertexCache.atvr,
            analyze2.vertexFetch.overfetch,
            analyze2.overdraw.overdraw,
        });

        // const vertex = cgltf.packVertex(.{
        //     .vertices = res3.vertices.?,
        //     .vertexCount = @intCast(res3.vertexCount),
        //     .vertexSize = vertexInfo.vertexSize,
        // }, std.meta.activeTag(value.vertex));

        std.log.debug("count {d}, size {d}", .{ res3.newVertexCount, vertexInfo.vertexSize });
        // cgltf.printVertex(vertex, res3.indices);

        return .{ .remap = res3, .vType = std.meta.activeTag(vertex) };
    }

    fn checkGltfPrimitiveName(
        ContentPathT: *tables.ContentPath,
        name: []const u8,
    ) !void {
        const have = try ContentPathT.have("FileName", "FileName = ?", .{name});
        if (have) {
            return error.Duplicated;
        }
    }
};

pub fn saveSceneJson(io: std.Io, content: std.Io.Dir) !void {
    var sceneFile = content.openFile(io, SceneFileName, .{ .mode = .read_write }) catch |err| blk: switch (err) {
        error.FileNotFound => break :blk try content.createFile(io, SceneFileName, .{ .read = true }),
        else => return err,
    };
    defer sceneFile.close(io);

    if (resourceProcess.SceneJson.value.?.len > 0) {
        try sceneFile.setLength(io, 0);

        var cacheBuffer = [_]u8{0} ** 1024;
        var sceneFileWriter = sceneFile.writer(io, &cacheBuffer);
        var sceneJsonWrite = std.json.Stringify{
            .writer = &sceneFileWriter.interface,
            .options = .{ .whitespace = .indent_tab },
        };
        try sceneJsonWrite.write(resourceProcess.SceneJson.value);
        try sceneFileWriter.interface.flush();
    }
}
