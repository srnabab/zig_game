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

pub const PNG_Reader = struct {
    pub const Ctx = struct {
        pTextureSet: *textureSet,
    };

    pub fn processResource(
        comptime fType: ProcessType,
        io: Io,
        gpa: Allocator,
        sqlite: sqlite3,
        vulkan: *VkStruct,
        fileID: i32,
        handle: Handle,
        buffers: ?[]Buffer_t,
        handles: *global.HandlesType,
        commands: *ExternalCommands,
        uctx: *Ctx,
    ) !void {
        _ = fType;
        _ = buffers;
        _ = handles;
        const pTextureSet = uctx.pTextureSet;

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

        const stagingBuffer = vulkan.createBufferByUsage(pixelSize, 0, .staging, false, null) catch |err| {
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

        _ = try pTextureSet.createTextureFromResource(
            io,
            gpa,

            .{
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
            },
            vulkan,
            commands,
        );
        // std.log.debug("r {s} {d}", .{ @tagName(fType), frame });

        // {
        //     try resourceArray.mutex.lock(io);
        //     defer resourceArray.mutex.unlock(io);
        //     const ptr = resourceArray.array.addOne() catch |err| {
        //         std.log.err("{s}", .{@errorName(err)});
        //         return err;
        //     };
        //     ptr.* = .{ .texture = .{
        //         .width = @intCast(imgWidth),
        //         .height = @intCast(imgHeight),
        //         .fileID = @intCast(fileID),
        //         .vkImage = @ptrFromInt(image.vkImage),
        //         .vkImageView = imageView,
        //         .allocation = @ptrFromInt(image.allocation),
        //         .staginfBuffer = stagingBuffer,
        //         .format = img.image.format,
        //         .handle = handle,
        //         .baseLayer = 0,
        //         .layerCount = 1,
        //         .mipLevels = 0,
        //         .depth = 1,
        //         .regions = region,
        //     } };
        // }
    }
};
