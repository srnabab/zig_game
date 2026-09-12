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
const Handles = @import("handle");
const Handle = Handles.Handle;
const mstd = @import("ms_std");
const MutexArray = mstd.MutexArray;
const resource = @import("resource");
const Resource = resource.Resource;

const stb_image = @import("stb_image");
const Buffer_t = VkStruct.Buffer_t;
const ExternalCommands = @import("processRender").externalCommands;
const Commands = @import("processRender").commands;
const mesh = @import("mesh");
const textureSet = @import("textureSet");

pub const PNG = [_]u8{
    0x89,
    std.mem.bytesToValue(u8, "P"),
    std.mem.bytesToValue(u8, "N"),
    std.mem.bytesToValue(u8, "G"),
};

pub const PNG_Cooker = struct {
    pub const TableName = "ImageLoadParameterT";
    pub const Enable = true;

    const TbaleType = tables.ImageLoadParameter;

    pub fn preProcess(
        io: Io,
        gpa: Allocator,
        dir: Io.Dir,
        parmas: *PreProcessParm,
        ImageLoadParameterT: *TbaleType,
    ) !void {
        _ = io;
        _ = gpa;
        _ = dir;

        const format: vk.VkFormat, const tiling: vk.VkImageTiling, const usage: vk.VkImageUsageFlags, const properties: vk.VkMemoryPropertyFlags = try judgeImageLoadParameter(parmas.fileName);

        try ImageLoadParameterT.update("Format,Tiling,Usage,Properties", "FileName = ?", .{ format, tiling, usage, properties, parmas.fileName });
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
        _ = io;
        _ = gpa;
        _ = contentFolderPath;
        _ = fileName;
        _ = content;
        _ = fullPath;
        _ = database;
    }

    pub fn judgeFileType2(content: []u8, fType: ProcessType) ProcessType {
        _ = fType;
        if (std.mem.eql(u8, content[0..PNG.len], @constCast(&PNG))) {
            return .PNG;
        }
        return judgeFileTypeByContent(content);
    }

    fn judgeImageLoadParameter(fileName: []const u8) !struct {
        vk.VkFormat,
        vk.VkImageTiling,
        vk.VkImageUsageFlags,
        vk.VkMemoryPropertyFlags,
    } {
        _ = fileName;
        // var format: vk.VkFormat = 0;
        // var tiling: vk.VkImageTiling = 0;
        // var usage: vk.VkImageUsageFlags = 0;
        // var properties: vk.VkMemoryPropertyFlags = 0;

        // return .{ format, tiling, usage, properties };
        return .{ vk.VK_FORMAT_R8G8B8A8_SRGB, vk.VK_IMAGE_TILING_OPTIMAL, vk.VK_IMAGE_USAGE_TRANSFER_DST_BIT | vk.VK_IMAGE_USAGE_SAMPLED_BIT, vk.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT };
    }
};

const ResourceError = resource.ResourceError;

pub const PNG_Reader = struct {
    const Self = @This();
    pub const Ctx = struct {
        pTextureSet: *textureSet,
    };

    pub const Child = struct {
        pub const Parent = PNG_Reader;

        texture: textureSet.ResourceTexture,
    };

    pub fn read(
        comptime fType: ProcessType,
        ctx: *const resource.ResourceCtx,
        sqlite: sqlite3,
        fileID: u32,
        buffers: ?[]Buffer_t,
        commands: *ExternalCommands,
    ) ResourceError!resource.ReaderReturnType {
        _ = fType;
        _ = buffers;
        _ = commands;
        const io = ctx.io;
        const gpa = ctx.gpa;
        const vulkan = ctx.vulkan;
        // const pTextureSet = uctx.pTextureSet;

        const img = file.getImageLoadParam(io, fileID, sqlite.?) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };
        defer img.file.close(io);

        const imgStat = img.file.stat(io) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };

        var buffer = [_]u8{0} ** 8;
        var reader = img.file.reader(io, &buffer);
        reader.seekTo(0) catch return ResourceError.Unavaliable;

        const fileMem = reader.interface.readAlloc(gpa, imgStat.size) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
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

        const stagingBuffer = vulkan.createBufferByUsage(pixelSize, 0, .staging, false, null) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
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
            return ResourceError.Unavaliable;
        };
        errdefer vulkan.destroyImage(image);

        const imageView = vulkan.createImageView2D(
            @ptrFromInt(image.vkImage),
            img.image.format,
            vk.VK_IMAGE_ASPECT_COLOR_BIT,
        ) catch |err| {
            std.log.err("{s}", .{@errorName(err)});
            return ResourceError.Unavaliable;
        };

        var region = gpa.alloc(vk.VkBufferImageCopy, 1) catch return ResourceError.Unavaliable;
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

        const ptr = gpa.create(Child) catch return ResourceError.Unavaliable;
        ptr.texture = .{
            .width = @intCast(imgWidth),
            .height = @intCast(imgHeight),
            .fileID = @intCast(fileID),
            .vkImage = @ptrFromInt(image.vkImage),
            .vkImageView = imageView,
            .allocation = @ptrFromInt(image.allocation),
            .staginfBuffer = stagingBuffer,
            .format = img.image.format,
            // .handle = handle,
            .baseLayer = 0,
            .layerCount = 1,
            .mipLevels = 0,
            .depth = 1,
            .regions = region,
        };

        return .{ .rType = .render, .pointer = resourceProcess.UnionInit(Self, ptr) };
    }

    pub fn load(io: Io, gpa: Allocator, vulkan: *VkStruct, commands: *Commands, uctx: *Ctx, handle: Handle, pointer: *Child) !u32 {
        defer gpa.destroy(pointer);

        return uctx.pTextureSet.createTextureFromResource(
            io,
            gpa,
            pointer.texture,
            vulkan,
            commands,
            handle,
        );
    }
};
