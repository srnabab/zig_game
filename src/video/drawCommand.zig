const std = @import("std");
const texture = @import("textureSet");
const vk = @import("vulkan").vulkan;
const VkStruct = @import("video");
const rendering = @import("rendering");

pub const CommandType = enum {
    start,
    draw2D,
    transLayout,
    changeBufferQueue,
    pipelineBarrier,
    copyBufferToImage,
    copyBuffer,
    bindVertexBuffers,
    beginPrimaryRecord,
    beginRendering,
    bindPipeline,
    bindIndexBuffer,
    bindDescriptorSets,
    beginSecondaryRecord,
    endRendering,
    setViewport,
    setScissor,
    endRecord,
    present,
    graphicTransfer,
    transfer,
    end,
    empty,
};

const privateEnum = [_]CommandType{
    .start,
    .transLayout,
    .changeBufferQueue,
    .bindVertexBuffers,
    .beginPrimaryRecord,
    .beginRendering,
    .beginSecondaryRecord,
    .bindDescriptorSets,
    .bindIndexBuffer,
    .bindPipeline,
    .endRecord,
    .endRendering,
    .end,
    .pipelineBarrier,
    .setScissor,
    .setViewport,
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

    srcQueueFamily: VkStruct.CommandPoolType = .init,
    dstQueueFamily: VkStruct.CommandPoolType = .init,

    // srcAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_NONE,
    // dstAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_NONE,
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
    depthAttachment: ?*vk.VkRenderingAttachmentInfo,
    stencilAttachment: ?*vk.VkRenderingAttachmentInfo,
};

pub const Start = struct {
    graphic: bool = false,
    transfer: bool = false,
    compute: bool = false,
    present: bool = false,
    currentIndex: u32 = std.math.maxInt(u32),
};

const MemoryBarrier = struct {
    srcStageMask: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE,
    srcAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_NONE,
    dstStageMask: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE,
    dstAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_NONE,
};
const BufferMemoryBarrier = struct {
    srcStageMask: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE,
    srcAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_NONE,
    dstStageMask: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE,
    dstAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_NONE,

    srcQueueFamilyIndex: u32,
    dstQueueFamilyIndex: u32,

    buffer: vk.VkBuffer,
    offset: vk.VkDeviceSize,
    size: vk.VkDeviceSize,
};
const ImageMemoryBarrier = struct {
    srcStageMask: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE,
    srcAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_NONE,
    dstStageMask: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE,
    dstAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_NONE,

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
    lastSrcStageMask: vk.VkPipelineStageFlags2 = std.math.maxInt(vk.VkPipelineStageFlags2),
    barriers: []Barrier,
};

const Draw2D = struct {
    pipeline: VkStruct.Pipeline_t,
    rendering: rendering.RenderingInfo_t,
    vertexBuffer: []VkStruct.Buffer_t,
    indexBuffer: VkStruct.Buffer_t,
    descriptorSets: []vk.VkDescriptorSet,
    pTexture: texture.Texture_t,
    pTextureSet: *texture,
    pViewport: VkStruct.Viewport_t,
    pScissor: VkStruct.Scissor_t,
};

const CopyBuffer = struct {
    srcBuffer: VkStruct.Buffer_t,
    dstBuffer: VkStruct.Buffer_t,
    regions: []vk.VkBufferCopy2,
    clean: bool = true,
};

const BindVertexBuffers = struct {
    firstBinding: u32,
    buffers: []vk.VkBuffer,
    offsets: []vk.VkDeviceSize,
    sizes: []vk.VkDeviceSize,
    strides: []vk.VkDeviceSize,
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

const BindPipeline = struct {
    bindPoint: vk.VkPipelineBindPoint,
    pipeline: vk.VkPipeline,
};

const BindIndexBuffer = struct {
    buffer: vk.VkBuffer,
    offset: vk.VkDeviceSize,
    size: vk.VkDeviceSize,
    indexType: vk.VkIndexType,
};

const BindDescriptorSets = struct {
    bindDescriptorSetsInfo: vk.VkBindDescriptorSetsInfo,
    // stageFlags: vk.VkShaderStageFlags,
    // layout: vk.VkPipelineLayout,
    // firstSet: u32,
    // descriptorSets: []vk.VkDescriptorSet,
    // dynamicOffsets: []u32,
};

const Present = struct {
    pipeline: VkStruct.Pipeline_t,
    rendering: rendering.RenderingInfo_t,
    descriptorSets: []vk.VkDescriptorSet,
    pTextures: []texture.Texture_t,
    pTextureSet: *texture,
    pViewport: VkStruct.Viewport_t,
    pScissor: VkStruct.Scissor_t,
};

pub const comm = union {
    start: Start,
    draw2d: Draw2D,
    copyBuffer: CopyBuffer,
    transLayout: TransLayout,
    changeBufferQueue: ChangeBufferQueue,
    bindVertexBuffers: BindVertexBuffers,
    copyBufferToImage: CopyBufferToImage,
    beginRecoed: BeginSecondaryRecord,
    beginRendering: BeginRendering,
    bindPipeline: BindPipeline,
    bindIndexBuffer: BindIndexBuffer,
    bindDescriptorSets: BindDescriptorSets,
    pipelineBarrier: PipelineBarrier,
    endRendering: void,
    setViewport: vk.VkViewport,
    setScissor: vk.VkRect2D,
    present: Present,
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
