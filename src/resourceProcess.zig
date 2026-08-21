const std = @import("std");
const Io = std.Io;

const Allocator = std.mem.Allocator;

const assert = std.debug.assert;

const tables = @import("tables");
const vk = @import("vulkan");
const cgltf = @import("cgltf");
const vertexStruct = @import("vertexStruct");
const meshopt = @import("meshopt");
const hash = @import("blake_hash");
const sqlDB = @import("sqlDb");
const UUID = @import("UUID");
const sampler = @import("sampler");
const pipelineParse = @import("pipelinrParse");
const db = @import("db");

pub const preProcessInitFn = fn (gpa: Allocator) anyerror!void;

pub const fileDbParamMapType = std.StringHashMap([]u8);
pub const PreProcessParm = struct {
    ContentPathT: *tables.ContentPath,
    fileName: []const u8,
    content: []const u8,
    // mem: []const u8,
    // fileUUID: []const u8,
    // fileDbParamMap: *fileDbParamMapType,
};

const HandleType = @import("handle").ResourceType;
pub const ProcessType_HandleType = struct {
    type1: ProcessType,
    type2: HandleType,
};

const PNG = [_]u8{
    0x89,
    std.mem.bytesToValue(u8, "P"),
    std.mem.bytesToValue(u8, "N"),
    std.mem.bytesToValue(u8, "G"),
};
const GLTF = "glTF";

pub const ProcessType = enum {
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
    GLTF,
    VTX,
    HASHTABLE,
    Shader,
    Pipeline,
    PipeB,
    Sampler,
    SamplerB,
    KTX2,
    UNKNOWN,
    // add here
};

const KV = struct {
    []const u8,
    ProcessType,
};
pub const list = [_]KV{
    .{ "", ProcessType.DIR },
    .{ ".obj", ProcessType.OBJ },
    .{ ".mtl", ProcessType.MTL },
    .{ ".png", ProcessType.PNG },
    .{ ".tsdI", ProcessType.TSDI },
    .{ ".tsd", ProcessType.TSD },
    .{ ".ttf", ProcessType.TTF },
    .{ ".wav", ProcessType.WAV },
    .{ ".spv", ProcessType.SPV },
    .{ ".txt", ProcessType.TXT },
    .{ ".gltf", ProcessType.GLTF },
    .{ ".glb", ProcessType.GLTF },
    .{ ".vtx", ProcessType.VTX },
    .{ ".frag", ProcessType.Shader },
    .{ ".vert", ProcessType.Shader },
    .{ ".comp", ProcessType.Shader },
    .{ ".mesh", ProcessType.Shader },
    .{ ".task", ProcessType.Shader },
    .{ ".pipe", ProcessType.Pipeline },
    .{ ".samp", ProcessType.Sampler },
    .{ ".pipeb", ProcessType.PipeB },
    .{ ".sampler", ProcessType.SamplerB },
    .{ ".ktx2", ProcessType.KTX2 },
};

pub const Mappings = [_]ProcessType_HandleType{
    // add here
};

const SceneFileName = "Scenes.json";

var fileDbParamMap: fileDbParamMapType = undefined;

var SceneJson: std.json.Parsed(?[]cgltf.Scene) = undefined;
var SceneNameStringMap: std.StringHashMap(u32) = undefined;
var SceneNodeNames: []std.StringHashMap(u32) = undefined;

var contentFolder: Io.Dir = undefined;

fn initFileParameterMap(gpa: Allocator) void {
    fileDbParamMap = .init(gpa);
}

fn sceneJsonInit(io: Io, gpa: Allocator, content: std.Io.Dir) !void {
    var sceneFile = content.openFile(io, SceneFileName, .{ .mode = .read_write }) catch |err| blk: switch (err) {
        error.FileNotFound => break :blk try content.createFile(io, SceneFileName, .{ .read = true }),
        else => return err,
    };
    {
        defer sceneFile.close(io);

        const sceneFileStat = try sceneFile.stat(io);
        var cacheBuffer = [_]u8{0} ** 256;
        var sceneFileReader = sceneFile.reader(io, &cacheBuffer);
        const sceneContent = try sceneFileReader.interface.readAlloc(gpa, sceneFileStat.size);
        defer gpa.free(sceneContent);

        SceneNameStringMap = .init(gpa);

        if (sceneFileStat.size != 0) {
            try sceneFile.setLength(io, 0);
            try sceneFileReader.seekTo(0);

            SceneJson = try std.json.parseFromSlice(?[]cgltf.Scene, gpa, sceneContent, .{});

            const arena = SceneJson.arena.allocator();

            if (SceneJson.value) |v| {
                SceneNodeNames = try arena.alloc(std.StringHashMap(u32), v.len);
                for (v, 0..) |value, i| {
                    const name_dupe = try arena.dupe(u8, value.name);
                    try SceneNameStringMap.put(name_dupe, @intCast(i));

                    SceneNodeNames[i] = .init(arena);

                    for (value.nodes, 0..) |node, j| {
                        const node_name = try arena.dupe(u8, node.name);

                        try SceneNodeNames[i].put(node_name, @intCast(j));
                    }
                }
            }
        } else {
            SceneJson = .{
                .arena = try gpa.create(std.heap.ArenaAllocator),
                .value = &.{},
            };
            SceneJson.arena.* = std.heap.ArenaAllocator.init(gpa);
        }
    }
}

fn saveSceneJson(io: std.Io, content: std.Io.Dir) !void {
    var sceneFile = content.openFile(io, SceneFileName, .{ .mode = .read_write }) catch |err| blk: switch (err) {
        error.FileNotFound => break :blk try content.createFile(io, SceneFileName, .{ .read = true }),
        else => return err,
    };
    defer sceneFile.close(io);

    if (SceneJson.value.?.len > 0) {
        try sceneFile.setLength(io, 0);

        var cacheBuffer = [_]u8{0} ** 1024;
        var sceneFileWriter = sceneFile.writer(io, &cacheBuffer);
        var sceneJsonWrite = std.json.Stringify{
            .writer = &sceneFileWriter.interface,
            .options = .{ .whitespace = .indent_tab },
        };
        try sceneJsonWrite.write(SceneJson.value);
        try sceneFileWriter.interface.flush();
    }
}

pub fn preProcessInit(io: Io, gpa: Allocator, content: Io.Dir) !void {
    try sceneJsonInit(io, gpa, content);

    try saveSceneJson(io, content);
    initFileParameterMap(gpa);

    contentFolder = content;
}

pub const Example_Cooker = struct {
    pub const TableName = "ContentPathT";
    pub const Enable = false;
    const TableType = tables.ContentPath;

    pub fn preProcess(
        io: Io,
        gpa: Allocator,
        dir: Io.Dir,
        parmas: *PreProcessParm,
        Table: *TableType,
    ) !void {
        _ = io;
        _ = gpa;
        _ = dir;
        _ = Table;
        _ = parmas;
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

pub const PNG_Cooker = struct {
    pub const TableName = "ImageLoadParameterT";
    pub const Enable = true;

    const TbaleType = tables.ImageLoadParameter;

    pub fn preProcess(
        io: Io,
        gpa: Allocator,
        dir: Io.Dir,
        parmas: *PreProcessParm,
        ImageLoadParameterT: *TbaleType,
    ) !void {
        _ = io;
        _ = gpa;
        _ = dir;

        const format: vk.VkFormat, const tiling: vk.VkImageTiling, const usage: vk.VkImageUsageFlags, const properties: vk.VkMemoryPropertyFlags = try judgeImageLoadParameter(parmas.fileName);

        try ImageLoadParameterT.update("Format,Tiling,Usage,Properties", "FileName = ?", .{ format, tiling, usage, properties, parmas.fileName });
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
        if (std.mem.eql(u8, content[0..PNG.len], @constCast(&PNG))) {
            return .PNG;
        }
        return judgeFileTypeByContent(content);
    }

    fn judgeImageLoadParameter(fileName: []const u8) !struct {
        vk.VkFormat,
        vk.VkImageTiling,
        vk.VkImageUsageFlags,
        vk.VkMemoryPropertyFlags,
    } {
        _ = fileName;
        // var format: vk.VkFormat = 0;
        // var tiling: vk.VkImageTiling = 0;
        // var usage: vk.VkImageUsageFlags = 0;
        // var properties: vk.VkMemoryPropertyFlags = 0;

        // return .{ format, tiling, usage, properties };
        return .{ vk.VK_FORMAT_R8G8B8A8_SRGB, vk.VK_IMAGE_TILING_OPTIMAL, vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT | vk.VK_IMAGE_USAGE_SAMPLED_BIT, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT };
    }
};

fn judgeFileType() !void {}
fn getInsertID() !void {}

const VTX_Mem = struct {
    vType: u32,
    verticeBytesLen: u64,
    meshletsBytesLen: u64,
    meshletVerticesBytesLen: u64,
    meshletTrianglesBytesLen: u64,
    fileUUID: []const u8,
    hash: hash.ReturnType,
};

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

            try fileDbParamMap.put(dupePrimFileName, primFileParm);
        }

        const arena = SceneJson.arena.allocator();
        const initSceneCount = SceneJson.value.?.len;
        var sceneAdd: usize = 0;
        var currentIndex: usize = initSceneCount + sceneAdd;
        for (res.scenes) |scene| {
            const scene_name = try arena.dupe(u8, scene.name);
            const getRes = try SceneNameStringMap.getOrPut(scene_name);

            var scenePtr: *cgltf.Scene = undefined;

            if (getRes.found_existing) {
                currentIndex = getRes.value_ptr.*;

                scenePtr = &SceneJson.value.?[currentIndex];
            } else {
                currentIndex = initSceneCount + sceneAdd;

                SceneJson.value = try arena.realloc(SceneJson.value.?, initSceneCount + sceneAdd + 1);
                scenePtr = &SceneJson.value.?[currentIndex];

                getRes.value_ptr.* = @intCast(currentIndex);

                SceneNodeNames = try arena.realloc(SceneNodeNames, initSceneCount + sceneAdd + 1);
                SceneNodeNames[currentIndex] = .init(arena);

                scenePtr.nodes = &.{};
                scenePtr.name = scene_name;

                sceneAdd += 1;
            }

            const initNodeCount = scenePtr.nodes.len;
            var nodeAdd: usize = 0;

            for (scene.nodes, 0..) |node, j| {
                _ = j;
                const node_name = try arena.dupe(u8, node.name);
                const node_getRes = try SceneNodeNames[currentIndex].getOrPut(node_name);

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
        try saveSceneJson(io, contentFolder);
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

pub const Sampler_Cooker = struct {
    pub const TableName = "ContentPathT";
    pub const Enable = true;
    const TableType = tables.ContentPath;

    pub fn preProcess(
        io: Io,
        gpa: Allocator,
        dir: Io.Dir,
        parmas: *PreProcessParm,
        Table: *TableType,
    ) !void {
        _ = io;
        _ = gpa;
        _ = dir;
        _ = Table;
        _ = parmas;
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
        _ = fullPath;
        _ = database;
        const samplerName = try std.fmt.allocPrint(gpa, "{s}ler", .{fileName});
        defer gpa.free(samplerName);

        const samplerFullPath = try std.fs.path.joinZ(
            gpa,
            &[_][]const u8{
                contentFolderPath,
                "Sampler",
                samplerName,
            },
        );
        defer gpa.free(samplerFullPath);

        sampler.praseSampler(io, content, samplerFullPath, gpa) catch |err| {
            std.log.err("write file {s} failed {s}", .{ samplerFullPath, @errorName(err) });
            return;
        };
    }

    pub fn judgeFileType2(content: []u8, fType: ProcessType) ProcessType {
        _ = content;
        return fType;
    }
};

pub const Pipeline_Cooker = struct {
    pub const TableName = "ContentPathT";
    pub const Enable = true;
    const TableType = tables.ContentPath;

    pub fn preProcess(
        io: Io,
        gpa: Allocator,
        dir: Io.Dir,
        parmas: *PreProcessParm,
        Table: *TableType,
    ) !void {
        _ = io;
        _ = gpa;
        _ = dir;
        _ = Table;
        _ = parmas;
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
        const pipebName = try std.fmt.allocPrintSentinel(
            gpa,
            "{s}b",
            .{fileName},
            0,
        );
        defer gpa.free(pipebName);

        const pipebFullPath = try std.fs.path.joinZ(
            gpa,
            &[_][]const u8{
                contentFolderPath,
                "Pipeline",
                pipebName,
            },
        );
        defer gpa.free(pipebFullPath);

        const shaderFolderFullPath = try std.fs.path.joinZ(
            gpa,
            &[_][]const u8{
                contentFolderPath,
                "Shaders",
            },
        );
        defer gpa.free(shaderFolderFullPath);

        const shaderNames = pipelineParse.pipelineJsonParse(
            io,
            content,
            shaderFolderFullPath,
            pipebFullPath,
            gpa,
        ) catch {
            std.log.err("pipeline json parse failed", .{});
            return;
        };
        defer {
            for (shaderNames) |value| {
                gpa.free(value);
            }
            gpa.free(shaderNames);
        }

        database.ShaderPipelineGraphNodeT.insert(.{
            .Name = fileName.ptr,
            .Path = fullPath.ptr,
            .Type = @as(u32, @intFromEnum(db.NodeType.Pipeline)),
        }) catch {};

        var nodeID: i32 = -1;
        var gets = [_]*anyopaque{@ptrCast(&nodeID)};
        var types = [_]db.innerType{.INTEGER32};
        database.ShaderPipelineGraphNodeT.get(
            "ID",
            null,
            "Name = ?",
            .{fileName},
            &gets,
            &types,
        ) catch {
            std.log.err("get pipeline id failed", .{});
            return;
        };

        database.ShaderPipelineGraphEdgeT.delete("ToNodeID = ?", .{nodeID}) catch {};

        for (shaderNames) |shaderName| {
            const shaderNameNoSpv = gpa.allocSentinel(
                u8,
                shaderName.len - 4,
                0,
            ) catch return;
            defer gpa.free(shaderNameNoSpv);
            @memcpy(shaderNameNoSpv, shaderName[0 .. shaderName.len - 4]);

            var shaderID: i32 = -1;
            var gets2 = [_]*anyopaque{@ptrCast(&shaderID)};
            var types2 = [_]db.innerType{.INTEGER32};
            database.ShaderPipelineGraphNodeT.get(
                "ID",
                null,
                "Name = ?",
                .{shaderNameNoSpv},
                &gets2,
                &types2,
            ) catch {
                // @breakpoint();
                std.log.err("get shader id failed (shader name: {s})", .{
                    shaderNameNoSpv,
                });
                return;
            };

            database.ShaderPipelineGraphEdgeT.insert(.{
                .FromNodeID = shaderID,
                .ToNodeID = nodeID,
            }) catch {
                database.ShaderPipelineGraphEdgeT.update(
                    "FromNodeID",
                    "ToNodeID = ?",
                    .{ shaderID, nodeID },
                ) catch {
                    std.log.err("insert pipeline edge failed", .{});
                    return;
                };
            };
            std.log.debug("{s}", .{shaderName});
        }
    }

    pub fn judgeFileType2(content: []u8, fType: ProcessType) ProcessType {
        _ = content;
        return fType;
    }
};

pub const Shader_Cooker = struct {
    pub const TableName = "ContentPathT";
    pub const Enable = true;
    const TableType = tables.ContentPath;

    pub fn preProcess(
        io: Io,
        gpa: Allocator,
        dir: Io.Dir,
        parmas: *PreProcessParm,
        Table: *TableType,
    ) !void {
        _ = io;
        _ = gpa;
        _ = dir;
        _ = Table;
        _ = parmas;
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
        _ = content;
        var readBuffer = [_]u8{0} ** 64;

        const spvName = try std.fmt.allocPrintSentinel(
            gpa,
            "{s}.spv",
            .{fileName},
            0,
        );
        defer gpa.free(spvName);

        const spvFullPath = try std.fs.path.joinZ(
            gpa,
            &[_][]const u8{
                contentFolderPath,
                "Shaders",
                spvName,
            },
        );
        defer gpa.free(spvFullPath);

        const runRes = try std.process.run(gpa, io, .{
            .argv = &[_][]const u8{ "glslc", "--target-env=vulkan1.4", "-o", spvFullPath, fullPath },
        });
        defer {
            gpa.free(runRes.stderr);
            gpa.free(runRes.stdout);
        }

        std.log.err("{s}", .{runRes.stderr});
        std.log.debug("{s}", .{runRes.stdout});

        switch (runRes.term) {
            .exited => |code| {
                if (code != 0) {
                    std.debug.print("Command failed with code: {d}\n", .{code});
                }
            },
            .signal => |sig| {
                _ = sig;
                std.debug.print("Process killed by signal: \n", .{});
            },
            .stopped => |sig| {
                _ = sig;
                std.debug.print("Process stopped: \n", .{});
            },
            .unknown => |val| {
                std.debug.print("Process exited with unknown code: {d}\n", .{val});
            },
        }

        const nodeType_u32: u32 = @intFromEnum(db.NodeType.Shader);
        database.ShaderPipelineGraphNodeT.insert(.{
            .Name = fileName.ptr,
            .Path = fullPath.ptr,
            .Type = nodeType_u32,
        }) catch {
            std.log.err("insert shader failed", .{});
        };

        var fromNodeID: i32 = -1;
        var gets = [_]*anyopaque{@ptrCast(&fromNodeID)};
        var types = [_]db.innerType{.INTEGER32};
        database.ShaderPipelineGraphNodeT.get(
            "ID",
            null,
            "Name = ?",
            .{fileName},
            &gets,
            &types,
        ) catch {
            std.log.err("get shader id failed", .{});
            return;
        };

        var pipelineCount: u32 = 0;

        database.ShaderPipelineGraphEdgeT.gets(
            "ToNodeID",
            null,
            "FromNodeID = ?",
            .{fromNodeID},
            null,
            null,
            &pipelineCount,
        ) catch {
            std.log.err("get pipeline count failed", .{});
            return;
        };

        if (pipelineCount > 0) {
            const getValues = gpa.alloc([]*anyopaque, pipelineCount) catch return;
            defer gpa.free(getValues);
            const ToNodeIDs = gpa.alloc(u32, pipelineCount) catch return;
            defer gpa.free(ToNodeIDs);
            for (getValues, 0..) |*value, i| {
                value.* = gpa.alloc(*anyopaque, 1) catch return;
                value.*[0] = @ptrCast(&ToNodeIDs[i]);
            }
            defer for (getValues) |value| gpa.free(value);

            database.ShaderPipelineGraphEdgeT.gets(
                "ToNodeID",
                null,
                "FromNodeID = ?",
                .{fromNodeID},
                getValues,
                &types,
                &pipelineCount,
            ) catch {
                std.log.err("get pipeline count failed", .{});
                return;
            };

            for (ToNodeIDs) |value| {
                var pipelinePath = [_]u8{0} ** 256;
                var pipelineGets = [_]*anyopaque{&pipelinePath};
                var pipelineTypes = [_]db.innerType{.TEXT};
                database.ShaderPipelineGraphNodeT.get(
                    "Path",
                    null,
                    "ID = ?",
                    .{value},
                    &pipelineGets,
                    &pipelineTypes,
                ) catch {
                    std.log.err("get pipeline path failed", .{});
                    return;
                };

                const pipelinePathLen = std.mem.len(@as([*c]u8, @ptrCast(&pipelinePath)));

                var pipelineNameStart = std.mem.findLast(
                    u8,
                    pipelinePath[0..pipelinePathLen],
                    "\\",
                );
                if (pipelineNameStart == null) {
                    pipelineNameStart = 0;
                } else {
                    pipelineNameStart.? += 1;
                }

                const pipebName = try std.fmt.allocPrintSentinel(
                    gpa,
                    "{s}b",
                    .{pipelinePath[pipelineNameStart.?..pipelinePathLen]},
                    0,
                );
                defer gpa.free(pipebName);

                const pipebFullPath = try std.fs.path.joinZ(
                    gpa,
                    &[_][]const u8{
                        contentFolderPath,
                        "Pipeline",
                        pipebName,
                    },
                );
                defer gpa.free(pipebFullPath);

                const shaderFolderFullPath = try std.fs.path.joinZ(
                    gpa,
                    &[_][]const u8{
                        contentFolderPath,
                        "Shaders",
                    },
                );
                defer gpa.free(shaderFolderFullPath);

                const pipelineFile = std.Io.Dir.openFileAbsolute(
                    io,
                    pipelinePath[0..pipelinePathLen],
                    .{},
                ) catch |err| {
                    std.log.err(
                        "failed to open pipeline file {s} {s}",
                        .{ pipelinePath[0..pipelinePathLen], @errorName(err) },
                    );
                    return;
                };

                const pipelineFileStat = pipelineFile.stat(io) catch |err| {
                    std.log.err(
                        "failed to stat pipeline file {s} {s}",
                        .{ pipelinePath[0..pipelinePathLen], @errorName(err) },
                    );
                    return;
                };

                var pipelineReader = pipelineFile.reader(io, &readBuffer);
                const pipelineContent = try pipelineReader.interface.readAlloc(gpa, pipelineFileStat.size);
                defer gpa.free(pipelineContent);

                const shaderNames = pipelineParse.pipelineJsonParse(
                    io,
                    pipelineContent,
                    shaderFolderFullPath,
                    pipebFullPath,
                    gpa,
                ) catch |err| {
                    std.log.err("pipeline json parse failed {s}", .{@errorName(err)});
                    return;
                };
                defer {
                    for (shaderNames) |shaderName| {
                        gpa.free(shaderName);
                    }
                    gpa.free(shaderNames);
                }
                // std.log.debug("ID {d}", .{value});
            }
        }
    }

    pub fn judgeFileType2(content: []u8, fType: ProcessType) ProcessType {
        _ = content;
        return fType;
    }
};

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

        const mem = fileDbParamMap.get(parmas.fileName) orelse return;
        assert(@sizeOf(VTX_Mem) == mem.len);

        defer {
            if (fileDbParamMap.getEntry(parmas.fileName)) |e| {
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

pub const DIR_Cooker = Example_Cooker;
pub const OBJ_Cooker = Example_Cooker;
pub const MTL_Cooker = Example_Cooker;
pub const TSDI_Cooker = Example_Cooker;
pub const TSD_Cooker = Example_Cooker;
pub const TTF_Cooker = Example_Cooker;
pub const WAV_Cooker = Example_Cooker;
pub const SPV_Cooker = Example_Cooker;
pub const TXT_Cooker = Example_Cooker;

pub const HASHTABLE_Cooker = Example_Cooker;
pub const PipeB_Cooker = Example_Cooker;
pub const SamplerB_Cooker = Example_Cooker;
pub const KTX2_Cooker = Example_Cooker;
pub const UNKNOWN_Cooker = Example_Cooker;

pub fn judgeFileTypeByContent(content: []u8) ProcessType {
    if (std.mem.eql(u8, content, @constCast(&PNG))) {
        return .PNG;
    } else if (std.mem.eql(u8, content, @constCast(GLTF))) {
        return .GLTF;
    } else {
        return .UNKNOWN;
    }
}
