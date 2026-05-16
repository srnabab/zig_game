const std = @import("std");
const renderFlow = @import("renderFlow");
const vk = @import("vulkan");
const vertexStruct = @import("vertexStruct");
const Pass = @import("pass").Pass;
const VTable = @import("renderFlow").Pass.VTable;
const VkStruct = @import("video");
const Commands = @import("processRender").commands;
const TextureSet = @import("textureSet");
const cglm = @import("cglm");

const vec4 = cglm.vec4;

const indirectPushConstant = struct {
    instanceBuffer: u64,
    instanceIDs: u64,
};

fn initIndirectDraw(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;

    var values = indirectPushConstant{
        .instanceBuffer = vulkan.getBufferAddress(pass.buffer[1]),
        .instanceIDs = vulkan.getBufferAddress(pass.buffer[2]),
    };

    pass.setPushConstants(&values);

    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
        vulkan.globalFixed2dMVPMatrixDescriptorSet,
    };

    try pass.setDescriptorSets(&descriptorSets, gpa);
}

fn setIndirectDrawPushConstant(userdata: ?*anyopaque, pValues: *anyopaque) void {
    const src: *indirectPushConstant = @ptrCast(@alignCast(userdata.?));
    const dst: *indirectPushConstant = @ptrCast(@alignCast(pValues));

    dst.* = src.*;
}

fn addCommand(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    textureSet: *TextureSet,
    commands: *Commands,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;

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

    // try pass.useTexture(texture, gpa);

    try commands.addCommand(.drawIndirect, .{
        .drawIndirect = .{
            .pipeline = pass.pipeline,
            .usedBuffers = pass.buffer[1..],
            .indirectBuffer = pass.buffer[0],
            .pTextures = pass.texture,
            .descriptorSets = pass.descriptorSet,
            .pushConstants = pass.pushConstant,
        },
    });

    pass.clearTexture(gpa);
}

const vtableIndirectDraw = VTable{
    .init = initIndirectDraw,
    .addCommand = addCommand,
    .setPushConstants = setIndirectDrawPushConstant,
};

fn addIndirectDrawPass() !void {
    const buffer = try renderFlow.createBuffer(
        "indirectDrawCommand",
        @sizeOf(vk.VkDrawIndirectCommand),
        0,
        .indirect,
    );
    const buffer2 = try renderFlow.createBuffer(
        "instance2D",
        1000 * @sizeOf(vertexStruct.Instance),
        @sizeOf(vertexStruct.Instance),
        .storage,
    );
    const buffer3 = try renderFlow.createBuffer(
        "instanceID2D",
        1000 * @sizeOf(u32),
        @sizeOf(u32),
        .storage,
    );

    const pipe = try renderFlow.addPipeline("indirectDraw.pipeb", false);

    try renderFlow.createPass("indirect2D");
    try renderFlow.addPipelineToPass("indirect2D", pipe);
    try renderFlow.addBufferToPass("indirect2D", buffer);
    try renderFlow.addBufferToPass("indirect2D", buffer2);
    try renderFlow.addBufferToPass("indirect2D", buffer3);
    try renderFlow.setPushConstant("indirect2D", vk.VK_SHADER_STAGE_VERTEX_BIT, 16);

    try renderFlow.addVTableToPass("indirect2D", &vtableIndirectDraw);

    try renderFlow.appendPass("indirect2D");
}

fn initPresent(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;

    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
        vulkan.globalFixed2dMVPMatrixDescriptorSet,
    };

    try pass.setDescriptorSets(&descriptorSets, gpa);
}

fn setPresentConstant(userdata: ?*anyopaque, pValues: *anyopaque) void {
    const src: *u32 = @ptrCast(@alignCast(userdata));
    const dst: *u32 = @ptrCast(@alignCast(pValues));

    dst.* = src.*;
}

fn addPresentCommand(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    textureSet: *TextureSet,
    commands: *Commands,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;

    commands.setRendering(0, vk.VkRect2D{
        .extent = .{
            .width = vulkan.windowWidth,
            .height = vulkan.windowHeight,
        },
        .offset = .{ .x = 0, .y = 0 },
    }, 1, 0, true);

    const texture = try vulkan.getRenderTarget(
        textureSet,
        vulkan.windowWidth,
        vulkan.windowHeight,
        vk.VK_FORMAT_R8G8B8A8_SRGB,
        vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | vk.VK_IMAGE_USAGE_SAMPLED_BIT,
        vk.VK_IMAGE_TILING_OPTIMAL,
        0,
    );
    var index = textureSet.getDescriptorSetIndex(texture);
    pass.setPushConstants(&index);

    try pass.useTexture(texture, gpa);

    try commands.setRenderingColorAttachment(0, .{
        .sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
        .pNext = null,
        .imageView = null,
        .imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        .loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE,
        .clearValue = vk.VkClearValue{
            .color = vk.VkClearColorValue{
                .float32 = [_]f32{ 0.0, 0.0, 0.0, 0.0 },
            },
        },
    }, texture, true);

    try commands.addCommand(.present, .{
        .present = .{
            .pipeline = pass.pipeline,
            .pTextures = pass.texture,
            .descriptorSets = pass.descriptorSet,
            .pushConstants = pass.pushConstant,
        },
    });

    pass.clearTexture(gpa);
}

const vtablePresent = VTable{
    .init = initPresent,
    .addCommand = addPresentCommand,
    .setPushConstants = setPresentConstant,
};

fn addPresentPass() !void {
    const pipe = try renderFlow.addPipeline("directOut.pipeb", false);
    try renderFlow.createPass("present");
    try renderFlow.addPipelineToPass("present", pipe);
    try renderFlow.setPushConstant("present", vk.VK_SHADER_STAGE_VERTEX_BIT, 4);
    try renderFlow.addVTableToPass("present", &vtablePresent);

    try renderFlow.appendPass("present");
}

const IndirectComputePushConstant = extern struct {
    instanceBuffer: u64,
    indirectAddress: u64,
    instanceIDs: u64,
    viewBounds: vec4,
    totalSpriteCount: u32,
    padding: u32,
};

pub const ViewBoundsAndTotalSpriteCount = struct {
    viewBounds: vec4,
    totalSpriteCount: u32,
};

fn initIndirectCompute(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;

    const values = IndirectComputePushConstant{
        .instanceBuffer = vulkan.getBufferAddress(pass.buffer[1]),
        .indirectAddress = vulkan.getBufferAddress(pass.buffer[0]),
        .instanceIDs = vulkan.getBufferAddress(pass.buffer[2]),
        .viewBounds = .{ 0.0, 0.0, 0.0, 0.0 },
        .totalSpriteCount = 0,
        .padding = 0,
    };

    const dst: *IndirectComputePushConstant = @ptrCast(@alignCast(pass.pushConstant.pValues));
    dst.* = values;

    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
    };

    try pass.setDescriptorSets(&descriptorSets, gpa);
}

fn setIndirectComputePushConstant(userdata: ?*anyopaque, pValues: *anyopaque) void {
    const src: *ViewBoundsAndTotalSpriteCount = @ptrCast(@alignCast(userdata.?));
    const dst: *IndirectComputePushConstant = @ptrCast(@alignCast(pValues));

    dst.viewBounds = src.viewBounds;
    dst.totalSpriteCount = src.totalSpriteCount;
}

fn addIndirectComputeCommand(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    textureSet: *TextureSet,
    commands: *Commands,
    gpa: std.mem.Allocator,
) !void {
    _ = textureSet;
    _ = gpa;

    pass.setPushConstants(userdata);

    const src: *ViewBoundsAndTotalSpriteCount = @ptrCast(@alignCast(userdata.?));

    const groupCount = (src.totalSpriteCount + 31) / 32;

    try commands.addCommand(.fillBuffer, .{ .fillBuffer = .{
        .buffer = pass.buffer[0],
        .offset = 4,
        .size = 4,
        .value = 0,
    } });

    try commands.addCommand(.compute, .{ .compute = .{
        .descriptorSets = pass.descriptorSet,
        .pipeline = pass.pipeline,
        .pTextures = pass.texture,
        .usedBuffers = pass.buffer,
        .pushConstants = pass.pushConstant,
        .groupCount = groupCount,
    } });

    vulkan.buffers.writeBuffer(pass.buffer[0]);
    vulkan.buffers.writeBuffer(pass.buffer[2]);
}

const vtableIndirectCompute = VTable{
    .init = initIndirectCompute,
    .addCommand = addIndirectComputeCommand,
    .setPushConstants = setIndirectComputePushConstant,
};

fn addIndirectComputePass() !void {
    const passName = "indirectCompute";

    const buffer = try renderFlow.createBuffer(
        "indirectDrawCommand",
        @sizeOf(vk.VkDrawIndirectCommand),
        0,
        .indirect,
    );
    const buffer2 = try renderFlow.createBuffer(
        "instance2D",
        1000 * @sizeOf(vertexStruct.Instance),
        @sizeOf(vertexStruct.Instance),
        .storage,
    );
    const buffer3 = try renderFlow.createBuffer(
        "instanceID2D",
        1000 * @sizeOf(u32),
        @sizeOf(u32),
        .storage,
    );

    const pipe = try renderFlow.addPipeline("indirectDrawCompute.pipeb", false);

    try renderFlow.createPass(passName);

    try renderFlow.addBufferToPass(passName, buffer);
    try renderFlow.addBufferToPass(passName, buffer2);
    try renderFlow.addBufferToPass(passName, buffer3);
    try renderFlow.addPipelineToPass(passName, pipe);
    try renderFlow.setPushConstant(passName, vk.VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT, 48);

    try renderFlow.addVTableToPass(passName, &vtableIndirectCompute);

    try renderFlow.appendPass(passName);
}

pub fn setting() !void {
    try addIndirectComputePass();
    try addIndirectDrawPass();
    try addPresentPass();
}
