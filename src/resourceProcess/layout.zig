const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const global = @import("global");

const tables = @import("tables");
const resourceProcess = @import("../resourceProcess.zig");
const PreProcessParm = resourceProcess.PreProcessParm;
const db = @import("db");
const ProcessType = resourceProcess.ProcessType;

const file = @import("fileSystem");
const sqlite3 = ?*file.sqlite.sqlite3;
const VkStruct = @import("video");
const ExternalCommands = @import("processRender").externalCommands;
const Commands = @import("processRender").commands;
const Handles = @import("handle");
const Handle = Handles.Handle;
const resource = @import("resource");

const cglm = @import("cglm");
const vec3 = cglm.vec3;

const u8pack = @import("u8pack");
const toStr = u8pack.toStr;

const mstd = @import("ms_std");
const renderData = @import("renderData");

const ResourceError = resource.ResourceError;

pub const Layout_Cooker = struct {
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
        const dstPath = try std.fmt.allocPrint(gpa, "{s}\\Layout\\{s}", .{ contentFolderPath, fileName });
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

pub const Item = struct {
    name: u8pack.Str,
    pos: vec3,
    scale: vec3,
    rotation: vec3,
    handle: Handle,
};

pub const Layout_Reader = struct {
    pub const Ctx = struct {
        renderData: *renderData,
        layoutQueue: *mstd.FixedIndexArray(Item),
    };

    pub const Child = struct {
        pub const Parent = Layout_Reader;

        items: []Item,

        pub fn free(self: *Child, gpa: Allocator) void {
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
            pos: []f32,
            scale: []f32,
            rotation: []f32,
        };
        const JsonFile = struct {
            @"$schema": ?[]const u8 = null,
            items: []JsonItem = &.{},
        };

        var layoutFile = file.getFile(io, fileID, sqlite) catch |err| {
            std.log.err("layout getFile {s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        defer layoutFile.close(io);

        const stat = layoutFile.stat(io) catch |err| {
            std.log.err("layout stat {s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };

        var readBuffer = [_]u8{0} ** 256;
        var reader = layoutFile.reader(io, &readBuffer);
        const content = reader.interface.readAlloc(gpa, stat.size) catch |err| {
            std.log.err("layout readAlloc {s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        defer gpa.free(content);

        const parsed = std.json.parseFromSlice(JsonFile, gpa, content, .{}) catch |err| {
            std.log.err("layout parse {s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        defer parsed.deinit();

        child.items = gpa.alloc(Item, parsed.value.items.len) catch return ResourceError.Unavaliable;
        errdefer gpa.free(child.items);
        const items = child.items;

        var filled: usize = 0;

        for (parsed.value.items, items) |jsonItem, *item| {
            if (jsonItem.pos.len != 3 or jsonItem.scale.len != 3 or jsonItem.rotation.len != 3) return ResourceError.Invalid;

            item.name = u8pack.toStr2(jsonItem.name);
            item.pos = .{ jsonItem.pos[0], jsonItem.pos[1], jsonItem.pos[2] };
            item.scale = .{ jsonItem.scale[0], jsonItem.scale[1], jsonItem.scale[2] };
            item.rotation = .{ jsonItem.rotation[0], jsonItem.rotation[1], jsonItem.rotation[2] };
            item.handle = ctx.handles.createHandle(Handles.Invalid, .others);

            filled += 1;
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
        updateEventQueue: *global.UpdateEventQueueType,
    ) !u32 {
        _ = io;
        _ = gpa;
        _ = vulkan;
        _ = commands;
        _ = handle;

        for (pointer.items) |item| {
            // item.name 走 strConstruct.rdatas 静态表, 查不到时 id = maxInt
            // TODO(release): ReleaseFast 下 Str2 是 u32
            const name = item.name;

            const rdata = uctx.renderData.get(name) orelse {
                try uctx.layoutQueue.append(item);
                continue;
            };

            if (u8pack.eql(toStr("indirect2D"), rdata.pass.name)) {
                updateEventQueue.pushLastC(.{ .createTest2d = .{
                    .pos = item.pos,
                    .scale = item.scale,
                    .rotation = item.rotation,
                    .rdata = name,
                    .handle = item.handle,
                } }) catch |err| {
                    std.log.err("layout push createTest2d {s}", .{@errorName(err)});
                    return Handles.Invalid;
                };
            } else if (u8pack.eql(toStr("i_feather"), rdata.pass.name)) {
                updateEventQueue.pushLastC(.{ .createTest3d = .{
                    .pos = item.pos,
                    .scale = item.scale,
                    .rotation = item.rotation,
                    .rdata = name,
                    .handle = item.handle,
                } }) catch |err| {
                    std.log.err("layout push createTest3d {s}", .{@errorName(err)});
                    return Handles.Invalid;
                };
            }
        }

        return Handles.WaitFill;
    }
};
