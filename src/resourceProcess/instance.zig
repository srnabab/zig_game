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
const Commands = @import("processRender").commands;
const Handles = @import("handle");
const Handle = Handles.Handle;
const mstd = @import("ms_std");
const resource = @import("resource");

const cglm = @import("cglm");

const toStr2 = @import("u8pack").toStr2;

const instance2 = @import("instance2");
const textureSet = @import("textureSet");

const instance = instance2.instance;

const ResourceError = resource.ResourceError;

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
    const Self = @This();

    pub const Ctx = struct {
        instances2: *instance2,
        pTextureSet: *textureSet,
    };

    pub const Child = struct {
        pub const Parent = Instance_Reader;

        instances: []instance,

        pub fn free(self: *Child, gpa: Allocator) void {
            gpa.free(self.instances);
        }
    };

    pub fn read(
        comptime fType: ProcessType,
        ctx: *const resource.ResourceCtx,
        sqlite: sqlite3,
        fileID: u32,
        buffers: ?[]VkStruct.Buffer_t,
        commands: *ExternalCommands,
        child: *Child,
    ) resource.ResourceError!resource.ReaderReturnType {
        _ = fType;
        _ = buffers;
        _ = commands;

        const io = ctx.io;
        const gpa = ctx.gpa;

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
            return ResourceError.Unavaliable;
        };
        defer instanceFile.close(io);

        const stat = instanceFile.stat(io) catch |err| {
            std.log.err("instance stat {s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };

        var readBuffer = [_]u8{0} ** 256;
        var reader = instanceFile.reader(io, &readBuffer);
        const content = reader.interface.readAlloc(gpa, stat.size) catch |err| {
            std.log.err("instance readAlloc {s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        defer gpa.free(content);

        const parsed = std.json.parseFromSlice(File, gpa, content, .{}) catch |err| {
            std.log.err("instance parse {s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        defer parsed.deinit();

        child.instances = gpa.alloc(instance, parsed.value.items.len) catch return ResourceError.Unavaliable;
        errdefer gpa.free(child.instances);
        const instances = child.instances;

        for (parsed.value.items, instances) |item, *ins| {
            ins.textures = gpa.alloc(Handle, item.textures.len) catch return resource.ResourceError.Unavaliable;
        }
        errdefer for (instances) |*ins| {
            gpa.free(ins.textures);
        };

        for (parsed.value.items, instances, 0..) |item, *ins, i| {
            _ = i;
            // std.log.debug("item {d}: pass {s}, pos {any}, scale {any}, rotation {any}, textures {any}, model {any}", .{ i, item.pass, item.pos, item.scale, item.rotation, item.textures, item.model });

            if (item.pos.len != 3 or item.scale.len != 3 or item.rotation.len != 3) return resource.ResourceError.Invalid;
            ins.pos = .{ item.pos[0], item.pos[1], item.pos[2] };
            ins.scale = .{ item.scale[0], item.scale[1], item.scale[2] };
            ins.rotation = .{ item.rotation[0], item.rotation[1], item.rotation[2] };

            const pass = ctx.passes.passMap.get(toStr2(item.pass)) orelse return resource.ResourceError.Invalid;
            ins.pass = pass;

            for (item.textures, ins.textures) |value, *t| {
                const tex = resource.getResourceHandle(file.getID(value)) orelse return resource.ResourceError.Unavaliable;
                if (!Handles.handleIsValid(@ptrCast(tex))) return resource.ResourceError.Unavaliable;

                t.* = @ptrCast(tex);
            }

            if (item.model) |modelName| {
                ins.model = resource.getResourceHandle(file.getID(modelName)) orelse return resource.ResourceError.Unavaliable;
            }

            ins.handle = ctx.handles.createHandle(Handles.WaitFill, .others);
        }

        return .{ .rType = .update };
    }

    pub fn updateLoad(io: Io, gpa: Allocator, vulkan: *VkStruct, commands: *Commands, uctx: *Ctx, handle: Handle, pointer: *Child) !u32 {
        _ = commands;
        _ = vulkan;
        _ = handle;
        _ = gpa;

        for (pointer.instances) |ins| {
            uctx.instances2.add(io, ins) catch |err| {
                std.log.err("instances2 add {s}", .{@errorName(err)});
                return Handles.WaitFill;
            };
        }
        return Handles.WaitFill;
    }
};
