const std = @import("std");
const Allocator = std.mem.Allocator;

const cglm = @import("cglm");
const vec4 = cglm.vec4;

const setPass = @import("../setPass.zig");

const vertexStruct = @import("vertexStruct");
const Pass = @import("pass").Pass;
const VTable = @import("renderFlow").Pass.VTable;
const VkStruct = @import("video");
const Commands = @import("processRender").commands;
const ExternalCommands = @import("processRender").externalCommands;
const TextureSet = @import("textureSet");
const renderFlow = @import("renderFlow");
const vk = @import("vulkan");

const u8pack = @import("u8pack");

const indirectPushConstant = extern struct {
    instanceBuffer: u64,
    instanceIDs: u64,
};

const IndirectComputePushConstant = extern struct {
    instanceBuffer: u64,
    indirectAddress: u64,
    instanceIDs: u64,
    viewBounds: vec4,
    totalSpriteCount: u32,
    padding: u32,
};

fn initIndirect2D(
    userdata: *?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    commands: *ExternalCommands,
    gpa: std.mem.Allocator,
) !void {
    _ = commands;

    const viewBoundsAndTotalSpriteCount = try gpa.create(setPass.ViewBoundsAndTotalSpriteCount);
    viewBoundsAndTotalSpriteCount.* = .{
        .viewBounds = .{ 0.0, 0.0, 0.0, 0.0 },
        .totalSpriteCount = 0,
    };
    userdata.* = viewBoundsAndTotalSpriteCount;

    // compute push (pipeline/pushConstant index 0, 48B)
    const values = IndirectComputePushConstant{
        .instanceBuffer = vulkan.getBufferAddress(pass.buffer[1]),
        .indirectAddress = vulkan.getBufferAddress(pass.buffer[0]),
        .instanceIDs = vulkan.getBufferAddress(pass.buffer[2]),
        .viewBounds = .{ 0.0, 0.0, 0.0, 0.0 },
        .totalSpriteCount = 0,
        .padding = 0,
    };
    const dst: *IndirectComputePushConstant = @ptrCast(@alignCast(pass.pushConstant[0].pValues));
    dst.* = values;

    // draw push (index 1, 16B)
    var valuesDraw = indirectPushConstant{
        .instanceBuffer = vulkan.getBufferAddress(pass.buffer[1]),
        .instanceIDs = vulkan.getBufferAddress(pass.buffer[2]),
    };
    pass.setPushConstants(1, @ptrCast(@alignCast(&valuesDraw)), 0);

    // 描述符超集: slot0 纹理, slot1 2d mvp(compute 命令只取 [0..1])
    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
        vulkan.globalFixed2dMVPMatrixDescriptorSet,
    };
    try pass.setDescriptorSets(&descriptorSets, gpa);
}

fn addIndirect2DCommand(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    textureSet: *TextureSet,
    commands: *Commands,
    gpa: std.mem.Allocator,
) !void {
    const src: *setPass.ViewBoundsAndTotalSpriteCount = @ptrCast(@alignCast(userdata.?));
    src.viewBounds = .{ -300, 300, -400, 400 };

    pass.setPushConstants(0, @ptrCast(@alignCast(src)), 24);

    const groupCount = (src.totalSpriteCount + 31) / 32;

    try commands.addCommand(.fillBuffer, .{ .fillBuffer = .{
        .buffer = pass.buffer[0],
        .offset = 4,
        .size = 4,
        .value = 0,
    } });

    try commands.addCommand(.compute, .{ .compute = .{
        .descriptorSets = pass.descriptorSet[0..1],
        .pipeline = pass.pipeline[0],
        .pTextures = &.{},
        .usedBuffers = pass.buffer,
        .pushConstants = pass.pushConstant[0],
        .groupCount = groupCount,
    } });

    vulkan.buffers.writeBuffer(pass.buffer[0]);
    vulkan.buffers.writeBuffer(pass.buffer[2]);

    commands.setRendering(0, vk.VkRect2D{
        .extent = .{
            .width = vulkan.windowWidth,
            .height = vulkan.windowHeight,
        },
        .offset = .{ .x = 0, .y = 0 },
    }, 1, 0, false);

    const texture = try vulkan.getRenderTarget(
        textureSet,
        vulkan.windowWidth,
        vulkan.windowHeight,
        vk.VK_FORMAT_R8G8B8A8_SRGB,
        vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | vk.VK_IMAGE_USAGE_SAMPLED_BIT,
        vk.VK_IMAGE_TILING_OPTIMAL,
        0,
    );
    const depth = try vulkan.getRenderTarget(
        textureSet,
        vulkan.windowWidth,
        vulkan.windowHeight,
        vk.VK_FORMAT_D32_SFLOAT,
        vk.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT,
        vk.VK_IMAGE_TILING_OPTIMAL,
        0,
    );

    try commands.setRenderingColorAttachment(0, .{
        .sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
        .pNext = null,
        .imageView = textureSet.getVkImageView(texture).?,
        .imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        .loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE,
        .clearValue = vk.VkClearValue{
            .color = vk.VkClearColorValue{
                .float32 = [_]f32{ 0.0, 0.0, 0.0, 0.0 },
            },
        },
    }, texture, false);

    commands.setRenderingDepthOrStencilAttachment(.{
        .sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
        .pNext = null,
        .imageView = textureSet.getVkImageView(depth).?,
        .imageLayout = vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL,
        .loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = vk.VK_ATTACHMENT_STORE_OP_DONT_CARE,
        .clearValue = vk.VkClearValue{
            .depthStencil = .{ .depth = 1.0 },
        },
    }, depth, true, false);

    try commands.addCommand(.drawIndirect, .{
        .drawIndirect = .{
            .pipeline = pass.pipeline[1],
            .usedBuffers = pass.buffer[1..],
            .indirectBuffer = pass.buffer[0],
            .pTextures = pass.texture,
            .descriptorSets = pass.descriptorSet,
            .pushConstants = pass.pushConstant[1],
        },
    });

    pass.clearTexture(gpa);
}

const vtableIndirect2D = VTable{
    .init = initIndirect2D,
    .addCommand = addIndirect2DCommand,
};

pub fn addIndirect2DPass(comptime ctx: ?*u8pack.CTX) !void {
    const passName = "indirect2D";

    const buffer = try renderFlow.createBuffer(
        ctx,
        "indirectDrawCommand",
        @sizeOf(vk.VkDrawIndirectCommand),
        @sizeOf(vk.VkDrawIndirectCommand),
        .indirect,
        false,
        null,
    );
    const buffer2 = try renderFlow.createBuffer(
        ctx,
        "instance2D",
        1000 * @sizeOf(vertexStruct.Instance),
        @sizeOf(vertexStruct.Instance),
        .storage,
        false,
        null,
    );
    const buffer3 = try renderFlow.createBuffer(
        ctx,
        "instanceID2D",
        1000 * @sizeOf(u32),
        @sizeOf(u32),
        .storage,
        false,
        null,
    );

    const pipeCompute = try renderFlow.addPipeline(ctx, "indirectDrawCompute.pipeb", false);
    const pipeDraw = try renderFlow.addPipeline(ctx, "indirectDraw.pipeb", false);

    try renderFlow.createPass(ctx, passName);
    try renderFlow.addPipelineToPass(ctx, passName, pipeCompute);
    try renderFlow.addPipelineToPass(ctx, passName, pipeDraw);
    try renderFlow.addBufferToPass(ctx, passName, buffer);
    try renderFlow.addBufferToPass(ctx, passName, buffer2);
    try renderFlow.addBufferToPass(ctx, passName, buffer3);

    try renderFlow.setPushConstant(ctx, passName, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 48);
    try renderFlow.setPushConstant(ctx, passName, vk.VK_SHADER_STAGE_VERTEX_BIT, 16);

    try renderFlow.addVTableToPass(ctx, passName, &vtableIndirect2D);

    try renderFlow.appendPass(ctx, passName);
}
