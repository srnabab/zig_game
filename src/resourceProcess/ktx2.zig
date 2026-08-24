const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

const global = @import("global");

const resourceProcess = @import("../resourceProcess.zig");
const PreProcessParm = resourceProcess.PreProcessParm;
const ProcessType = resourceProcess.ProcessType;

const vk = @import("vk");
const file = @import("fileSystem");
const sqlite3 = ?*file.sqlite.sqlite3;
const VkStruct = @import("video");
const Handles = @import("handle");
const Handle = Handles.Handle;
const mstd = @import("ms_std");
const MutexArray = mstd.MutexArray;
const resource = @import("resource");

const Resource = resource.Resource;

const ktx = @import("ktx");

const Buffer_t = VkStruct.Buffer_t;
const ExternalCommands = @import("processRender").externalCommands;
const mesh = @import("mesh");

pub const KTX2_Reader = struct {
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
        meshes: *mesh,
        resourceArray: *MutexArray(Resource),
    ) !void {
        _ = fType;
        _ = buffers;
        _ = handles;
        _ = commands;
        _ = meshes;
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

        const stagingBuffer = vulkan.createBufferByUsage(pixelSize, 0, .staging, false, null) catch |err| {
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
};
