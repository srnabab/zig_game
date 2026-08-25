const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const mstd = @import("ms_std");

const vk = @import("vk");
const vma = @import("vma");
const VkStruct = @import("video");
const Handles = @import("handle");
const Handle = Handles.Handle;

const Texture_t = @import("textureSet").Texture_t;
const vertexStruct = @import("vertexStruct");
const Mesh_t = @import("mesh").Mesh_t;
const Instance_t = @import("instance").Instance_t;
const global = @import("global");
const ringBuffer = mstd.RingBuffer;
const MutexArray = mstd.MutexArray;
const ExternalCommands = @import("processRender").externalCommands;
const mesh = @import("mesh");

const file = @import("fileSystem");
const sqlite3 = ?*file.sqlite.sqlite3;

const stb_image = @import("stb_image");
// const ktx_vulkan = @import("ktx_vulkan");

const vec3 = vertexStruct.vec3;

const resourceProcess = @import("resourceProcess");

pub const ResourceType = enum {
    // texture,
    position2D,
    // mesh,
    instance,
    meshInstance,
    others,
};

pub const Resource = union(ResourceType) {
    // texture: Texture,
    position2D: Position2D,
    // mesh: Mesh,
    instance: Instance,
    meshInstance: MeshInstance,
    others: Others,
};

pub const MeshInstance = struct {
    passName: []const u8,
    mesh: Mesh_t,
    instance: Instance_t,
};

pub const Instance = struct {
    texture: ?Texture_t,
    handle: Handles.Handle,
    sampler: ?u32,
    pos: vec3,
    scale: vec3,
    rotation: vec3,
};

pub const Mesh = struct {
    fileID: u32,
    vertexStride: u32,
    handle: Handles.Handle,
    meshletStagingBuffer: VkStruct.Buffer_t,
    verticesStagingBuffer: VkStruct.Buffer_t,
    meshletVerticesStagingBuffer: VkStruct.Buffer_t,
    meshletTrianglesStagingBuffer: VkStruct.Buffer_t,
    meshletSize: u32,
    verticesSize: u32,
    meshletVerticesSize: u32,
    meshletTrianglesSize: u32,
};

pub const Texture = struct {
    regions: []vk.VkBufferImageCopy,
    width: u32,
    height: u32,
    depth: u32,
    fileID: u32,
    format: vk.VkFormat,
    baseLayer: u32,
    layerCount: u32,
    mipLevels: u32,
    vkImage: vk.VkImage,
    vkImageView: vk.VkImageView,
    allocation: vma.VmaAllocation,
    staginfBuffer: VkStruct.Buffer_t,
    handle: Handles.Handle,
};

pub const Others = struct {
    fileID: u32,
    mem: []u8,
    handle: Handles.Handle,
};

pub const Position2D = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    depth: f32,
    texture: Texture_t,
};

const ID_FileType_Handle = struct {
    id: i32,
    buffers: []VkStruct.Buffer_t,
    fileType: file.FileType,
    handle: Handle,
};

pub const ResourcesQueue = MutexArray(Resource);
pub const NameQueue = MutexArray(ID_FileType_Handle);
pub const DataBaseHandleArrayType = ringBuffer(sqlite3, 8);

pub const ResourceThreadArgs = struct {
    io: std.Io,
    group: *std.Io.Group,
    gpa: std.mem.Allocator,
    nameArray: *NameQueue,
    handleArray: *DataBaseHandleArrayType,
    handleMutex: *Io.Mutex,
    handles: *global.HandlesType,
    vulkan: *VkStruct,
    externalCommands: *ExternalCommands,
    uctx: *resourceProcess.UserContext,
};

var idHandleCache: std.AutoHashMapUnmanaged(i32, Handle) = .empty;

pub fn deinit(gpa: Allocator) void {
    idHandleCache.deinit(gpa);
}

pub fn readResource(
    io: Io,
    gpa: std.mem.Allocator,
    handles: *global.HandlesType,
    nameArray: *NameQueue,
    mainSqlite: sqlite3,
    buffers: []VkStruct.Buffer_t,
    fileName: []const u8,
) !?Handle {
    const fileID = file.getID(fileName);

    if (idHandleCache.contains(fileID)) {
        return idHandleCache.get(fileID).?;
    }

    const fileType = file.getFileType(fileID, mainSqlite) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return null;
    };

    var handleType: Handles.ResourceType = .others;
    handleType = s: switch (fileType) {
        inline else => |t| {
            inline for (resourceProcess.Mappings) |value| {
                if (value.@"0" == t) {
                    break :s value.@"1";
                }
            }
            return null;
        },
    };

    const handle_ = handles.createHandle(Handles.WaitFill, handleType);

    const buffers_dupe = try gpa.dupe(VkStruct.Buffer_t, buffers);
    try nameArray.append(io, .{
        .fileType = fileType,
        .handle = handle_,
        .id = fileID,
        .buffers = buffers_dupe,
    });

    try idHandleCache.put(gpa, fileID, handle_);

    return handle_;
}

pub fn processResource(args: ResourceThreadArgs) Io.Cancelable!void {
    const io = args.io;
    const gpa = args.gpa;
    const nameArray = args.nameArray;
    const handleMutex = args.handleMutex;
    const handleArray = args.handleArray;
    const vulkan = args.vulkan;

    while (true) {
        try nameArray.mutex.lock(io);
        const pack_ = nameArray.array.pop();
        nameArray.mutex.unlock(io);

        if (pack_) |pack| {
            errdefer args.handles.destroyHandle(pack.handle);
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
                        const testBuffers = gpa.alloc(VkStruct.Buffer_t, 4) catch {
                            return Io.Cancelable.Canceled;
                        };
                        defer gpa.free(testBuffers);

                        testBuffers[0] = vulkan.buffers.getBuffer("featherMeshlet").?;
                        testBuffers[1] = vulkan.buffers.getBuffer("featherVertices").?;
                        testBuffers[2] = vulkan.buffers.getBuffer("featherMeshletVertices").?;
                        testBuffers[3] = vulkan.buffers.getBuffer("featherMeshletTriangles").?;

                        const field = @field(resourceProcess, readerName);

                        var ctx: field.Ctx = undefined;
                        const ctxInfo = @typeInfo(field.Ctx);
                        inline for (ctxInfo.@"struct".fields) |f| {
                            @field(ctx, f.name) = &@field(args.uctx, f.name);
                        }

                        field.processResource(
                            t,
                            io,
                            gpa,
                            sqlite.?,
                            vulkan,
                            pack.id,
                            pack.handle,
                            testBuffers,
                            args.handles,
                            args.externalCommands,
                            &ctx,
                        ) catch continue;
                    } else {
                        try resourceProcess.Example_Reader.processResource(
                            t,
                            io,
                            gpa,
                            sqlite.?,
                            vulkan,
                            pack.id,
                            pack.handle,
                            &.{},
                            args.handles,
                            args.externalCommands,
                            @constCast(&resourceProcess.Example_Reader.Ctx{}),
                        );
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

fn processResource_Unknown(
    io: Io,
    gpa: Allocator,
    sqlite: sqlite3,
    fileID: i32,
    handle: Handle,
    resourceArray: *MutexArray(Resource),
) !void {
    const f = file.getFile(io, fileID, sqlite) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    defer f.close(io);

    const stat = f.stat(io) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };

    var buffer = [_]u8{0} ** 8;
    var reader = f.reader(io, &buffer);
    try reader.seekTo(0);

    const content = reader.interface.readAlloc(gpa, stat.size) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };

    {
        try resourceArray.mutex.lock(io);
        defer resourceArray.mutex.unlock(io);
        const ptr = resourceArray.array.addOne() catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return err;
        };
        ptr.* = .{ .others = .{
            .fileID = @intCast(fileID),
            .mem = content,
            .handle = handle,
        } };
    }
}
