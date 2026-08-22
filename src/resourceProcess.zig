const std = @import("std");
const Io = std.Io;

const Allocator = std.mem.Allocator;

const png = @import("resourceProcess/png.zig");
const vtx = @import("resourceProcess/vtx.zig");
const gltf = @import("resourceProcess/gltf.zig");
const sampler = @import("resourceProcess/sampler.zig");
const shader = @import("resourceProcess/shader.zig");
const pipeline = @import("resourceProcess/pipeline.zig");

const tables = @import("tables");
const triggers = @import("triggers.zig");

const cgltf = @import("cgltf");
const db = @import("db");

pub const CustomTables = [_]type{
    tables.ModelLoadParameter,
    tables.ImageLoadParameter,
    tables.ContentPath,
};

pub const CustomTablePack = t: {
    var fields_name: [1024][]const u8 = undefined;
    var fields_type: [1024]type = undefined;
    var count: u32 = 0;

    for (CustomTables) |table| {
        // const info = @typeInfo(table);
        // for (info.@"struct".fields) |f| {
        //     @compileLog(std.fmt.comptimePrint("name: {s}", .{f.name}));
        // }
        if (!@hasField(table, "db")) {
            @compileError("not a Table");
        }
        if (!@hasField(table, "tableName")) {
            @compileError("not a Table");
        }

        const typeName = @typeName(table);

        const indexend = std.mem.findLast(u8, typeName, "\"") orelse @compileError("not a Table");
        const indexStart = std.mem.findLast(u8, typeName[0 .. indexend - 1], "\"") orelse @compileError("not a Table");

        fields_name[count] = std.fmt.comptimePrint("{s}T", .{typeName[indexStart + 1 .. indexend]});
        fields_type[count] = table;
        // @compileLog(std.fmt.comptimePrint("name: {s}", .{fields_name[count]}));
        count += 1;
    }

    break :t @Struct(
        .auto,
        null,
        fields_name[0..count],
        fields_type[0..count],
        &@splat(.{}),
    );
};

pub const Triggers = [_][:0]const u8{
    triggers.createUniqueIndexFileNameAndContentHash,
    triggers.createTriggerOnInsertContentPathCheckContentHash,
    triggers.createTriggerOnDeleteContentPathUpdateTablesRelativePathWhereSameContentHash,
    triggers.createTriggerOnUpdateContentPathUpdateOrInsertTables,
};

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
pub const PNG_Cooker = png.PNG_Cooker;
pub const GLTF_Cooker = gltf.GLTF_Cooker;
pub const VTX_Cooker = vtx.VTX_Cooker;
pub const Sampler_Cooker = sampler.Sampler_Cooker;
pub const Shader_Cooker = shader.Shader_Cooker;
pub const Pipeline_Cooker = pipeline.Pipeline_Cooker;

const PNG = png.PNG;
const GLTF = gltf.GLTF;

pub fn judgeFileTypeByContent(content: []u8) ProcessType {
    if (std.mem.eql(u8, content, @constCast(&PNG))) {
        return .PNG;
    } else if (std.mem.eql(u8, content, @constCast(GLTF))) {
        return .GLTF;
    } else {
        return .UNKNOWN;
    }
}

pub const SceneFileName = "Scenes.json";

pub var fileDbParamMap: fileDbParamMapType = undefined;

pub var SceneJson: std.json.Parsed(?[]cgltf.Scene) = undefined;
pub var SceneNameStringMap: std.StringHashMap(u32) = undefined;
pub var SceneNodeNames: []std.StringHashMap(u32) = undefined;

pub var contentFolder: Io.Dir = undefined;

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

pub fn preProcessInit(io: Io, gpa: Allocator, content: Io.Dir) !void {
    contentFolder = content;

    try sceneJsonInit(io, gpa, content);
    try gltf.saveSceneJson(io, content);
    initFileParameterMap(gpa);
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
