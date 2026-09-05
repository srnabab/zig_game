const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const global = @import("global");

const vk = @import("vulkan");
const tables = @import("tables");
const resourceProcess = @import("../resourceProcess.zig");
const PreProcessParm = resourceProcess.PreProcessParm;
const db = @import("db");
const ProcessType = resourceProcess.ProcessType;

const judgeFileTypeByContent = resourceProcess.judgeFileTypeByContent;

const file = @import("fileSystem");
const sqlite3 = ?*file.sqlite.sqlite3;
const VkStruct = @import("video");
const ExternalCommands = @import("processRender").externalCommands;
const Handles = @import("handle");
const Handle = Handles.Handle;
const mstd = @import("ms_std");
const resource = @import("resource");

pub const Scene_Cooker = struct {
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
        _ = content;
        _ = database;
        std.log.debug("{s}", .{contentFolderPath});
        const dstPath = try std.fmt.allocPrint(gpa, "{s}\\Scene\\{s}", .{ contentFolderPath, fileName });
        defer gpa.free(dstPath);
        std.log.debug("{s}", .{dstPath});

        const pRes = try std.process.run(gpa, io, .{ .argv = &[_][]const u8{
            "pwsh",
            "-Command",
            "Copy-Item",
            fullPath,
            "-Destination",
            dstPath,
            "-Force",
        } });
        std.log.err("{s}", .{pRes.stderr});
        defer {
            gpa.free(pRes.stderr);
            gpa.free(pRes.stdout);
        }
    }

    pub fn judgeFileType2(content: []u8, fType: ProcessType) ProcessType {
        _ = content;

        return fType;
    }
};

pub const Scene_Reader = struct {
    pub const Ctx = struct {};

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
        _ = ctx;
        _ = sqlite;
        _ = handle;
        _ = buffers;
        _ = commands;
        _ = uctx;

        std.log.debug("unsupported type {s}, {d}", .{ @tagName(fType), fileID });
        // unreachable;
        return Handles.WaitFill;
    }
};
