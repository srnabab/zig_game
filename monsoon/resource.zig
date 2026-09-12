const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const mstd = @import("ms_std");

const vk = @import("vk");
const VkStruct = @import("video");
const Handles = @import("handle");
const Handle = Handles.Handle;

const u8pack = @import("u8pack");
const Str = u8pack.Str;

const Texture_t = @import("textureSet").Texture_t;
const vertexStruct = @import("vertexStruct");
const Mesh_t = @import("mesh").Mesh_t;
const Instance_t = @import("meshInstance").Instance_t;
const global = @import("global");
const ringBuffer = mstd.RingBuffer;
const MutexArray = mstd.MutexArray;
const ExternalCommands = @import("processRender").externalCommands;

const file = @import("fileSystem");
const sqlite3 = ?*file.sqlite.sqlite3;

const pass = @import("pass");

const stb_image = @import("stb_image");
// const ktx_vulkan = @import("ktx_vulkan");

const vec3 = vertexStruct.vec3;

const resourceProcess = @import("resourceProcess");

pub const ResourceError = error{
    Invalid,
    Unavaliable,
};

const ID_FileType_Handle = struct {
    id: u32,
    buffers: []VkStruct.Buffer_t,
    fileType: file.FileType,
    handle: Handle,
};

const ReaderQueueEnum = enum(u8) { update, render };
pub const ReaderReturnType = struct {
    rType: ReaderQueueEnum,
    pointer: resourceProcess.ReaderUnion,
};

pub const Pointer_Handle = struct {
    handle: Handle,
    pointer: resourceProcess.ReaderUnion,
};

// pub const ResourcesQueue = MutexArray(Resource);
pub const NameQueue = MutexArray(ID_FileType_Handle);
pub const DataBaseHandleArrayType = ringBuffer(sqlite3, 8);
pub const ReaderQueue = mstd.Queue(Pointer_Handle);

pub const ResourceCtx = struct {
    io: Io,
    gpa: std.mem.Allocator,
    handles: *global.HandlesType,
    nameArray: *NameQueue,
    vulkan: *VkStruct,
    mainSqlite: sqlite3,
    passes: *pass,
    render: *ReaderQueue,
    update: *ReaderQueue,
};

pub const ResourceThreadArgs = struct {
    ctx: *const ResourceCtx,

    group: *std.Io.Group,
    handleArray: *DataBaseHandleArrayType,
    handleMutex: *Io.Mutex,
    externalCommands: *ExternalCommands,
    uctx: *resourceProcess.UserContext,
};

var idHandleCache: std.AutoHashMapUnmanaged(u32, Handle) = .empty;

pub fn deinit(gpa: Allocator) void {
    idHandleCache.deinit(gpa);
}

pub fn readResource(
    ctx: *const ResourceCtx,
    sqlite: sqlite3,
    buffers: []VkStruct.Buffer_t,
    fileName: Str,
) !Handle {
    const fileID = fileName.id;

    if (idHandleCache.contains(fileID)) {
        return idHandleCache.get(fileID).?;
    }

    const fileType = file.getFileType(fileID, sqlite) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };

    var handleType: Handles.ResourceType = .others;
    handleType = s: switch (fileType) {
        inline else => |t| {
            inline for (resourceProcess.Mappings) |value| {
                if (value.@"0" == t) {
                    break :s value.@"1";
                }
            }
            break :s .others;
        },
    };

    const handle_ = ctx.handles.createHandle(Handles.WaitFill, handleType);

    const buffers_dupe = try ctx.gpa.dupe(VkStruct.Buffer_t, buffers);
    try ctx.nameArray.append(ctx.io, .{
        .fileType = fileType,
        .handle = handle_,
        .id = fileID,
        .buffers = buffers_dupe,
    });

    try idHandleCache.put(ctx.gpa, fileID, handle_);

    return handle_;
}

pub fn processResource(args: *const ResourceThreadArgs) Io.Cancelable!void {
    const io = args.ctx.io;
    const gpa = args.ctx.gpa;
    const nameArray = args.ctx.nameArray;
    const handleMutex = args.handleMutex;
    const handleArray = args.handleArray;
    const handles = args.ctx.handles;

    r: while (true) {
        try nameArray.mutex.lock(io);
        const pack_ = nameArray.array.pop();
        nameArray.mutex.unlock(io);

        if (pack_) |pack| {
            errdefer handles.destroyHandle(pack.handle);
            defer gpa.free(pack.buffers);

            var sqlite: ?sqlite3 = null;
            while (sqlite == null) {
                try handleMutex.lock(io);
                defer handleMutex.unlock(io);
                sqlite = handleArray.pop();
                try std.Io.sleep(io, .fromMilliseconds(1), .real);
            }

            switch (pack.fileType) {
                inline else => |t| {
                    const readerName = std.fmt.comptimePrint("{s}{s}", .{ @tagName(t), "_Reader" });

                    if (@hasDecl(resourceProcess, readerName)) {
                        const field = @field(resourceProcess, readerName);

                        const index: ReaderReturnType = field.read(
                            t,
                            args.ctx,
                            sqlite.?,
                            pack.id,
                            pack.buffers,
                            args.externalCommands,
                        ) catch |err| {
                            std.log.err("{s} -> err: {s}", .{ readerName, @errorName(err) });
                            switch (err) {
                                ResourceError.Unavaliable => {
                                    nameArray.append(io, pack) catch {};
                                },
                                else => {},
                            }
                            continue :r;
                        };
                        switch (index.rType) {
                            .update => {
                                args.ctx.update.pushLast(.{
                                    .pointer = index.pointer,
                                    .handle = pack.handle,
                                }) catch |err| {
                                    switch (err) {
                                        else => {
                                            nameArray.append(io, pack) catch {};
                                        },
                                    }
                                    continue :r;
                                };
                            },
                            .render => {
                                args.ctx.render.pushLast(.{
                                    .pointer = index.pointer,
                                    .handle = pack.handle,
                                }) catch |err| {
                                    switch (err) {
                                        else => {
                                            nameArray.append(io, pack) catch {};
                                        },
                                    }
                                    continue :r;
                                };
                            },
                        }
                    } else {
                        if (comptime resourceProcess.useExample(t)) {
                            _ = resourceProcess.Example_Reader.read(
                                t,
                                args.ctx,
                                sqlite.?,
                                pack.id,
                                &.{},
                                args.externalCommands,
                            ) catch {};
                        } else {
                            @compileError(std.fmt.comptimePrint("no reader for {s}", .{@tagName(t)}));
                        }
                    }
                },
            }

            var pushSuccess = false;
            while (pushSuccess == false) {
                {
                    try handleMutex.lock(io);
                    defer handleMutex.unlock(io);
                    pushSuccess = handleArray.push(sqlite.?);
                    try std.Io.sleep(io, .fromMilliseconds(1), .real);
                }
            }
        }

        try std.Io.sleep(io, .fromMilliseconds(1), .real);
    }
}
pub fn getResourceHandle(id: u32) ?Handle {
    return idHandleCache.get(id);
}

// fn processResource_Unknown(
//     io: Io,
//     gpa: Allocator,
//     sqlite: sqlite3,
//     fileID: i32,
//     handle: Handle,
//     resourceArray: *MutexArray(Resource),
// ) !void {
//     const f = file.getFile(io, fileID, sqlite) catch |err| {
//         std.log.err("{s}", .{@errorName(err)});
//         return err;
//     };
//     defer f.close(io);

//     const stat = f.stat(io) catch |err| {
//         std.log.err("{s}", .{@errorName(err)});
//         return err;
//     };

//     var buffer = [_]u8{0} ** 8;
//     var reader = f.reader(io, &buffer);
//     try reader.seekTo(0);

//     const content = reader.interface.readAlloc(gpa, stat.size) catch |err| {
//         std.log.err("{s}", .{@errorName(err)});
//         return err;
//     };

//     {
//         try resourceArray.mutex.lock(io);
//         defer resourceArray.mutex.unlock(io);
//         const ptr = resourceArray.array.addOne() catch |err| {
//             std.log.err("{s}", .{@errorName(err)});
//             return err;
//         };
//         ptr.* = .{ .others = .{
//             .fileID = @intCast(fileID),
//             .mem = content,
//             .handle = handle,
//         } };
//     }
// }
