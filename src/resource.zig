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

const file = @import("fileSystem");
const sqlite3 = ?*file.sqlite.sqlite3;

const stb_image = @import("stb_image");
const ktx = @import("ktx");
// const ktx_vulkan = @import("ktx_vulkan");

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

fn MutexArray(T: type) type {
    return struct {
        const Self = @This();

        const Error = std.Io.Cancelable || Allocator.Error;

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

        pub fn append(self: *Self, io: Io, item: T) Error!void {
            try self.mutex.lock(io);
            defer self.mutex.unlock(io);

            const new_item_ptr = try self.array.addOne();
            new_item_ptr.* = item;
        }
    };
}

const ID_FileType_Handle = struct {
    id: i32,
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
    resourceArray: *ResourcesQueue,
    nameArray: *NameQueue,
    handleArray: *DataBaseHandleArrayType,
    handleMutex: *Io.Mutex,
    handles: *global.HandlesType,
    vulkan: *VkStruct,
};

var idHandleCache: std.AutoHashMapUnmanaged(i32, Handle) = .empty;

pub fn deinit(gpa: Allocator) void {
    idHandleCache.deinit(gpa);
}

pub fn readResource(io: Io, gpa: std.mem.Allocator, handles: *global.HandlesType, nameArray: *NameQueue, mainSqlite: sqlite3, fileName: []const u8) !?Handle {
    const fileID = file.getID(fileName);

    if (idHandleCache.contains(fileID)) {
        return idHandleCache.get(fileID).?;
    }

    const fileType = file.getFileType(fileID, mainSqlite) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return null;
    };

    var handleType: Handles.ResourceType = .others;
    switch (fileType) {
        .PNG, .KTX2 => {
            handleType = .texture;
        },
        .VTX => {
            handleType = .mesh;
        },
        .UNKNOWN => {},
        else => return null,
    }

    const handle_ = handles.createHandle(Handles.WaitFill, handleType);

    try nameArray.append(io, .{
        .fileType = fileType,
        .handle = handle_,
        .id = fileID,
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
    const resourceArray = args.resourceArray;
    const vulkan = args.vulkan;

    while (true) {
        try nameArray.mutex.lock(io);
        const pack_ = nameArray.array.pop();
        nameArray.mutex.unlock(io);

        if (pack_) |pack| {
            errdefer args.handles.destroyHandle(pack.handle);

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
                        pack.id,
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
                        pack.id,
                        pack.handle,
                        resourceArray,
                    ) catch {
                        const ptr = resourceArray.array.addOne() catch |err| {
                            std.debug.panic("{s}", .{@errorName(err)});
                        };
                        ptr.texture.fileID = comptime file.comptimeGetID("non_exist.png");
                        ptr.texture.regions = &.{};
                    };
                },
                .VTX => {
                    // std.log.debug("d", .{});
                    processResource_VTX(
                        io,
                        gpa,
                        sqlite.?,
                        vulkan,
                        pack.id,
                        pack.handle,
                        resourceArray,
                    ) catch continue;
                },
                .KTX2 => {
                    processResource_KTX2(
                        io,
                        gpa,
                        sqlite.?,
                        vulkan,
                        pack.id,
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

fn processResource_PNG(
    io: Io,
    gpa: Allocator,
    sqlite: sqlite3,
    vulkan: *VkStruct,
    fileID: i32,
    handle: Handle,
    resourceArray: *MutexArray(Resource),
) !void {
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

    var region = try gpa.alloc(vk.VkBufferImageCopy, 1);
    region[0] = .{
        .bufferOffset = 0,
        .bufferRowLength = 0,
        .bufferImageHeight = 0,
        .imageSubresource = vk.VkImageSubresourceLayers{
            .aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
            .mipLevel = 0,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
        .imageOffset = vk.VkOffset3D{ .x = 0, .y = 0, .z = 0 },
        .imageExtent = vk.VkExtent3D{
            .width = @intCast(imgWidth),
            .height = @intCast(imgHeight),
            .depth = 1,
        },
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
            .baseLayer = 0,
            .layerCount = 1,
            .mipLevels = 0,
            .depth = 1,
            .regions = region,
        } };
    }
}

fn processResource_VTX(
    io: Io,
    gpa: Allocator,
    sqlite: sqlite3,
    vulkan: *VkStruct,
    fileID: i32,
    handle: Handle,
    resourceArray: *MutexArray(Resource),
) !void {
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

fn processResource_KTX2(
    io: Io,
    gpa: Allocator,
    sqlite: sqlite3,
    vulkan: *VkStruct,
    fileID: i32,
    handle: Handle,
    resourceArray: *MutexArray(Resource),
) !void {
    const img = file.getFile(io, fileID, sqlite.?) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    defer img.close(io);

    const imgStat = img.stat(io) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };

    var buffer = [_]u8{0} ** 8;
    var reader = img.reader(io, &buffer);
    try reader.seekTo(0);

    const fileMem = reader.interface.readAlloc(gpa, imgStat.size) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    defer gpa.free(fileMem);

    var texture: [*c]ktx.ktxTexture2 = null;
    const res = ktx.ktxTexture2_CreateFromMemory(
        fileMem.ptr,
        fileMem.len,
        ktx.KTX_TEXTURE_CREATE_LOAD_IMAGE_DATA_BIT,
        &texture,
    );
    assert(res == ktx.KTX_SUCCESS);

    const imgWidth = texture.*.baseWidth;
    const imgHeight = texture.*.baseHeight;
    const imgDepth = texture.*.baseDepth;

    const pixelSize: u64 = texture.*.dataSize;

    const stagingBuffer = vulkan.createBufferByUsage(pixelSize, 0, .staging, false) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    errdefer vulkan.destroyBuffer(stagingBuffer);

    vulkan.buffers.copyDataToMapped(stagingBuffer, 0, u8, texture.*.pData[0..pixelSize]);

    const imageType, const imageViewType = blk: switch (texture.*.numDimensions) {
        1 => {
            if (texture.*.isArray) break :blk .{ vk.VK_IMAGE_TYPE_1D, vk.VK_IMAGE_VIEW_TYPE_1D_ARRAY };
            break :blk .{ vk.VK_IMAGE_TYPE_1D, vk.VK_IMAGE_VIEW_TYPE_1D };
        },
        2 => {
            if (texture.*.isCubemap) {
                if (texture.*.isArray) break :blk .{ vk.VK_IMAGE_TYPE_2D, vk.VK_IMAGE_VIEW_TYPE_CUBE_ARRAY };
                break :blk .{ vk.VK_IMAGE_TYPE_2D, vk.VK_IMAGE_VIEW_TYPE_CUBE };
            }
            if (texture.*.isArray) break :blk .{ vk.VK_IMAGE_TYPE_2D, vk.VK_IMAGE_VIEW_TYPE_2D_ARRAY };
            break :blk .{ vk.VK_IMAGE_TYPE_2D, vk.VK_IMAGE_VIEW_TYPE_2D };
        },
        3 => .{ vk.VK_IMAGE_TYPE_3D, vk.VK_IMAGE_VIEW_TYPE_3D },
        else => unreachable,
    };

    const image = vulkan._createVkImage(
        null,
        0,
        @intCast(imageType),
        texture.*.vkFormat,
        .{ .width = imgWidth, .height = imgHeight, .depth = imgDepth },
        texture.*.numLevels,
        texture.*.numLayers,
        vk.VK_SAMPLE_COUNT_1_BIT,
        vk.VK_IMAGE_TILING_OPTIMAL,
        vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT | vk.VK_IMAGE_USAGE_SAMPLED_BIT,
        vk.VK_SHARING_MODE_EXCLUSIVE,
        0,
        null,
        .VK_IMAGE_LAYOUT_UNDEFINED,
    ) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };
    errdefer vulkan.destroyImage(image);

    const imageView = vulkan._createImageView(
        null,
        0,
        @ptrFromInt(image.vkImage),
        @intCast(imageViewType),
        texture.*.vkFormat,

        vk.VkComponentMapping{
            .r = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
            .g = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
            .b = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
            .a = vk.VK_COMPONENT_SWIZZLE_IDENTITY,
        },
        vk.VK_IMAGE_ASPECT_COLOR_BIT,
        0,
        texture.*.numLevels,
        0,
        texture.*.numLayers,
    ) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return err;
    };

    const regions = try gpa.alloc(vk.VkBufferImageCopy, texture.*.numLayers * texture.*.numFaces * texture.*.numLevels);
    errdefer gpa.free(regions);

    // std.log.debug("layers {d}, dimension {d}", .{ texture.*.numLayers, texture.*.numDimensions });

    for (0..texture.*.numLayers) |l| {
        for (0..texture.*.numFaces) |f| {
            for (0..texture.*.numLevels) |level| {
                const index = l * texture.*.numFaces * texture.*.numLevels + f * texture.*.numLevels + level;
                var offset: u64 = 0;
                const err = ktx.ktxTexture2_GetImageOffset(texture, @intCast(level), @intCast(l), @intCast(f), &offset);
                assert(err == ktx.KTX_SUCCESS);

                regions[index] = vk.VkBufferImageCopy{
                    .bufferOffset = offset,
                    .bufferRowLength = 0,
                    .bufferImageHeight = 0,
                    .imageSubresource = vk.VkImageSubresourceLayers{
                        .aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT,
                        .mipLevel = @intCast(level),
                        .baseArrayLayer = @intCast(f),
                        .layerCount = 1,
                    },
                    .imageOffset = vk.VkOffset3D{ .x = 0, .y = 0, .z = 0 },
                    .imageExtent = vk.VkExtent3D{
                        .width = imgWidth >> @intCast(level),
                        .height = imgHeight >> @intCast(level),
                        .depth = imgDepth >> @intCast(level),
                    },
                };
                // std.log.debug("{d} {d} {d}", .{ l, f, level });
            }
        }
    }

    {
        try resourceArray.mutex.lock(io);
        defer resourceArray.mutex.unlock(io);
        const ptr = resourceArray.array.addOne() catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return err;
        };
        ptr.* = .{ .texture = .{
            .regions = regions,
            .width = @intCast(imgWidth),
            .height = @intCast(imgHeight),
            .depth = @intCast(imgDepth),
            .baseLayer = 0,
            .layerCount = texture.*.numLayers,
            .mipLevels = texture.*.numLevels,
            .fileID = @intCast(fileID),
            .vkImage = @ptrFromInt(image.vkImage),
            .vkImageView = imageView,
            .allocation = @ptrFromInt(image.allocation),
            .staginfBuffer = stagingBuffer,
            .format = texture.*.vkFormat,
            .handle = handle,
        } };
    }
}
