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

pub const Instance_Cooker = struct {
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
        const dstPath = try std.fmt.allocPrint(gpa, "{s}\\Instance\\{s}", .{ contentFolderPath, fileName });
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

pub const Instance_Reader = struct {
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
        _ = fType;
        _ = handle;
        _ = buffers;
        _ = commands;
        _ = uctx;

        const io = ctx.io;
        const gpa = ctx.gpa;

        // instance.schema.json 布局：root { "$schema", items[] }
        const Item = struct {
            pass: []const u8,
            pos: []f32,
            scale: []f32,
            rotation: []f32,
            textures: [][]const u8,
            model: ?[]const u8 = null,
        };
        const File = struct {
            @"$schema": ?[]const u8 = null,
            items: []Item = &.{},
        };

        var instanceFile = file.getFile(io, fileID, sqlite) catch |err| {
            std.log.err("instance getFile {s}", .{@errorName(err)});
            return Handles.WaitFill;
        };
        defer instanceFile.close(io);

        const stat = instanceFile.stat(io) catch |err| {
            std.log.err("instance stat {s}", .{@errorName(err)});
            return Handles.WaitFill;
        };

        var readBuffer = [_]u8{0} ** 256;
        var reader = instanceFile.reader(io, &readBuffer);
        const content = reader.interface.readAlloc(gpa, stat.size) catch |err| {
            std.log.err("instance readAlloc {s}", .{@errorName(err)});
            return Handles.WaitFill;
        };
        defer gpa.free(content);

        const parsed = std.json.parseFromSlice(File, gpa, content, .{}) catch |err| {
            std.log.err("instance parse {s}", .{@errorName(err)});
            return Handles.WaitFill;
        };
        defer parsed.deinit();

        for (parsed.value.items, 0..) |item, i| {
            if (item.pass.len == 0) {
                std.log.err("instance item {d}: empty pass", .{i});
                return Handles.WaitFill;
            }
            if (item.pos.len != 3 or item.scale.len != 3 or item.rotation.len != 3) {
                std.log.err("instance item {d}: pos/scale/rotation must have length 3", .{i});
                return Handles.WaitFill;
            }
            std.log.debug("item {d}: pass {s}, pos {any}, scale {any}, rotation {any}, textures {any}, model {any}", .{ i, item.pass, item.pos, item.scale, item.rotation, item.textures, item.model });

            // const ress = resource.getResourceHandle(fileID) orelse unreachable;
        }

        return Handles.WaitFill;
    }
};
