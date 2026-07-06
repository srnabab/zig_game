const std = @import("std");
const math = @import("math");

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
        false,
        null,
    );
    const buffer2 = try renderFlow.createBuffer(
        "instance2D",
        1000 * @sizeOf(vertexStruct.Instance),
        @sizeOf(vertexStruct.Instance),
        .storage,
        false,
        null,
    );
    const buffer3 = try renderFlow.createBuffer(
        "instanceID2D",
        1000 * @sizeOf(u32),
        @sizeOf(u32),
        .storage,
        false,
        null,
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
        false,
        null,
    );
    const buffer2 = try renderFlow.createBuffer(
        "instance2D",
        1000 * @sizeOf(vertexStruct.Instance),
        @sizeOf(vertexStruct.Instance),
        .storage,
        false,
        null,
    );
    const buffer3 = try renderFlow.createBuffer(
        "instanceID2D",
        1000 * @sizeOf(u32),
        @sizeOf(u32),
        .storage,
        false,
        null,
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

const Im_FeatherPushConstant = struct {
    meshlet: u64,
    vertices: u64,
    meshletVertices: u64,
    meshletTriangles: u64,
    commands: u64,
    mappings: u64,
    instances: u64,
    meshes: u64,
};

fn initIm_Feather(userdata: ?*anyopaque, pass: *Pass, vulkan: *VkStruct, gpa: std.mem.Allocator) !void {
    _ = userdata;

    const storageBufferAddress = vulkan.getBufferAddress(pass.buffer[1]);

    const meshlet = storageBufferAddress;

    var bufferContent = vulkan.buffers.getBufferContent(pass.buffer[2]);
    const vertices = storageBufferAddress + bufferContent.size;

    bufferContent = vulkan.buffers.getBufferContent(pass.buffer[3]);
    const meshletVertices = vertices + bufferContent.size;

    bufferContent = vulkan.buffers.getBufferContent(pass.buffer[4]);
    const meshletTriangles = meshletVertices + bufferContent.size;

    const commands = vulkan.getBufferAddress(pass.buffer[0]);
    const mappings = vulkan.getBufferAddress(pass.buffer[5]);
    const instances = vulkan.getBufferAddress(pass.buffer[6]);
    const meshes = vulkan.getBufferAddress(pass.buffer[7]);

    pass.setPushConstants(&Im_FeatherPushConstant{
        .meshlet = meshlet,
        .vertices = vertices,
        .meshletVertices = meshletVertices,
        .meshletTriangles = meshletTriangles,
        .commands = commands,
        .mappings = mappings,
        .instances = instances,
        .meshes = meshes,
    });

    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
        vulkan.global3dMVPMatrixDescriptorSet,
    };

    try pass.setDescriptorSets(&descriptorSets, gpa);
}

fn setIm_FeatherPushConstant(userdata: ?*anyopaque, pValues: *anyopaque) void {
    const src: *Im_FeatherPushConstant = @ptrCast(@alignCast(userdata.?));
    const dst: *Im_FeatherPushConstant = @ptrCast(@alignCast(pValues));

    dst.* = src.*;
}

fn addIm_FeatherCommand(
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

    commands.addCommand(.drawMeshIndirect, .{ .drawMeshIndirect = .{
        .descriptorSets = pass.descriptorSet,
        .pipeline = pass.pipeline,
        .usedBuffers = pass.buffer[0..2],
        .pushConstants = pass.pushConstant,
        .indirectBuffer = pass.buffer[0],
        .pTextures = pass.texture,
    } });

    pass.clearTexture(gpa);
}

const vtableIm_Feather = VTable{
    .init = initIm_Feather,
    .addCommand = addIm_FeatherCommand,
    .setPushConstants = setIm_FeatherPushConstant,
};

fn addIm_FeatherPass() !void {
    const buffer = try renderFlow.createBuffer(
        "im_FeatherCommand",
        @sizeOf(vertexStruct.CustomDrawMeshTasksIndirectCommand) * 2,
        0,
        .indirect,
        false,
        null,
    );
    const meshletSize = math.round(16, @sizeOf(vertexStruct.Meshlet) * 100);
    const verticesSize = math.round(16, @sizeOf(vertexStruct.Vertex_f3pf3nf3tf2u) * 2000);
    const meshletVerticesSize = math.round(16, @sizeOf(u32) * 1000);
    const mehsletTrianglesSize = math.round(16, @sizeOf(u8) * 1000);
    // const metadataSize = math.round(16, @sizeOf(vertexStruct.MetaData) * 10);

    const totalSize = verticesSize + meshletSize + meshletVerticesSize + mehsletTrianglesSize;

    const buffer2 = try renderFlow.createBuffer(
        "featherStorageBuffer",
        totalSize,
        0,
        .storage,
        false,
        null,
    );

    const buffer3 = try renderFlow.createBuffer(
        "featherMeshlet",
        meshletSize,
        @sizeOf(vertexStruct.Meshlet),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer4 = try renderFlow.createBuffer(
        "featherVertices",
        verticesSize,
        @sizeOf(vertexStruct.Vertex_f3pf3nf3tf2u),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer5 = try renderFlow.createBuffer(
        "featherMeshletVertices",
        meshletVerticesSize,
        @sizeOf(u32),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer6 = try renderFlow.createBuffer(
        "featherMeshletTriangles",
        mehsletTrianglesSize,
        @sizeOf(u8),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer7 = try renderFlow.createBuffer(
        "groupMappings",
        @sizeOf(vertexStruct.GroupMapping) * 4,
        @sizeOf(vertexStruct.GroupMapping),
        .storage,
        false,
        null,
    );

    const buffer8 = try renderFlow.createBuffer(
        "instance3D",
        @sizeOf(vertexStruct.Instance3D) * 4,
        @sizeOf(vertexStruct.Instance3D),
        .storage,
        false,
        null,
    );

    const buffer9 = try renderFlow.createBuffer(
        "meshes",
        @sizeOf(vertexStruct.Mesh) * 40,
        @sizeOf(vertexStruct.Mesh),
        .storage,
        false,
        null,
    );

    const pipe = try renderFlow.addPipeline("im_feather.pipeb", true);

    try renderFlow.createPass("im_feather");
    try renderFlow.addPipelineToPass("im_feather", pipe);
    try renderFlow.addBufferToPass("im_feather", buffer);
    try renderFlow.addBufferToPass("im_feather", buffer2);
    try renderFlow.addBufferToPass("im_feather", buffer3);
    try renderFlow.addBufferToPass("im_feather", buffer4);
    try renderFlow.addBufferToPass("im_feather", buffer5);
    try renderFlow.addBufferToPass("im_feather", buffer6);
    try renderFlow.addBufferToPass("im_feather", buffer7);
    try renderFlow.addBufferToPass("im_feather", buffer8);
    try renderFlow.addBufferToPass("im_feather", buffer9);

    try renderFlow.setPushConstant(
        "im_feather",
        vk.VK_SHADER_STAGE_TASK_BIT_EXT | vk.VK_SHADER_STAGE_MESH_BIT_EXT,
        64,
    );

    try renderFlow.addVTableToPass("im_feather", &vtableIndirectDraw);

    try renderFlow.appendPass("im_feather");
}

pub fn setting() !void {
    try addIndirectComputePass();
    try addIndirectDrawPass();
    try addIm_FeatherPass();
    try addPresentPass();
}
