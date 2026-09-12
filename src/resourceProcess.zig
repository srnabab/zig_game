const std = @import("std");
const Io = std.Io;

const global = @import("global");

const Allocator = std.mem.Allocator;

const png = @import("resourceProcess/png.zig");
const vtx = @import("resourceProcess/vtx.zig");
const gltf = @import("resourceProcess/gltf.zig");
const sampler = @import("resourceProcess/sampler.zig");
const shader = @import("resourceProcess/shader.zig");
const pipeline = @import("resourceProcess/pipeline.zig");
const ktx2 = @import("resourceProcess/ktx2.zig");
const loadmap = @import("resourceProcess/loadmap.zig");
const lMap = @import("resourceProcess/lMap.zig");
const binary = @import("resourceProcess/binary.zig");
const Instance = @import("resourceProcess/instance.zig");

// shared
const tables = @import("tables");
const triggers = @import("triggers.zig");

const cgltf = @import("cgltf");
const db = @import("db");

// runtime
const file = @import("fileSystem");
const sqlite3 = ?*file.sqlite.sqlite3;
const toStr2 = @import("u8pack").toStr2;

const VkStruct = @import("video");
const ExternalCommands = @import("processRender").externalCommands;
const Handles = @import("handle");
const Handle = Handles.Handle;
const mstd = @import("ms_std");
const resource = @import("resource");
const pass = @import("pass");

const MutexArray = mstd.MutexArray;

const mesh = @import("mesh");
const textureSet = @import("textureSet");
const loadMap = @import("loadmap");
const instance2 = @import("instance2");
const vertices2D = @import("vertices");
const PassGroupMapping = @import("passGroupMapping");
const meshInstance = @import("meshInstance");

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
    LoadMap,
    LMap,
    Binary,
    Instance,
};

pub const UserContext = struct {
    /// engine will use this
    pTextureSet: textureSet,
    loadmaps: loadMap,
    instances1: meshInstance,
    instances2: instance2,
    vertices: vertices2D,
    passGroupMapping: PassGroupMapping,

    meshes: mesh,

    pub fn initUserContext(
        gpa: Allocator,
        vulkan: *VkStruct,
        handles: *global.HandlesType,
        passes: *pass,
        externalCommands: *ExternalCommands,
    ) !UserContext {
        const indirect2DBuffers = passes.passMap.get(toStr2("indirect2D")).?.buffer;
        const iFeatherBuffers = passes.passMap.get(toStr2("i_feather")).?.buffer; // IF.instance3D = 9

        var uctx: UserContext = .{
            .meshes = mesh.init(gpa, vulkan, handles, .{
                iFeatherBuffers[2], // IF.meshlet (featherMeshlet)
                iFeatherBuffers[3], // IF.vertices (featherVertices)
                iFeatherBuffers[4], // IF.meshletVertices (featherMeshletVertices)
                iFeatherBuffers[5], // IF.meshletTriangles (featherMeshletTriangles)
                iFeatherBuffers[10], // IF.meshes
            }),
            .loadmaps = try .init(gpa, 1),
            .instances2 = .init(gpa),
            .passGroupMapping = .init(gpa),
            .vertices = try vertices2D.init(indirect2DBuffers[2], indirect2DBuffers[0], indirect2DBuffers[1], gpa, externalCommands),
            .instances1 = meshInstance.init(gpa, handles, iFeatherBuffers[9]),
            .pTextureSet = undefined,
        };
        try uctx.passGroupMapping.addUploadTarget(toStr2("i_feather"), iFeatherBuffers[6], iFeatherBuffers[8]); // IF.featherCommands / IF.groupMappings
        return uctx;
    }

    pub fn deinitUserContext(self: *UserContext, gpa: Allocator) void {
        self.meshes.deinit();
        self.loadmaps.deinit(gpa);
        self.instances2.deinit();
        self.vertices.deinit();
        self.passGroupMapping.deinit();
        self.instances1.deinit();
    }
};

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
    .{ ".loadmap", ProcessType.LoadMap },
    .{ ".lMap", ProcessType.LMap },
    .{ ".binary", ProcessType.Binary },
    .{ ".instance", ProcessType.Instance },
};

const HandleType = @import("handle").ResourceType;
pub const ProcessType_HandleType = struct {
    ProcessType,
    HandleType,
};
pub const Mappings = [_]ProcessType_HandleType{
    .{ ProcessType.PNG, HandleType.texture },
    .{ ProcessType.KTX2, HandleType.texture },
    .{ ProcessType.VTX, HandleType.mesh },
};

const PNG = png.PNG;
const GLTF = gltf.GLTF;
const LMap = lMap.LMap;

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
        std.log.debug("skip {s}", .{parmas.fileName});
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

        _ = content;
        _ = fullPath;
        _ = database;
        std.log.debug("skip {s}", .{fileName});
    }

    pub fn judgeFileType2(content: []u8, fType: ProcessType) ProcessType {
        _ = content;

        return fType;
    }
};

pub const Example_Reader = struct {
    pub const Ctx = struct {};

    pub const Child = struct {
        pub const Parent = Example_Reader;
    };

    pub fn read(
        comptime fType: ProcessType,
        ctx: *const resource.ResourceCtx,
        sqlite: sqlite3,
        fileID: u32,
        buffers: ?[]VkStruct.Buffer_t,
        commands: *ExternalCommands,
    ) resource.ResourceError!resource.ReaderReturnType {
        _ = ctx;
        _ = sqlite;
        _ = buffers;
        _ = commands;

        std.log.debug("unsupported type {s}, {d}", .{ @tagName(fType), fileID });
        unreachable;
    }
};

pub const PNG_Cooker = png.PNG_Cooker;
pub const GLTF_Cooker = gltf.GLTF_Cooker;
pub const VTX_Cooker = vtx.VTX_Cooker;
pub const Sampler_Cooker = sampler.Sampler_Cooker;
pub const Shader_Cooker = shader.Shader_Cooker;
pub const Pipeline_Cooker = pipeline.Pipeline_Cooker;
pub const LoadMap_Cooker = loadmap.LoadMap_Cooker;
pub const Instance_Cooker = Instance.Instance_Cooker;

pub const KTX2_Reader = ktx2.KTX2_Reader;
pub const VTX_Reader = vtx.VTX_Reader;
pub const PNG_Reader = png.PNG_Reader;
pub const LMap_Reader = lMap.LMap_Reader;
pub const Binary_Reader = binary.Binary_Reader;
pub const Instance_Reader = Instance.Instance_Reader;

pub const TypeUseExample = [_]ProcessType{
    .DIR,
    .GLTF,
    .OBJ,
    .MTL,
    .HASHTABLE,
    .Sampler,
    .LoadMap,
    .Pipeline,
    .UNKNOWN,
    .PipeB,
    .WAV,
    .TXT,
    .TTF,
    .TSDI,
    .SPV,
    .SamplerB,
    .Shader,
    .TSD,
};

pub fn useExample(comptime fType: ProcessType) bool {
    comptime {
        for (TypeUseExample) |value| {
            if (value == fType) {
                return true;
            }
        }

        return false;
    }
}

const Type = std.builtin.Type;

pub const ReaderUnion = e: {
    const Self = @This();

    const maxLen = 100;

    const selfInfo = @typeInfo(Self);

    var enum_field_names: []const []const u8 = &.{};

    // var union_field_names: []const []const u8 = &.{};

    var union_types: [maxLen]type = undefined;
    var union_attrs: [maxLen]Type.UnionField.Attributes = undefined;
    var count = 0;

    for (selfInfo.@"struct".decls) |field| {
        if (std.mem.endsWith(u8, field.name, "_Reader")) {
            if (std.mem.eql(u8, field.name, "Example_Reader")) continue;

            // @compileLog(field.name);

            const enumName = std.fmt.comptimePrint("{s}_Child", .{field.name[0 .. field.name.len - 7]});
            enum_field_names = enum_field_names ++ .{enumName};

            // const unionName = std.fmt.comptimePrint("{s}_Child", .{field.name[0 .. field.name.len - 7]});
            // union_field_names = union_field_names ++ .{unionName};

            union_types[count] = *@field(Self, field.name).Child;
            union_attrs[count] = .{ .@"align" = null };
            count += 1;
        }
    }

    var enum_values: [enum_field_names.len]u32 = undefined;
    for (0..enum_field_names.len) |i| {
        enum_values[i] = @intCast(i);
    }

    const reader_enum = @Enum(
        u32,
        .exhaustive,
        enum_field_names,
        &enum_values,
    );

    break :e @Union(
        .auto,
        reader_enum,
        enum_field_names,
        union_types[0..count],
        union_attrs[0..count],
    );
};

fn UnionName(comptime reader: type) [:0]const u8 {
    const typeName = s: {
        // comptime {
        const name = @typeName(reader);
        const start = std.mem.findLast(u8, name, ".") orelse 0;

        // @compileLog(name[start + 1 ..]);

        break :s name[start + 1 ..];
        // }
    };

    return std.fmt.comptimePrint("{s}_Child", .{typeName[0 .. typeName.len - 7]});
}

pub inline fn UnionInit(comptime reader: type, pointer: anytype) ReaderUnion {
    return @unionInit(ReaderUnion, UnionName(reader), pointer);
}
