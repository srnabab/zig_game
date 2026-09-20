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

const u8pack = @import("u8pack");

const pass = @import("pass");
const textureSet = @import("textureSet");
const renderData = @import("renderData");

const ResourceError = resource.ResourceError;

pub const RData_Cooker = struct {
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
        const dstPath = try std.fmt.allocPrint(gpa, "{s}\\Rdata\\{s}", .{ contentFolderPath, fileName });
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

pub const RData_Reader = struct {
    pub const Ctx = struct {
        renderData: *renderData,
        pTextureSet: *textureSet,
    };

    pub const Item = struct {
        name: []u8,
        model: ?Handle = null,
        textures: []Handle,
        pass: *pass.Pass,
    };

    pub const Child = struct {
        pub const Parent = RData_Reader;

        items: []Item,

        pub fn free(self: *Child, gpa: Allocator) void {
            for (self.items) |item| {
                gpa.free(item.name);
                gpa.free(item.textures);
            }
            gpa.free(self.items);
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

        const JsonItem = struct {
            name: []const u8,
            pass: []const u8,
            textures: [][]const u8,
            model: ?[]const u8 = null,
        };
        const JsonFile = struct {
            @"$schema": ?[]const u8 = null,
            items: []JsonItem = &.{},
        };

        var rdataFile = file.getFile(io, fileID, sqlite) catch |err| {
            std.log.err("rdata getFile {s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        defer rdataFile.close(io);

        const stat = rdataFile.stat(io) catch |err| {
            std.log.err("rdata stat {s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };

        var readBuffer = [_]u8{0} ** 256;
        var reader = rdataFile.reader(io, &readBuffer);
        const content = reader.interface.readAlloc(gpa, stat.size) catch |err| {
            std.log.err("rdata readAlloc {s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        defer gpa.free(content);

        const parsed = std.json.parseFromSlice(JsonFile, gpa, content, .{}) catch |err| {
            std.log.err("rdata parse {s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        defer parsed.deinit();

        child.items = gpa.alloc(Item, parsed.value.items.len) catch return ResourceError.Unavaliable;
        errdefer gpa.free(child.items);
        const items = child.items;

        var filled: usize = 0;
        errdefer for (items[0..filled]) |item| {
            gpa.free(item.name);
            gpa.free(item.textures);
        };

        for (parsed.value.items, items) |jsonItem, *item| {
            item.textures = gpa.alloc(Handle, jsonItem.textures.len) catch return ResourceError.Unavaliable;
            item.name = gpa.dupe(u8, jsonItem.name) catch {
                gpa.free(item.textures);
                return ResourceError.Unavaliable;
            };
            item.model = null;
            filled += 1;
        }

        for (parsed.value.items, items) |jsonItem, *item| {
            // std.log.debug("rdata item: name {s}, pass {s}, textures {any}, model {any}", .{ jsonItem.name, jsonItem.pass, jsonItem.textures, jsonItem.model });

            item.pass = ctx.passes.passMap.get(u8pack.toStr2(jsonItem.pass)) orelse return ResourceError.Invalid;

            for (jsonItem.textures, item.textures) |value, *t| {
                const tex = resource.getResourceHandle(file.getID(value)) orelse return ResourceError.Unavaliable;
                if (!Handles.handleIsValid(@ptrCast(tex))) return ResourceError.Unavaliable;

                t.* = @ptrCast(tex);
            }

            if (jsonItem.model) |modelName| {
                item.model = resource.getResourceHandle(file.getID(modelName)) orelse return ResourceError.Unavaliable;
            }
        }

        return .{ .rType = .render };
    }

    pub fn renderLoad(
        io: Io,
        gpa: Allocator,
        vulkan: *VkStruct,
        commands: *Commands,
        uctx: *Ctx,
        handle: Handle,
        pointer: *Child,
    ) !u32 {
        _ = io;
        _ = vulkan;
        _ = commands;
        _ = handle;

        for (pointer.items) |item| {
            const name = u8pack.toStr2(item.name);

            uctx.renderData.add(gpa, name, .{
                .model = item.model,
                .textures = item.textures,
                .pass = item.pass,
            }) catch |err| {
                std.log.err("renderData add {s}", .{@errorName(err)});
                return Handles.Invalid;
            };
        }
        return Handles.WaitFill;
    }
};
