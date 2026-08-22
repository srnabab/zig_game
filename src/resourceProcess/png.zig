const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const vk = @import("vulkan");
const tables = @import("tables");
const resourceProcess = @import("../resourceProcess.zig");
const PreProcessParm = resourceProcess.PreProcessParm;
const db = @import("db");
const ProcessType = resourceProcess.ProcessType;

const judgeFileTypeByContent = resourceProcess.judgeFileTypeByContent;

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
