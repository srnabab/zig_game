const std = @import("std");
const texture = @import("textureSet");
const vk = @import("vulkan").vulkan;
const VkStruct = @import("video");

pub const CommandType = enum {
    start,
    graphic,
    transLayout,
    copyBufferToImage,
    beginPrimaryRecord,
    beginRendering,
    beginSecondaryRecord,
    endRendering,
    endRecord,
    present,
    graphicTransfer,
    trasfer,
    end,
};

const privateEnum = [_]CommandType{
    .start,
    .transLayout,
    .beginPrimaryRecord,
    .beginRendering,
    .beginSecondaryRecord,
    .endRecord,
    .endRendering,
    .end,
};

pub const PrivateCommandType: type = blk: {
    const ct = @typeInfo(CommandType).@"enum";
    var pe: [1024]std.builtin.Type.EnumField = undefined;

    var count: usize = 0;

    for (ct.fields) |value| {
        if (count < privateEnum.len) {
            for (privateEnum) |ee| {
                if (@intFromEnum(ee) == value.value) {
                    pe[count].name = value.name;
                    pe[count].value = value.value;

                    count += 1;
                    break;
                }
            }
            continue;
        }
        break;
    }

    break :blk @Type(.{ .@"enum" = .{
        .decls = &.{},
        .fields = pe[0..count],
        .is_exhaustive = true,
        .tag_type = u32,
    } });
};

pub const PublicCommandType: type = blk: {
    const ct = @typeInfo(CommandType).@"enum";
    var pe: [1024]std.builtin.Type.EnumField = undefined;

    var count: usize = 0;
    var i: usize = 0;

    a: for (ct.fields, ct.decls) |value, decl| {
        if (count < privateEnum.len) {
            for (privateEnum) |ee| {
                if (@intFromEnum(ee) == value.value) {
                    count += 1;
                    continue :a;
                }
            }
        }

        pe[i].name = decl.name;
        pe[i].value = value.value;
        i += 1;
    }

    break :blk @Type(.{ .@"enum" = .{
        .tag_type = u32,
        .fields = pe[0..i],
        .decls = &.{},
        .is_exhaustive = true,
    } });
};

pub fn PublicCommandTypeToCommandType(a: PublicCommandType) CommandType {
    return switch (a) {
        .graphic => .graphic,
        .copyBufferToImage => .copyBufferToImage,
        .present => .present,
    };
}

const TransLayout = struct {
    pTexture: *texture,

    oldLayout: vk.VkImageLayout,
    newLayout: vk.VkImageLayout,
    baseLayer: u32,
    layerCount: u32,

    srcAccessMask: vk.VkAccessFlags = vk.VK_ACCESS_NONE,
    dstAccessMask: vk.VkAccessFlags = vk.VK_ACCESS_NONE,
    aspectMask: vk.VkImageAspectFlags = vk.VK_IMAGE_ASPECT_NONE,
    sourceStage: vk.VkPipelineStageFlags = vk.VK_PIPELINE_STAGE_NONE,
    destinationStage: vk.VkPipelineStageFlags = vk.VK_PIPELINE_STAGE_NONE,

    baseMipLevel: u32 = 0,
    levelCount: u32 = 0,
};

pub const CopyBufferToImage = struct {
    pTexture: *texture,

    width: u32,
    height: u32,
    depth: u32 = 1,

    dstImageLayout: vk.VkImageLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    aspectMask: vk.VkImageAspectFlags = vk.VK_IMAGE_ASPECT_COLOR_BIT,
    mipLevel: u32 = 0,
    baseArrayLayer: u32 = 0,
    layerCount: u32 = 1,

    buffer: VkStruct.Buffer,
    bufferRowLength: u32 = 0,
    bufferImageHegiht: u32 = 0,

    imageOffset: vk.VkOffset3D = .{
        .x = 0,
        .y = 0,
        .z = 0,
    },
};

pub const BeginSecondaryRecord = struct {
    rendering: bool = false,
    occulusionQueryEnable: vk.VkBool32,
    queryFlags: vk.VkQueryControlFlags,
    pipelineStatistics: vk.VkQueryPipelineStatisticFlags,
    flags: vk.VkRenderingFlags,
    viewMask: u32,
    pColorAttachmentFormats: []vk.VkFormat,
    depthAttachmentFormat: vk.VkFormat,
    stencilAttachmentFormat: vk.VkFormat,
    rasterizationSamples: vk.VkSampleCountFlagBits,
};

pub const BeginRendering = struct {
    flags: vk.VkRenderingFlags,
    renderArea: vk.VkRect2D,
    layerCount: u32,
    viewMask: u32,
    pColorAttachments: []vk.VkRenderingAttachmentInfo,
    depthAttachment: vk.VkRenderingAttachmentInfo,
    stencilAttachment: vk.VkRenderingAttachmentInfo,
};

pub const Start = struct {
    graphic: bool = false,
    transfer: bool = false,
    compute: bool = false,
    present: bool = false,
};

pub const comm = union {
    start: Start,
    transLayout: TransLayout,
    copyBufferToImage: CopyBufferToImage,
    beginRecoed: BeginSecondaryRecord,
    beginRendering: BeginRendering,
    empty: void,
};

pub const Output = union {
    image: vk.VkImage,
    empty: void,
};

commandType: CommandType,
timestamp: i128 = 0,
ID: u32,

command: comm,
output: Output,
