const std = @import("std");
const texture = @import("textureSet");
const VkStruct = @import("video");
const vk = VkStruct.vk;
const rendering = @import("rendering");

pub const CommandType = enum {
    compute,
    copyBuffer,
    copyBufferToImage,
    draw2D,
    drawIndirect,
    drawMesh,
    empty,
    present,
};

pub const comm = union(CommandType) {
    compute: Compute,
    copyBuffer: CopyBuffer,
    copyBufferToImage: CopyBufferToImage,
    draw2D: Draw2D,
    drawIndirect: DrawIndirect,
    drawMesh: DrawMesh,
    empty: void,
    present: Present,
};

pub const CommandType2 = enum {
    beginRendering,
    beginSecondaryRecord,
    bindDescriptorSets,
    bindIndexBuffer,
    bindPipeline,
    bindVertexBuffers,
    changeBufferQueue,
    computeRecord,
    copyBuffer,
    copyBufferToImage,
    draw2DRecord,
    drawIndirectRecord,
    drawMeshRecord,
    empty,
    end,
    endRecord,
    endRendering,
    pipelineBarrier,
    presentRecord,
    pushconstant,
    setScissor,
    setViewport,
    start,
    transLayout,
};

pub const comm2 = union(CommandType2) {
    beginRendering: BeginRendering,
    beginSecondaryRecord: BeginSecondaryRecord,
    bindDescriptorSets: BindDescriptorSets,
    bindIndexBuffer: BindIndexBuffer,
    bindPipeline: BindPipeline,
    bindVertexBuffers: BindVertexBuffers,
    changeBufferQueue: ChangeBufferQueue,
    computeRecord: ComputeRecord,
    copyBuffer: CopyBuffer,
    copyBufferToImage: CopyBufferToImage,
    draw2DRecord: Draw2DRecord,
    drawIndirectRecord: DrawIndirectRecord,
    drawMeshRecord: DrawMeshRecord,
    empty: void,
    end: void,
    endRecord: void,
    endRendering: void,
    pipelineBarrier: PipelineBarrier,
    presentRecord: PresentRecord,
    pushconstant: PushConstant,
    setScissor: vk.VkRect2D,
    setViewport: vk.VkViewport,
    start: Start,
    transLayout: TransLayout,
};

pub const TransLayout = struct {
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

    width: u32,
    height: u32,
    depth: u32 = 1,

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

pub const MemoryBarrier = struct {
    srcStageMask: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE,
    srcAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_NONE,
    dstStageMask: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE,
    dstAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_NONE,
};
pub const BufferMemoryBarrier = struct {
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
pub const ImageMemoryBarrier = struct {
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
pub const PipelineBarrier = struct {
    lastSrcStageMask: vk.VkPipelineStageFlags2 = std.math.maxInt(vk.VkPipelineStageFlags2),
    barriers: []Barrier,
};

pub const PushConstantPack = struct {
    stageFlag: vk.VkShaderStageFlags,
    size: u16,
    offset: u16,
    pValues: *anyopaque,
};

pub const Draw2D = struct {
    pipeline: VkStruct.Pipeline_t,
    rendering: rendering.RenderingInfo_t,
    vertexBuffer: []VkStruct.Buffer_t,
    indexBuffer: VkStruct.Buffer_t,
    descriptorSets: []vk.VkDescriptorSet,
    pTexture: texture.Texture_t,
    pushConstants: []PushConstantPack,
};

pub const Draw2DRecord = struct {
    offsets: []texture.Offsets,
};

pub const CopyBuffer = struct {
    srcBuffer: VkStruct.Buffer_t,
    dstBuffer: VkStruct.Buffer_t,
    regions: []vk.VkBufferCopy2,
    clean: bool = true,
};

pub const BindVertexBuffers = struct {
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

pub const ChangeBufferQueue = struct {
    buffer: VkStruct.Buffer_t,
    srcQueueFamily: VkStruct.CommandPoolType,
    dstQueueFamily: VkStruct.CommandPoolType,
    regions: []SizeOffset,
};

pub const BindPipeline = struct {
    bindPoint: vk.VkPipelineBindPoint,
    pipeline: vk.VkPipeline,
};

pub const BindIndexBuffer = struct {
    buffer: vk.VkBuffer,
    offset: vk.VkDeviceSize,
    size: vk.VkDeviceSize,
    indexType: vk.VkIndexType,
};

pub const BindDescriptorSets = struct {
    bindDescriptorSetsInfo: vk.VkBindDescriptorSetsInfo,
    // stageFlags: vk.VkShaderStageFlags,
    // layout: vk.VkPipelineLayout,
    // firstSet: u32,
    // descriptorSets: []vk.VkDescriptorSet,
    // dynamicOffsets: []u32,
};

pub const Present = struct {
    pipeline: VkStruct.Pipeline_t,
    rendering: rendering.RenderingInfo_t,
    descriptorSets: []vk.VkDescriptorSet,
    pTextures: []texture.Texture_t,
};

pub const PresentRecord = struct {
    empty: void,
};

pub const PushConstant = struct {
    layout: vk.VkPipelineLayout,
    stageFlags: vk.VkShaderStageFlags,
    offset: u32,
    size: u32,
    pValues: []u8,
};

pub const DrawMesh = struct {
    pipeline: VkStruct.Pipeline_t,
    rendering: rendering.RenderingInfo_t,
    descriptorSets: []vk.VkDescriptorSet,
    pTextures: []texture.Texture_t,
    usedBuffers: []VkStruct.Buffer_t,
    pushConstants: []PushConstantPack,
    meshletCount: u32,
};

pub const DrawMeshRecord = struct {
    meshletCount: u32,
};

pub const DrawIndirect = struct {
    pipeline: VkStruct.Pipeline_t,
    rendering: rendering.RenderingInfo_t,
    descriptorSets: []vk.VkDescriptorSet,
    pTextures: []texture.Texture_t,
    usedBuffers: []VkStruct.Buffer_t,
    indirectBuffer: VkStruct.Buffer_t,
    pushConstants: []PushConstantPack,
};

pub const DrawIndirectRecord = struct {
    buffer: vk.VkBuffer,
    offset: vk.VkDeviceSize,
};

pub const Compute = struct {
    pipeline: VkStruct.Pipeline_t,
    descriptorSets: []vk.VkDescriptorSet,
    pTextures: []texture.Texture_t,
    usedBuffers: []VkStruct.Buffer_t,
    pushConstants: PushConstantPack,
    groupCount: u32,
};

pub const ComputeRecord = struct {
    groupCount: u32,
};

// pub const Output = union {
//     image: vk.VkImage,
//     buffer: VkStruct.Buffer_t,
//     empty: void,
// };

pub const BufferUsage = enum {
    none,
    vertex,
    index,
    indirect,
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

// timestamp: i96,
ID: u32,
command: comm2,
