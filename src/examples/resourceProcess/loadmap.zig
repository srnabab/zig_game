const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

pub const resourceProcess = @import("../resourceProcess.zig");

const tables = @import("tables");
const PreProcessParm = resourceProcess.PreProcessParm;
const db = @import("db");
const ProcessType = resourceProcess.ProcessType;

pub const LoadMap_Cooker = struct {
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
        // var readBuffer = [_]u8{0} ** 64;

        const lMapName = try std.fmt.allocPrintSentinel(
            gpa,
            "{s}.lMap",
            .{fileName[0 .. std.mem.findLast(u8, fileName, ".") orelse fileName.len]},
            0,
        );
        defer gpa.free(lMapName);

        const lmapFullPath = try std.fs.path.joinZ(
            gpa,
            &[_][]const u8{
                contentFolderPath,
                "LoadMap",
                lMapName,
            },
        );
        defer gpa.free(lmapFullPath);

        const runRes = try std.process.run(gpa, io, .{
            .argv = &[_][]const u8{ "loadmapConverter.exe", fullPath, lmapFullPath },
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
    }

    pub fn judgeFileType2(content: []u8, fType: ProcessType) ProcessType {
        _ = content;

        return fType;
    }
};
