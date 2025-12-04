const std = @import("std");
const texture = @import("textureSet");
const vk = @import("vulkan").vulkan;
const VkStruct = @import("video");

pub const CommandType = enum {
    start,
    draw2D,
    transLayout,
    changeBufferQueue,
    changeTextureQueue,
    pipelineBarrier,
    copyBufferToImage,
    copyBuffer,
    bindVertexBuffer,
    beginPrimaryRecord,
    beginRendering,
    beginSecondaryRecord,
    endRendering,
    endRecord,
    present,
    graphicTransfer,
    transfer,
    end,
};

const privateEnum = [_]CommandType{
    .start,
    .transLayout,
    .changeBufferQueue,
    .changeTextureQueue,
    .bindVertexBuffer,
    .beginPrimaryRecord,
    .beginRendering,
    .beginSecondaryRecord,
    .endRecord,
    .endRendering,
    .end,
    .pipelineBarrier,
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

    a: for (ct.fields) |value| {
        if (count < privateEnum.len) {
            for (privateEnum) |ee| {
                if (@intFromEnum(ee) == value.value) {
                    count += 1;
                    continue :a;
                }
            }
        }

        pe[i].name = value.name;
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
    return @enumFromInt(@intFromEnum(a));
}

pub fn PrivateCommandTypeToCommandType(a: PrivateCommandType) CommandType {
    return @enumFromInt(@intFromEnum(a));
}

const TransLayout = struct {
    // pTexture: texture.Texture_t,

    image: vk.VkImage,
    oldLayout: vk.VkImageLayout,
    newLayout: vk.VkImageLayout,
    baseLayer: u32,
    layerCount: u32,

    // srcAccessMask: vk.VkAccessFlags = vk.VK_ACCESS_NONE,
    // dstAccessMask: vk.VkAccessFlags = vk.VK_ACCESS_NONE,
    // aspectMask: vk.VkImageAspectFlags = vk.VK_IMAGE_ASPECT_NONE,
    // sourceStage: vk.VkPipelineStageFlags = vk.VK_PIPELINE_STAGE_NONE,
    // destinationStage: vk.VkPipelineStageFlags = vk.VK_PIPELINE_STAGE_NONE,

    baseMipLevel: u32 = 0,
    levelCount: u32 = 1,
};

pub const CopyBufferToImage = struct {
    pTexture: texture.Texture_t,
    pTextureSet: *texture,

    width: u32,
    height: u32,
    depth: u32 = 1,

    dstImage: vk.VkImage = null,
    dstImageLayout: vk.VkImageLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
    aspectMask: vk.VkImageAspectFlags = vk.VK_IMAGE_ASPECT_COLOR_BIT,
    mipLevel: u32 = 0,
    baseArrayLayer: u32 = 0,
    layerCount: u32 = 1,

    buffer: VkStruct.Buffer_t,
    bufferRowLength: u32 = 0,
    bufferImageHegiht: u32 = 0,

    imageOffset: vk.VkOffset3D = .{
        .x = 0,
        .y = 0,
        .z = 0,
    },

    clean: bool = true,
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

const MemoryBarrier = struct {
    srcAccessMask: vk.VkAccessFlags = vk.VK_ACCESS_NONE,
    dstAccessMask: vk.VkAccessFlags = vk.VK_ACCESS_NONE,
};
const BufferMemoryBarrier = struct {
    srcAccessMask: vk.VkAccessFlags = vk.VK_ACCESS_NONE,
    dstAccessMask: vk.VkAccessFlags = vk.VK_ACCESS_NONE,

    srcQueueFamilyIndex: u32,
    dstQueueFamilyIndex: u32,

    buffer: vk.VkBuffer,
    offset: vk.VkDeviceSize,
    size: vk.VkDeviceSize,
};
const ImageMemoryBarrier = struct {
    srcAccessMask: vk.VkAccessFlags = vk.VK_ACCESS_NONE,
    dstAccessMask: vk.VkAccessFlags = vk.VK_ACCESS_NONE,

    oldLayout: vk.VkImageLayout,
    newLayout: vk.VkImageLayout,

    srcQueueFamilyIndex: u32,
    dstQueueFamilyIndex: u32,

    image: vk.VkImage,
    subresourceRange: vk.VkImageSubresourceRange,
};

const BarrierType = enum { memory, bufferMemory, imageMemory };
pub const Barrier = union(BarrierType) {
    memory: MemoryBarrier,
    bufferMemory: BufferMemoryBarrier,
    imageMemory: ImageMemoryBarrier,
};
const PipelineBarrier = struct {
    sourceStage: vk.VkPipelineStageFlags = vk.VK_PIPELINE_STAGE_NONE,
    destinationStage: vk.VkPipelineStageFlags = vk.VK_PIPELINE_STAGE_NONE,
    barriers: []Barrier,
};

const Draw2D = struct {
    pipeline: VkStruct.Pipeline,
    // vertexBuffer: VkStruct.Buffer,
    // indexBuffer: VkStruct.Buffer,
    pTexture: *texture.Texture,
};

const CopyBuffer = struct {
    srcBuffer: VkStruct.Buffer_t,
    dstBuffer: VkStruct.Buffer_t,
    regions: []vk.VkBufferCopy,
    clean: bool = true,
};

const BindVertexBuffer = struct {
    firstBinding: u32,
    buffers: []VkStruct.Buffer_t,
};

pub const SizeOffset = struct {
    size: vk.VkDeviceSize,
    offset: vk.VkDeviceSize,
};

const ChangeBufferQueue = struct {
    buffer: VkStruct.Buffer_t,
    srcQueueFamily: VkStruct.CommandPoolType,
    dstQueueFamily: VkStruct.CommandPoolType,
    regions: []SizeOffset,
};

const ChangeTextureQueue = struct {
    texture: texture.Texture_t,
    srcQueueFamily: VkStruct.CommandPoolType,
    dstQueueFamily: VkStruct.CommandPoolType,
};

pub const comm = union {
    start: Start,
    draw2d: Draw2D,
    copyBuffer: CopyBuffer,
    transLayout: TransLayout,
    changeBufferQueue: ChangeBufferQueue,
    changeTextureQueue: ChangeTextureQueue,
    bindVertexBuffer: BindVertexBuffer,
    copyBufferToImage: CopyBufferToImage,
    beginRecoed: BeginSecondaryRecord,
    beginRendering: BeginRendering,
    pipelineBarrier: PipelineBarrier,
    empty: void,
};

pub const Output = union {
    image: vk.VkImage,
    buffer: VkStruct.Buffer_t,
    empty: void,
};

pub const BufferUsage = enum {
    none,
    vertex,
    index,
    uniform,
    // transfer,
    storage,
    staging,
};

// pub const TextureUsage = enum {
//     none,
//     color,
//     shader,
// };

commandType: CommandType,
timestamp: i128,
ID: u32,

command: comm,
output: Output,

fn empty() void {
    //
}
