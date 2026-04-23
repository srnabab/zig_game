const sqlDB = @import("sqlDb");
const sqlite = sqlDB.sqlite;
const std = @import("std");
const builtin = @import("builtin");
pub const UUID = @import("UUID");
const hash = @import("blake_hash");
const reflect = @import("reflect");
const vk = reflect.vk;
const tables = @import("tables");
const cgltf = @import("cgltf");
const vertexStruct = @import("vertexStruct");
const meshopt = @import("meshopt");
const Types = @import("types");

const assert = std.debug.assert;

const SceneFileName = "Scenes.json";

const ShaderLoad = struct { subPath: []const u8, len: usize };

const FileData = union {
    shader: ShaderLoad,
};

const FileType = Types.FileType;

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

const PNG = [_]u8{
    0x89,
    std.mem.bytesToValue(u8, "P"),
    std.mem.bytesToValue(u8, "N"),
    std.mem.bytesToValue(u8, "G"),
};
const GLTF = "glTF";

const FileTypeHashTable = map: {
    const maptype = std.StaticStringMap(FileType);
    const KV = struct {
        []const u8,
        FileType,
    };
    const list = [_]KV{
        .{ "", FileType.DIR },
        .{ ".obj", FileType.OBJ },
        .{ ".mtl", FileType.MTL },
        .{ ".png", FileType.PNG },
        .{ ".tsdI", FileType.TSDI },
        .{ ".tsd", FileType.TSD },
        .{ ".ttf", FileType.TTF },
        .{ ".wav", FileType.WAV },
        .{ ".spv", FileType.SPV },
        .{ ".txt", FileType.TXT },
        .{ ".gltf", FileType.GLTF },
        .{ ".glb", FileType.GLTF },
        .{ ".vtx", FileType.VTX },
    };

    const maps = maptype.initComptime(list);
    break :map maps;
};

fn executeSQL(SQL: []const u8, db_: *sqlite.sqlite3) void {
    const res = sqlite.sqlite3_exec(db_, @ptrCast(SQL.ptr), null, null, null);

    if (res != sqlite.SQLITE_OK) {
        std.log.err("{s}\n{s}", .{ sqlite.sqlite3_errmsg(db_), SQL });
    }
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

fn updateLoadParameter(
    io: std.Io,
    dir: std.Io.Dir,
    parentID: []const u8,
    tp: FileType,
    cc: std.Io.File.Stat,
    content: []const u8,
    fileName: []const u8,
    rpZ: []const u8,
) !void {
    switch (tp) {
        .PNG => {
            const format: vk.VkFormat, const tiling: vk.VkImageTiling, const usage: vk.VkImageUsageFlags, const properties: vk.VkMemoryPropertyFlags = try judgeImageLoadParameter(fileName);

            try ImageLoadParameterT.update("Format,Tiling,Usage,Properties", "FileName = ?", .{ format, tiling, usage, properties, fileName });
        },
        .GLTF => {
            std.log.debug("file name {s}", .{fileName});
            var res = try cgltf.loadGltfFile(content, cc, gpa);
            defer res.arenaAllocator.deinit();

            const arena = SceneJson.arena.allocator();

            var modelNameToNewName = std.StringHashMap([]u8).init(arena);
            defer modelNameToNewName.deinit();

            for (res.primitives) |value| {
                const vertex_opted = try optimizeVertex(value.vertex, value.index, gpa);
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
                var meshMem = try arena.alloc(
                    u8,
                    indicesBytes.len + meshletsBytes.len + meshletVerticesBytes.len + meshletTrianglesBytes.len + verticeBytes.len,
                );
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
                var primFileName = try std.fmt.bufPrintZ(&buffer, "{s}.vtx", .{value.name});

                const have = try ContentPathT.have("FileName", "FileName = ?", .{primFileName});
                if (have) {
                    const have3 = try ContentPathT.have(
                        "ContentHash",
                        "ContentHash = ?",
                        .{sqlDB.BLOB{ .data = &hashh, .len = hashh.len }},
                    );
                    if (have3) {
                        continue;
                    }

                    primFileName = try std.fmt.bufPrintZ(&buffer, "{s}_{s}.vtx", .{
                        value.name,
                        std.fmt.bytesToHex(hashh, .lower),
                    });

                    const name_dupe = try arena.dupe(u8, value.name);
                    const primFileName_dupe = try arena.dupe(u8, primFileName);

                    try modelNameToNewName.put(name_dupe, primFileName_dupe);

                    const have2 = try ContentPathT.have("FileName", "FileName = ?", .{primFileName});
                    if (have2) {
                        continue;
                    }
                }

                var primFile = try dir.createFile(io, primFileName, .{ .read = true });
                defer primFile.close(io);

                var primFileWriter = primFile.writer(io, &buffer);
                try primFileWriter.interface.writeAll(meshMem);

                {
                    const time: i64 = @truncate(std.Io.Timestamp.now(io, .real).toNanoseconds());
                    const metadata = primFile.stat(io) catch |err| blk: switch (err) {
                        error.AccessDenied => {
                            try std.Io.sleep(
                                io,
                                std.Io.Duration{ .nanoseconds = std.time.ns_per_ms },
                                .real,
                            );
                            break :blk try primFile.stat(io);
                        },
                        else => return err,
                    };

                    var relativePathBuffer = [_]u8{0} ** 256;
                    const relativePathZ = try std.fmt.bufPrintZ(&relativePathBuffer, "{s}{s}{s}", .{ rpZ, slash, primFileName });

                    var uuidBuffer = [_:0]u8{0} ** UUID.len;
                    try UUID.createNewUUID(&uuidBuffer);
                    const sufffix_index = std.mem.lastIndexOf(u8, primFileName, ".") orelse primFileName.len;
                    const fType = judgeFileType(primFileName[sufffix_index..], meshMem);

                    try ContentPathT.insert(.{
                        .ID = @intCast(getInsertID()),
                        .UUID = @constCast(&uuidBuffer),
                        .ParentUUID = @constCast(parentID.ptr),
                        .RelativePath = @constCast(relativePathZ.ptr),
                        .FileName = @constCast(primFileName.ptr),
                        .TYPE = @intFromEnum(metadata.kind),
                        .FileSize = @intCast(metadata.size),
                        .ContentHash = sqlDB.BLOB{ .data = &hashh, .len = hash.blake3.BLAKE3_OUT_LEN },
                        .ModifiedTime = @as(i64, @truncate(metadata.mtime.toNanoseconds())),
                        .LastSeenTime = time,
                        .FileType = @intFromEnum(fType),
                    });

                    const relativePathZ2 = try std.fmt.bufPrintZ(&relativePathBuffer, "{s}{s}{s}", .{ rpZ, slash, fileName });

                    var anys = [_]*anyopaque{&uuidBuffer};
                    var types = [_]sqlDB.innerType{.TEXT};

                    try ContentPathT.get(
                        "UUID",
                        null,
                        "RelativePath = ?",
                        .{relativePathZ2},
                        &anys,
                        &types,
                    );

                    try ModelLoadParameterT.update(
                        "VertexType,VerticesSize,MeshletsSize,MeshletVerticesSize,MeshletTrianglesSize,ParentModelFile",
                        "ContentHash = ?",
                        .{
                            @as(u32, @intFromEnum(vertex_opted.vType)),
                            verticeBytes.len,
                            meshletsBytes.len,
                            meshletVerticesBytes.len,
                            meshletTrianglesBytes.len,
                            uuidBuffer,
                            sqlDB.BLOB{ .data = &hashh, .len = hash.blake3.BLAKE3_OUT_LEN },
                        },
                    );
                }
                // try processFile(dir, primFileName, rPZ, parentID, -1, -1);
            }

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
                            continue;
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
        },
        else => {},
    }
}

fn judgeFileTypeByContent(content: []u8) FileType {
    if (std.mem.eql(u8, content, @constCast(&PNG))) {
        return .PNG;
    } else if (std.mem.eql(u8, content, @constCast(GLTF))) {
        return .GLTF;
    } else {
        return .UNKNOWN;
    }
}

pub fn judgeFileType(suffix: []const u8, content: []u8) FileType {
    const fType = FileTypeHashTable.get(suffix) orelse FileType.UNKNOWN;

    switch (fType) {
        .PNG => {
            if (std.mem.eql(u8, content[0..PNG.len], @constCast(&PNG))) {
                return .PNG;
            }
            return judgeFileTypeByContent(content);
        },
        .GLTF => {
            if (std.mem.eql(u8, content[0..GLTF.len], @constCast(GLTF))) {
                return .GLTF;
            }
            return judgeFileTypeByContent(content);
        },
        .UNKNOWN => {
            return judgeFileTypeByContent(content);
        },
        else => {
            return fType;
        },
    }
}

fn getDbModifiedTime(comptime where_clause: []const u8, params: anytype) !i64 {
    var modifiedTime: i64 = -1;
    var getValues: [1]*anyopaque = .{@ptrCast(&modifiedTime)};
    var types = [_]sqlDB.innerType{.INTEGER};

    ContentPathT.get("ModifiedTime", null, where_clause, params, &getValues, &types) catch |err| switch (err) {
        sqlDB.sqliteError.SQLError => return err,
        // 如果没找到，就返回 -1
        sqlDB.sqliteError.StepError, sqlDB.sqliteError.Empty => return -1,
    };
    return modifiedTime;
}

pub fn processFile(
    io: std.Io,
    dir: std.Io.Dir,
    name: []const u8,
    rPZ: []const u8,
    parentID: []const u8,
) !FileType {
    const time: i64 = @truncate(std.Io.Timestamp.now(io, .real).toNanoseconds());
    // std.log.debug("time {d} {s}", .{ time, name });
    var tempFile = try dir.openFile(io, name, .{});
    defer tempFile.close(io);

    const metadata = try tempFile.stat(io);
    const currentModifiedTime: i64 = @truncate(metadata.mtime.toNanoseconds());

    const fileModifiedTime = try getDbModifiedTime("FileName = ?", .{name});
    const pathModifiedTime = try getDbModifiedTime("RelativePath = ?", .{rPZ});

    var fileBuffer = [_]u8{0} ** 256;

    var fType: FileType = .UNKNOWN;

    if (fileModifiedTime == -1) {
        // 新文件：插入新记录
        var uuidBuffer = [_]u8{0} ** UUID.len;
        try UUID.createNewUUID(&uuidBuffer);
        const index = std.mem.lastIndexOf(u8, name, ".") orelse name.len;

        var fileReader = tempFile.reader(io, &fileBuffer);
        const content = try fileReader.interface.readAlloc(gpa, metadata.size);
        defer gpa.free(content);
        // _ = try tempFile.readAll(content);

        var hashh = hash.blake3HashContent(content[0..metadata.size]);

        fType = judgeFileType(name[index..], content);

        try ContentPathT.insert(.{
            .ID = @intCast(getInsertID()),
            .UUID = @constCast(&uuidBuffer),
            .ParentUUID = @constCast(parentID.ptr),
            .RelativePath = @constCast(rPZ.ptr),
            .FileName = @constCast(name.ptr),
            .TYPE = @intFromEnum(metadata.kind),
            .FileSize = @intCast(metadata.size),
            .ContentHash = sqlDB.BLOB{ .data = &hashh, .len = hash.blake3.BLAKE3_OUT_LEN },
            .ModifiedTime = @as(i64, @truncate(metadata.mtime.toNanoseconds())),
            .LastSeenTime = time,
            .FileType = @intFromEnum(fType),
        });

        try updateLoadParameter(
            io,
            dir,
            parentID,
            fType,
            metadata,
            content,
            name,
            rPZ[0 .. rPZ.len - name.len - 1],
        );
    } else {
        const isModified = (currentModifiedTime != fileModifiedTime);
        if (pathModifiedTime == -1) {
            if (isModified) {
                var fileReader = tempFile.reader(io, &fileBuffer);
                const content = try fileReader.interface.readAlloc(gpa, metadata.size);
                defer gpa.free(content);

                var contentHash = hash.blake3HashContent(content);
                // const contentHash = try hashFileContent(&tempFile, metadata.size());
                try ContentPathT.update(
                    "RelativePath,ParentID,ModifiedTime,LastSeenTime,ContentHash,FileSize",
                    "FileName = ?",
                    .{
                        rPZ,
                        parentID,
                        currentModifiedTime,
                        time,
                        sqlDB.BLOB{ .data = &contentHash, .len = contentHash.len },
                        metadata.size,
                        name,
                    },
                );

                const index = std.mem.lastIndexOf(u8, name, ".") orelse name.len;
                fType = judgeFileType(name[index..], content);

                try updateLoadParameter(
                    io,
                    dir,
                    parentID,
                    fType,
                    metadata,
                    content,
                    name,
                    rPZ[0 .. rPZ.len - name.len - 1],
                );
            } else {
                try ContentPathT.update(
                    "RelativePath,ParentID,LastSeenTime",
                    "FileName = ?",
                    .{ rPZ, parentID, time, name },
                );
            }
        } else {
            // 已存在的文件：只更新时间和内容哈希（如果需要）
            if (isModified) {
                var fileReader = tempFile.reader(io, &fileBuffer);
                const content = try fileReader.interface.readAlloc(gpa, metadata.size);
                defer gpa.free(content);

                var contentHash = hash.blake3HashContent(content);

                try ContentPathT.update(
                    "ModifiedTime,LastSeenTime,ContentHash,FileSize",
                    "FileName = ?",
                    .{
                        currentModifiedTime,
                        time,
                        sqlDB.BLOB{ .data = &contentHash, .len = contentHash.len },
                        metadata.size,
                        name,
                    },
                );

                const index = std.mem.lastIndexOf(u8, name, ".") orelse name.len;
                fType = judgeFileType(name[index..], content);
                // std.log.debug("{s}", .{@tagName(fType)});

                try updateLoadParameter(
                    io,
                    dir,
                    parentID,
                    fType,
                    metadata,
                    content,
                    name,
                    rPZ[0 .. rPZ.len - name.len - 1],
                );
            } else {
                try ContentPathT.update("LastSeenTime", "FileName = ?", .{ time, name });
            }
        }
    }

    return fType;
}

fn hashFileContent(file: *std.fs.File, size: u64) !sqlDB.BLOB {
    const content = try gpa.alloc(u8, size);
    defer gpa.free(content);
    _ = try file.readAll(content);
    var contentHash = hash.blake3HashContent(content);
    return sqlDB.BLOB{ .data = &contentHash, .len = hash.blake3.BLAKE3_OUT_LEN };
}

pub fn processDirectory(
    io: std.Io,
    dir: std.Io.Dir,
    name: []const u8,
    rPZ: []const u8,
    parentID: []const u8,
    skipIterate: bool,
) anyerror!void {
    const time: i64 = @truncate(std.Io.Timestamp.now(io, .real).toNanoseconds());
    // std.log.debug("time {d} {s}", .{ time, name });
    var tempDir = try dir.openDir(io, name, .{ .iterate = true });
    defer tempDir.close(io);

    const metadata = try tempDir.stat(io);
    const currentModifiedTime: i64 = @truncate(metadata.mtime.toNanoseconds());
    var currentID: [UUID.len]u8 = undefined;
    currentID[UUID.len - 2] = 0;
    currentID[UUID.len - 1] = 0;

    const fileModifiedTime = try getDbModifiedTime("FileName = ?", .{name});
    const pathModifiedTime = try getDbModifiedTime("RelativePath = ?", .{rPZ});

    if (fileModifiedTime == -1) {
        // 新目录：插入记录并获取新ID
        try UUID.createNewUUID(&currentID);
        try ContentPathT.insert(.{
            .ID = @intCast(getInsertID()),
            .UUID = &currentID,
            .ParentUUID = @constCast(parentID.ptr),
            .RelativePath = @constCast(rPZ.ptr),
            .FileName = @constCast(name.ptr),
            .TYPE = @intFromEnum(metadata.kind),
            .FileSize = @intCast(metadata.size),
            .ContentHash = null,
            .ModifiedTime = currentModifiedTime,
            .LastSeenTime = time,
            .FileType = @intFromEnum(FileType.DIR),
        });
    } else {
        const isModified = (currentModifiedTime != fileModifiedTime);
        if (pathModifiedTime == -1) {
            if (isModified) {
                try ContentPathT.update(
                    "RelativePath,ParentUUID,ModifiedTime,LastSeenTime",
                    "FileName = ?",
                    .{ rPZ, parentID, currentModifiedTime, time, name },
                );
            } else {
                try ContentPathT.update(
                    "RelativePath,ParentUUID,LastSeenTime",
                    "FileName = ?",
                    .{ rPZ, parentID, time, name },
                );
            }
        } else {
            if (isModified) {
                try ContentPathT.update(
                    "ModifiedTime,LastSeenTime",
                    "FileName = ?",
                    .{ currentModifiedTime, time, name },
                );
            } else {
                try ContentPathT.update(
                    "LastSeenTime",
                    "FileName = ?",
                    .{ time, name },
                );
            }
        }

        var ptrs = [_]*anyopaque{&currentID};
        var types = [_]sqlDB.innerType{.TEXT};
        try ContentPathT.get("UUID", null, "RelativePath = ?", .{rPZ}, &ptrs, &types);
    }

    if (!skipIterate)
        try iterateFolderUpdate(io, tempDir, rPZ, &currentID);
}

fn iterateFolderUpdate(io: std.Io, dir: std.Io.Dir, dirName: []const u8, parentID: []const u8) !void {
    var contentIt = dir.iterate();
    while (try contentIt.next(io)) |entry| {
        var relativePathBuffer = [_]u8{0} ** 256;
        const rPZ = try std.fmt.bufPrintZ(&relativePathBuffer, "{s}{s}{s}", .{ dirName, slash, entry.name });

        var bufferZ = [_]u8{0} ** 128;
        const nameZ = try std.fmt.bufPrintZ(&bufferZ, "{s}", .{entry.name});

        switch (entry.kind) {
            .file => _ = try processFile(io, dir, nameZ, rPZ, parentID),
            .directory => try processDirectory(io, dir, nameZ, rPZ, parentID, false),
            else => {},
        }
    }
}

fn getInsertID() u32 {
    const sql = "WITH RECURSIVE" ++
        " next_id(n) AS (" ++
        "VALUES(0) UNION ALL" ++
        " SELECT n + 1 FROM next_id WHERE n IN (SELECT ID FROM ContentPath))" ++
        " SELECT n FROM next_id ORDER BY n DESC LIMIT 1";

    var stmt: ?*sqlite.sqlite3_stmt = null;
    var missing_id: c_int = 0;

    // 准备
    _ = sqlite.sqlite3_prepare_v2(db, sql, -1, &stmt, null);

    if (sqlite.sqlite3_step(stmt) == sqlite.SQLITE_ROW) {
        missing_id = sqlite.sqlite3_column_int(stmt, 0);
    }

    _ = sqlite.sqlite3_finalize(stmt);

    return @intCast(missing_id);
}

const AllTable = struct {
    db: ?*sqlite.sqlite3,
    ContentPath: tables.ContentPath,
    ImageLoadParameter: tables.ImageLoadParameter,
    ModelLoadParameter: tables.ModelLoadParameter,
    contentPathExist: bool,
};

var db: ?*sqlite.sqlite3 = undefined;
var ContentPathT: tables.ContentPath = undefined;
var ImageLoadParameterT: tables.ImageLoadParameter = undefined;
var ModelLoadParameterT: tables.ModelLoadParameter = undefined;

var SceneJson: std.json.Parsed(?[]cgltf.Scene) = undefined;
var SceneNameStringMap: std.StringHashMap(u32) = undefined;
var SceneNodeNames: []std.StringHashMap(u32) = undefined;

var gpa: std.mem.Allocator = undefined;
pub fn processContentFolder(content: std.Io.Dir, io: std.Io, tablePack: AllTable, allocator: std.mem.Allocator) !void {
    gpa = allocator;
    db = tablePack.db;
    ContentPathT = tablePack.ContentPath;
    ImageLoadParameterT = tablePack.ImageLoadParameter;
    ModelLoadParameterT = tablePack.ModelLoadParameter;

    const exist = tablePack.contentPathExist;

    var buffer = [_]u8{0} ** UUID.len;
    const time: i64 = @truncate(std.Io.Timestamp.now(io, .real).toNanoseconds());
    // std.log.debug("time {d}", .{time});

    var sceneFile = content.openFile(io, SceneFileName, .{ .mode = .read_write }) catch |err| blk: switch (err) {
        error.FileNotFound => break :blk try content.createFile(io, SceneFileName, .{ .read = true }),
        else => return err,
    };
    {
        errdefer sceneFile.close(io);
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
    errdefer sceneFile.close(io);
    defer {
        SceneNameStringMap.deinit();

        SceneJson.deinit();
    }

    if (exist) {
        const cc = try content.stat(io);
        var modifiedTime: i64 = 0;

        var getValues: [2]*anyopaque = undefined;
        getValues[0] = @ptrCast(&buffer);
        getValues[1] = @ptrCast(&modifiedTime);
        var types = [_]sqlDB.innerType{ .TEXT, .INTEGER };

        try ContentPathT.get("UUID,ModifiedTime", null, "RelativePath = ?", .{"Content"}, &getValues, &types);
        // std.log.info("{s}", .{buffer});

        if (cc.mtime.toNanoseconds() != @as(i96, @intCast(modifiedTime))) {
            try ContentPathT.update("ModifiedTime,LastSeenTime", "UUID = ?", .{ modifiedTime, time, buffer });
            // std.log.info("update", .{});
        } else {
            try ContentPathT.update("LastSeenTime", "UUID = ?", .{ time, buffer });
        }
    } else {
        const cc = try content.stat(io);
        try UUID.createNewUUID(&buffer);

        try ContentPathT.insert(.{
            .ID = @intCast(getInsertID()),
            .UUID = &buffer,
            .ParentUUID = null,
            .RelativePath = @constCast("Content"),
            .FileName = @constCast("Content"),
            .TYPE = @intFromEnum(cc.kind),
            .FileSize = @intCast(cc.size),
            .ContentHash = null,
            .ModifiedTime = @as(i64, @truncate(cc.mtime.toNanoseconds())),
            .LastSeenTime = @as(i64, @truncate(time)),
            .FileType = @intFromEnum(FileType.DIR),
        });
    }

    try iterateFolderUpdate(io, content, "Content", &buffer);

    if (SceneJson.value.?.len > 0) {
        var cacheBuffer = [_]u8{0} ** 1024;
        var sceneFileWriter = sceneFile.writer(io, &cacheBuffer);
        var sceneJsonWrite = std.json.Stringify{
            .writer = &sceneFileWriter.interface,
            .options = .{ .whitespace = .indent_tab },
        };
        try sceneJsonWrite.write(SceneJson.value);
        try sceneFileWriter.interface.flush();

        sceneFile.close(io);

        _ = try processFile(
            io,
            content,
            SceneFileName,
            "Content" ++ slash ++ SceneFileName,
            &buffer,
        );
    }

    try ContentPathT.delete("LastSeenTime < ?", .{time});
}
