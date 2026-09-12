const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const global = @import("global");

pub const resourceProcess = @import("../resourceProcess.zig");

const tables = @import("tables");
const PreProcessParm = resourceProcess.PreProcessParm;
const db = @import("db");
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
const ResourceError = resource.ResourceError;

const vertexStruct = @import("vertexStruct");
const Buffer_t = VkStruct.Buffer_t;
const ExternalCommands = @import("processRender").externalCommands;
const Commands = @import("processRender").commands;

const loadMap = @import("loadmap");

pub const LMap = "lMap";

pub const LMap_Reader = struct {
    const Self = @This();

    pub const Ctx = struct {
        loadmaps: *loadMap,
    };

    pub const Child = struct {
        pub const Parent = LMap_Reader;

        load_map: loadMap.loadmap,
    };

    pub fn read(
        comptime fType: ProcessType,
        ctx: *const resource.ResourceCtx,
        sqlite: sqlite3,
        fileID: u32,
        buffers: ?[]VkStruct.Buffer_t,
        commands: *ExternalCommands,
    ) ResourceError!resource.ReaderReturnType {
        _ = fType;
        _ = buffers;
        _ = commands;
        const io = ctx.io;
        const gpa = ctx.gpa;
        // const lmap = uctx.loadmaps;

        var mapFile = file.getFile(io, fileID, sqlite) catch return ResourceError.Invalid;
        defer mapFile.close(io);

        const stat = mapFile.stat(io) catch return ResourceError.Unavaliable;

        var buffer = [_]u8{0} ** 256;
        var fileReader = mapFile.reader(io, &buffer);
        const content = fileReader.interface.readAlloc(gpa, stat.size) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        defer gpa.free(content);

        const ptr = gpa.create(Child) catch return ResourceError.Unavaliable;
        ptr.load_map = loadMap.loadmap.loadLoadmap(gpa, content) catch return ResourceError.Unavaliable;

        return .{
            .rType = .update,
            .pointer = resourceProcess.UnionInit(Self, ptr),
        };
    }

    pub fn load(io: Io, gpa: Allocator, vulkan: *VkStruct, commands: *Commands, uctx: *Ctx, handle: Handle, pointer: *Child) !u32 {
        _ = io;
        _ = vulkan;
        _ = commands;
        _ = handle;

        defer gpa.destroy(pointer);

        uctx.loadmaps.addMap(pointer.load_map, 0);

        return Handles.WaitFill;
    }
};
