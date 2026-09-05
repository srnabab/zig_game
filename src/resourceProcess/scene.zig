const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const vk = @import("vulkan");
const tables = @import("tables");
const resourceProcess = @import("../resourceProcess.zig");
const PreProcessParm = resourceProcess.PreProcessParm;
const db = @import("db");
const ProcessType = resourceProcess.ProcessType;

const judgeFileTypeByContent = resourceProcess.judgeFileTypeByContent;

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
