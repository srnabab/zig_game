const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

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
const ringBuffer = @import("ringBuffer");

const file = @import("fileSystem");
const sqlite3 = ?*file.sqlite.sqlite3;

const stb_image = @import("stb_image");

const vec3 = vertexStruct.vec3;

pub const ResourceType = enum {
    texture,
    position2D,
    mesh,
    instance,
    meshInstance,
    others,
};

pub const Resource = union(ResourceType) {
    texture: Texture,
    position2D: Position2D,
    mesh: Mesh,
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
    width: u32,
    height: u32,
    fileID: u32,
    format: vk.VkFormat, // 16
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

fn MutexArray(T: type) type {
    return struct {
        const Self = @This();

        mutex: std.Io.Mutex,
        array: std.array_list.Managed(T),

        pub fn init(gpa: std.mem.Allocator) Self {
            return .{
                .mutex = .init,
                .array = .init(gpa),
            };
        }

        pub fn deinit(self: *Self) void {
            self.array.deinit();
        }
    };
}

const Name_FileType_Handle = struct {
    name: []u8,
    fileType: file.FileType,
    handle: Handle,
};

pub const ResourcesQueue = MutexArray(Resource);
pub const NameQueue = MutexArray(Name_FileType_Handle);
pub const DataBaseHandleArrayType = ringBuffer.RingBuffer(sqlite3, 8);

pub const ResourceThreadArgs = struct {
    io: std.Io,
    group: *std.Io.Group,
    gpa: std.mem.Allocator,
    resourceArray: *ResourcesQueue,
    nameArray: *NameQueue,
    handleArray: *DataBaseHandleArrayType,
    handleMutex: *Io.Mutex,
    handles: *global.HandlesType,
    vulkan: *VkStruct,
};

pub fn readResource(io: Io, gpa: std.mem.Allocator, handles: *global.HandlesType, nameArray: *NameQueue, mainSqlite: sqlite3, fileName: []const u8) !?Handle {
    const fileType = file.getFileType(fileName, mainSqlite) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return null;
    };

    var handleType: Handles.ResourceType = .others;
    switch (fileType) {
        .PNG => {
            handleType = .texture;
        },
        .VTX => {
            handleType = .mesh;
        },
        .UNKNOWN => {},
        else => return null,
    }

    const handle_ = handles.createHandle(Handles.WaitFill, handleType);

    try nameArray.mutex.lock(io);
    defer nameArray.mutex.unlock(io);

    const name = try gpa.dupe(u8, fileName);
    try nameArray.array.append(.{
        .fileType = fileType,
        .handle = handle_,
        .name = name,
    });

    return handle_;
}

pub fn processResource(args: ResourceThreadArgs) Io.Cancelable!void {
    const io = args.io;
    const gpa = args.gpa;
    const nameArray = args.nameArray;
    const handleMutex = args.handleMutex;
    const handleArray = args.handleArray;
    const resourceArray = args.resourceArray;
    const vulkan = args.vulkan;

    while (true) {
        try nameArray.mutex.lock(io);
        const pack_ = nameArray.array.pop();
        nameArray.mutex.unlock(io);

        if (pack_) |pack| {
            errdefer args.handles.destroyHandle(pack.handle);
            defer gpa.free(pack.name);

            var sqlite: ?sqlite3 = null;
            while (sqlite == null) {
                try handleMutex.lock(io);
                defer handleMutex.unlock(io);
                sqlite = handleArray.pop();
                try std.Io.sleep(io, .fromMilliseconds(1), .real);
            }

            switch (pack.fileType) {
                .UNKNOWN => {
                    processResource_Unknown(
                        io,
                        gpa,
                        sqlite.?,
                        pack.name,
                        pack.handle,
                        resourceArray,
                    ) catch continue;
                },
                .PNG => {
                    processResource_PNG(
                        io,
                        gpa,
                        sqlite.?,
                        vulkan,
                        pack.name,
                        pack.handle,
                        resourceArray,
                    ) catch continue;
                },
                .VTX => {
                    // std.log.debug("d", .{});
                    processResource_VTX(
                        io,
                        gpa,
                        sqlite.?,
                        vulkan,
                        pack.name,
                        pack.handle,
                        resourceArray,
                    ) catch continue;
                },
                else => {
                    std.log.debug("unsupported type {s}", .{@tagName(pack.fileType)});
                    unreachable;
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
    name: []const u8,
    handle: Handle,
    resourceArray: *MutexArray(Resource),
) !void {
    const fileID = file.getID(name);
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

fn processResource_PNG(
    io: Io,
    gpa: Allocator,
    sqlite: sqlite3,
    vulkan: *VkStruct,
    name: []const u8,
    handle: Handle,
    resourceArray: *MutexArray(Resource),
) !void {
    const fileID = file.getID(name);
    std.log.debug("ID {d}", .{fileID});
    const img = file.getImageLoadParam(io, fileID, sqlite.?) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    defer img.file.close(io);

    const imgStat = img.file.stat(io) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };

    var buffer = [_]u8{0} ** 8;
    var reader = img.file.reader(io, &buffer);
    try reader.seekTo(0);

    const fileMem = reader.interface.readAlloc(gpa, imgStat.size) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    defer gpa.free(fileMem);

    var imgWidth: c_int = 0;
    var imgHeight: c_int = 0;
    var channel: c_int = 0;

    const imageMem = stb_image.stbi_load_from_memory(
        @ptrCast(fileMem.ptr),
        @intCast(fileMem.len),
        @ptrCast(&imgWidth),
        @ptrCast(&imgHeight),
        @ptrCast(&channel),
        stb_image.STBI_rgb_alpha,
    );
    const pixelSize: u64 = @intCast(@sizeOf(u8) * imgWidth * imgHeight * channel);

    const stagingBuffer = vulkan.createBufferByUsage(pixelSize, 0, .staging, false) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    errdefer vulkan.destroyBuffer(stagingBuffer);

    vulkan.buffers.copyDataToMapped(stagingBuffer, 0, u8, imageMem[0..pixelSize]);

    const image = vulkan.createImage2D(
        @intCast(imgWidth),
        @intCast(imgHeight),
        img.image.format,
        img.image.tiling,
        img.image.usage,
    ) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    errdefer vulkan.destroyImage(image);

    const imageView = vulkan.createImageView2D(
        @ptrFromInt(image.vkImage),
        img.image.format,
        vk.VK_IMAGE_ASPECT_COLOR_BIT,
    ) catch |err| {
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
        ptr.* = .{ .texture = .{
            .width = @intCast(imgWidth),
            .height = @intCast(imgHeight),
            .fileID = @intCast(fileID),
            .vkImage = @ptrFromInt(image.vkImage),
            .vkImageView = imageView,
            .allocation = @ptrFromInt(image.allocation),
            .staginfBuffer = stagingBuffer,
            .format = img.image.format,
            .handle = handle,
        } };
    }
}

fn processResource_VTX(
    io: Io,
    gpa: Allocator,
    sqlite: sqlite3,
    vulkan: *VkStruct,
    name: []const u8,
    handle: Handle,
    resourceArray: *MutexArray(Resource),
) !void {
    const fileID = file.getID(name);
    std.log.debug("ID {d}", .{fileID});

    const res = file.getMeshLoadParam(io, fileID, sqlite) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    defer res.file.close(io);

    const stat = try res.file.stat(io);

    var buffer = [_]u8{0} ** 256;
    var fileReader = res.file.reader(io, &buffer);
    var content = fileReader.interface.readAlloc(gpa, stat.size) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    defer gpa.free(content);

    const stride = l: {
        var size: usize = 0;
        switch (res.mesh.vertexType) {
            inline else => |t| {
                size = @sizeOf(vertexStruct.enumToType(t));
            },
        }
        break :l size;
    };

    const vertexCount = res.mesh.verticesSize / stride;
    _ = vertexCount;
    // std.log.debug("vertex count {d}", .{vertexCount});

    const meshletsStart = res.mesh.verticesSize;
    const meshletVerticesStart = res.mesh.meshletsSize + meshletsStart;
    const meshletTrianglesStart = res.mesh.meshletVerticesSize + meshletVerticesStart;
    const end = res.mesh.meshletTrianglesSize + meshletTrianglesStart;

    const vertices = content[0..meshletsStart];
    const meshlets = content[meshletsStart..meshletVerticesStart];
    const meshletVertices = content[meshletVerticesStart..meshletTrianglesStart];
    const meshletTriangles = content[meshletTrianglesStart..end];

    // for (meshletTriangles) |value| {
    //     std.log.debug("value {d}", .{value});
    // }

    const stagingBuffer0 = vulkan.createBufferByUsage(
        vertices.len,
        0,
        .staging,
        false,
    ) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    errdefer vulkan.destroyBuffer(stagingBuffer0);
    vulkan.buffers.copyDataToMapped(stagingBuffer0, 0, u8, vertices);

    const stagingBuffer1 = vulkan.createBufferByUsage(
        meshlets.len,
        0,
        .staging,
        false,
    ) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    errdefer vulkan.destroyBuffer(stagingBuffer1);
    vulkan.buffers.copyDataToMapped(stagingBuffer1, 0, u8, meshlets);

    const stagingBuffer2 = vulkan.createBufferByUsage(
        meshletVertices.len,
        0,
        .staging,
        false,
    ) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    errdefer vulkan.destroyBuffer(stagingBuffer2);
    vulkan.buffers.copyDataToMapped(stagingBuffer2, 0, u8, meshletVertices);

    const stagingBuffer3 = vulkan.createBufferByUsage(
        meshletTriangles.len,
        0,
        .staging,
        false,
    ) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    errdefer vulkan.destroyBuffer(stagingBuffer3);
    vulkan.buffers.copyDataToMapped(stagingBuffer3, 0, u8, meshletTriangles);

    {
        try resourceArray.mutex.lock(io);
        defer resourceArray.mutex.unlock(io);
        const ptr = resourceArray.array.addOne() catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return err;
        };
        ptr.* = .{ .mesh = .{
            .fileID = @intCast(fileID),
            .vertexStride = @intCast(stride),
            .handle = handle,
            .meshletStagingBuffer = stagingBuffer1,
            .verticesStagingBuffer = stagingBuffer0,
            .meshletVerticesStagingBuffer = stagingBuffer2,
            .meshletTrianglesStagingBuffer = stagingBuffer3,
            .meshletSize = @intCast(res.mesh.meshletsSize),
            .verticesSize = @intCast(res.mesh.verticesSize),
            .meshletVerticesSize = @intCast(res.mesh.meshletVerticesSize),
            .meshletTrianglesSize = @intCast(res.mesh.meshletTrianglesSize),
        } };
    }
}
