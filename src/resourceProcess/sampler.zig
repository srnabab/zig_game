const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const sampler = @import("sampler");
const vk = @import("vulkan");
const tables = @import("tables");
const resourceProcess = @import("../resourceProcess.zig");
const PreProcessParm = resourceProcess.PreProcessParm;
const db = @import("db");
const ProcessType = resourceProcess.ProcessType;

const judgeFileTypeByContent = resourceProcess.judgeFileTypeByContent;

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
