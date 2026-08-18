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
const resourceProcess = @import("resourceProcess");

const Allocator = std.mem.Allocator;
const Io = std.Io;

const assert = std.debug.assert;

const SceneFileName = "Scenes.json";

const FileType = resourceProcess.ProcessType;

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
    const list = resourceProcess.list;

    const maps = maptype.initComptime(list);
    break :map maps;
};

pub var forceUpdata = false;

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
    _ = cc;
    _ = parentID;
    _ = rpZ;
    switch (tp) {
        inline else => |t| {
            const cookerName = std.fmt.comptimePrint("{s}{s}", .{ @tagName(t), "_Cooker" });

            const field = @field(resourceProcess, cookerName);

            if (field.Enable)
                try field.preProcess(io, gpa, dir, &ContentPathT, fileName, content, &@field(allTable, field.TableName));
        },
    }
}

fn checkGltfMeshProcess(allocator: Allocator, content: []const u8) !bool {
    const data = try cgltf.getGltfFileInfo(content);
    defer cgltf.cgltf.cgltf_free(data);

    const scenes = data.*.scenes;
    const scenes_count = data.*.scenes_count;

    for (0..scenes_count) |i| {
        const scene = scenes[i];

        const nodes = scene.nodes;
        const nodes_count = scene.nodes_count;

        for (0..nodes_count) |j| {
            const node = nodes[j];

            const mesh = node.*.mesh;

            const mesh_name = mesh.*.name;
            const mesh_name_len = std.mem.len(mesh_name);

            const primitives_count = mesh.*.primitives_count;
            for (0..primitives_count) |l| {
                const primitive_name_mem = try allocator.alloc(u8, mesh_name_len + 4 + 5);
                defer allocator.free(primitive_name_mem);

                const primitive_name = try std.fmt.bufPrintZ(
                    primitive_name_mem,
                    "{s}_{d}.vtx",
                    .{ mesh_name, l },
                );

                const have = try ContentPathT.have(
                    "FileName",
                    "FileName = ?",
                    .{primitive_name},
                );

                if (!have) return false;
            }
        }
    }

    return true;
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

fn checkGltfPrimitiveName(
    name: []const u8,
) !void {
    const have = try ContentPathT.have("FileName", "FileName = ?", .{name});
    if (have) {
        return error.Duplicated;
    }
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
        // std.log.debug("1", .{});
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
        // std.log.debug("2", .{});
        var isModified = (currentModifiedTime != fileModifiedTime);

        switch (fType) {
            .GLTF => {
                var fileReader = tempFile.reader(io, &fileBuffer);
                const content = try fileReader.interface.readAlloc(gpa, metadata.size);
                defer gpa.free(content);

                isModified = try checkGltfMeshProcess(gpa, content);
            },
            else => {},
        }

        if (forceUpdata) isModified = true;

        if (pathModifiedTime == -1) {
            if (isModified) {
                // std.log.debug("2", .{});
                var fileReader = tempFile.reader(io, &fileBuffer);
                const content = try fileReader.interface.readAlloc(gpa, metadata.size);
                defer gpa.free(content);

                const index = std.mem.lastIndexOf(u8, name, ".") orelse name.len;
                fType = judgeFileType(name[index..], content);

                var contentHash = hash.blake3HashContent(content);
                // const contentHash = try hashFileContent(&tempFile, metadata.size());
                try ContentPathT.update(
                    "RelativePath,ParentID,ModifiedTime,LastSeenTime,ContentHash,FileSize,FileType",
                    "FileName = ?",
                    .{
                        rPZ,
                        parentID,
                        currentModifiedTime,
                        time,
                        sqlDB.BLOB{ .data = &contentHash, .len = contentHash.len },
                        metadata.size,
                        @intFromEnum(fType),
                        name,
                    },
                );

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
                var fType_u32: u32 = 0;
                var getValues: [1]*anyopaque = .{@ptrCast(&fType_u32)};
                var types = [_]sqlDB.innerType{.INTEGER};

                try ContentPathT.get(
                    "FileType",
                    null,
                    "FileName = ?",
                    .{name},
                    &getValues,
                    &types,
                );

                fType = @enumFromInt(fType_u32);

                try ContentPathT.update(
                    "RelativePath,ParentID,LastSeenTime",
                    "FileName = ?",
                    .{ rPZ, parentID, time, name },
                );
            }
        } else {
            // 已存在的文件：只更新时间和内容哈希（如果需要）
            if (isModified) {
                // std.log.debug("3", .{});
                var fileReader = tempFile.reader(io, &fileBuffer);
                const content = try fileReader.interface.readAlloc(gpa, metadata.size);
                defer gpa.free(content);

                var contentHash = hash.blake3HashContent(content);

                const index = std.mem.lastIndexOf(u8, name, ".") orelse name.len;
                fType = judgeFileType(name[index..], content);

                try ContentPathT.update(
                    "ModifiedTime,LastSeenTime,ContentHash,FileSize,FileType",
                    "FileName = ?",
                    .{
                        currentModifiedTime,
                        time,
                        sqlDB.BLOB{ .data = &contentHash, .len = contentHash.len },
                        metadata.size,
                        @intFromEnum(fType),
                        name,
                    },
                );
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
                var fType_u32: u32 = 0;
                var getValues: [1]*anyopaque = .{@ptrCast(&fType_u32)};
                var types = [_]sqlDB.innerType{.INTEGER32};

                try ContentPathT.get(
                    "FileType",
                    null,
                    "FileName = ?",
                    .{name},
                    &getValues,
                    &types,
                );

                fType = @enumFromInt(fType_u32);

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
        const isModified = (currentModifiedTime != fileModifiedTime) | forceUpdata;
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
    ContentPathT: tables.ContentPath,
    ImageLoadParameterT: tables.ImageLoadParameter,
    ModelLoadParameterT: tables.ModelLoadParameter,
    ShaderPipelineGraphNodeT: tables.ShaderPipelineGraphNode,
    ShaderPipelineGraphEdgeT: tables.ShaderPipelineGraphEdge,

    contentPathExist: bool,
};

var db: ?*sqlite.sqlite3 = undefined;
var ContentPathT: tables.ContentPath = undefined;

var allTable: AllTable = undefined;

var ShaderPipelineGraphNodeT: tables.ShaderPipelineGraphNode = undefined;
var ShaderPipelineGraphEdgeT: tables.ShaderPipelineGraphEdge = undefined;

var SceneJson: std.json.Parsed(?[]cgltf.Scene) = undefined;
var SceneNameStringMap: std.StringHashMap(u32) = undefined;
var SceneNodeNames: []std.StringHashMap(u32) = undefined;

var gpa: std.mem.Allocator = undefined;
pub fn processContentFolder(content: std.Io.Dir, io: std.Io, tablePack: AllTable, allocator: std.mem.Allocator) !void {
    gpa = allocator;
    db = tablePack.db;
    ContentPathT = tablePack.ContentPathT;

    allTable = tablePack;

    ShaderPipelineGraphNodeT = tablePack.ShaderPipelineGraphNodeT;
    ShaderPipelineGraphEdgeT = tablePack.ShaderPipelineGraphEdgeT;

    const exist = tablePack.contentPathExist;

    var buffer = [_]u8{0} ** UUID.len;
    const time: i64 = @truncate(std.Io.Timestamp.now(io, .real).toNanoseconds());
    // std.log.debug("time {d}", .{time});

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

    try saveSceneJson(io, content);

    try ContentPathT.delete("LastSeenTime < ?", .{time});
}

pub fn saveSceneJson(io: std.Io, content: std.Io.Dir) !void {
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

        // _ = try processFile(
        //     io,
        //     content,
        //     SceneFileName,
        //     "Content" ++ slash ++ SceneFileName,
        //     &buffer,
        // );
    }
}

pub fn cleanSceneJson() void {
    SceneJson.deinit();
    SceneNameStringMap.deinit();
}
