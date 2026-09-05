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
const Resource = resource.Resource;
const vertexStruct = @import("vertexStruct");
const Buffer_t = VkStruct.Buffer_t;
const ExternalCommands = @import("processRender").externalCommands;

const loadMap = @import("loadmap");

pub const LMap = "lMap";

pub const LMap_Reader = struct {
    pub const Ctx = struct {
        loadmaps: *loadMap,
    };

    pub fn processResource(
        comptime fType: ProcessType,
        ctx: *const resource.ResourceCtx,
        sqlite: sqlite3,
        fileID: i32,
        handle: Handle,
        buffers: ?[]VkStruct.Buffer_t,
        commands: *ExternalCommands,
        uctx: *Ctx,
    ) !u32 {
        _ = fType;
        _ = handle;
        _ = buffers;
        _ = commands;
        const io = ctx.io;
        const gpa = ctx.gpa;
        const lmap = uctx.loadmaps;

        var mapFile = file.getFile(io, fileID, sqlite) catch return Handles.WaitFill;
        defer mapFile.close(io);

        const stat = mapFile.stat(io) catch return Handles.WaitFill;

        var buffer = [_]u8{0} ** 256;
        var fileReader = mapFile.reader(io, &buffer);
        const content = fileReader.interface.readAlloc(gpa, stat.size) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return Handles.WaitFill;
        };
        defer gpa.free(content);

        const load_map = loadMap.loadmap.loadLoadmap(gpa, content) catch return Handles.WaitFill;
        lmap.addMap(load_map, 0);

        return Handles.WaitFill;
    }
};
