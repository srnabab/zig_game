const std = @import("std");
const mstd = @import("ms_std");

const math = mstd.Math;

const renderFlow = @import("renderFlow");
const vk = @import("vulkan");
const vertexStruct = @import("vertexStruct");
const Pass = @import("pass").Pass;
const VTable = @import("renderFlow").Pass.VTable;
const VkStruct = @import("video");
const Commands = @import("processRender").commands;
const ExternalCommands = @import("processRender").externalCommands;
const TextureSet = @import("textureSet");
const cglm = @import("cglm");
const renderDebug = @import("renderDebug");

const vec4 = cglm.vec4;

const indirectPushConstant = extern struct {
    instanceBuffer: u64,
    instanceIDs: u64,
};

fn initIndirectDraw(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    commands: *ExternalCommands,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;
    _ = commands;

    var values = indirectPushConstant{
        .instanceBuffer = vulkan.getBufferAddress(pass.buffer[1]),
        .instanceIDs = vulkan.getBufferAddress(pass.buffer[2]),
    };

    pass.setPushConstants(0, @ptrCast(@alignCast(&values)), 0);

    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
        vulkan.globalFixed2dMVPMatrixDescriptorSet,
    };

    try pass.setDescriptorSets(&descriptorSets, gpa);
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
            .pipeline = pass.pipeline[0],
            .usedBuffers = pass.buffer[1..],
            .indirectBuffer = pass.buffer[0],
            .pTextures = pass.texture,
            .descriptorSets = pass.descriptorSet,
            .pushConstants = pass.pushConstant[0],
        },
    });

    pass.clearTexture(gpa);
}

const vtableIndirectDraw = VTable{
    .init = initIndirectDraw,
    .addCommand = addCommand,
};

fn addIndirectDrawPass() !void {
    const buffer = try renderFlow.createBuffer(
        "indirectDrawCommand",
        @sizeOf(vk.VkDrawIndirectCommand),
        @sizeOf(vk.VkDrawIndirectCommand),
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
    commands: *ExternalCommands,
    gpa: std.mem.Allocator,
) !void {
    _ = commands;
    _ = userdata;

    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
        vulkan.globalFixed2dMVPMatrixDescriptorSet,
    };

    try pass.setDescriptorSets(&descriptorSets, gpa);
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
    try pass.useTexture(texture, gpa);

    var index = textureSet.getDescriptorSetIndex(texture);
    pass.setPushConstants(0, @ptrCast(@alignCast(&index)), 0);

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
    }, undefined, true);

    // renderDebug.printToDot();

    try commands.addCommand(.present, .{
        .present = .{
            .pipeline = pass.pipeline[0],
            .pTextures = pass.texture,
            .descriptorSets = pass.descriptorSet,
            .pushConstants = pass.pushConstant[0],
        },
    });

    pass.clearTexture(gpa);
}

const vtablePresent = VTable{
    .init = initPresent,
    .addCommand = addPresentCommand,
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

pub const ViewBoundsAndTotalSpriteCount = extern struct {
    viewBounds: vec4,
    totalSpriteCount: u32,
};

fn initIndirectCompute(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    commands: *ExternalCommands,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;
    _ = commands;

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

    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
    };

    try pass.setDescriptorSets(&descriptorSets, gpa);
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

    const src: *ViewBoundsAndTotalSpriteCount = @ptrCast(@alignCast(userdata.?));
    pass.setPushConstants(0, @ptrCast(@alignCast(src)), 24);

    const groupCount = (src.totalSpriteCount + 31) / 32;

    try commands.addCommand(.fillBuffer, .{ .fillBuffer = .{
        .buffer = pass.buffer[0],
        .offset = 4,
        .size = 4,
        .value = 0,
    } });

    try commands.addCommand(.compute, .{ .compute = .{
        .descriptorSets = pass.descriptorSet,
        .pipeline = pass.pipeline[0],
        .pTextures = pass.texture,
        .usedBuffers = pass.buffer,
        .pushConstants = pass.pushConstant[0],
        .groupCount = groupCount,
    } });

    vulkan.buffers.writeBuffer(pass.buffer[0]);
    vulkan.buffers.writeBuffer(pass.buffer[2]);
}

const vtableIndirectCompute = VTable{
    .init = initIndirectCompute,
    .addCommand = addIndirectComputeCommand,
};

fn addIndirectComputePass() !void {
    const passName = "indirectCompute";

    const buffer = try renderFlow.createBuffer(
        "indirectDrawCommand",
        @sizeOf(vk.VkDrawIndirectCommand),
        @sizeOf(vk.VkDrawIndirectCommand),
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

const Im_FeatherPushConstant = extern struct {
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
    const mappings = vulkan.getBufferAddress(pass.buffer[6]);
    const instances = vulkan.getBufferAddress(pass.buffer[7]);
    const meshes = vulkan.getBufferAddress(pass.buffer[8]);

    var push = Im_FeatherPushConstant{
        .meshlet = meshlet,
        .vertices = vertices,
        .meshletVertices = meshletVertices,
        .meshletTriangles = meshletTriangles,
        .commands = commands,
        .mappings = mappings,
        .instances = instances,
        .meshes = meshes,
    };
    pass.setPushConstants(0, @ptrCast(@alignCast(&push)), 0);

    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
        vulkan.global3dMVPMatrixDescriptorSet,
    };

    try pass.setDescriptorSets(&descriptorSets, gpa);
}

fn addIm_FeatherCommand(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    textureSet: *TextureSet,
    commands: *Commands,
    gpa: std.mem.Allocator,
) !void {
    _ = vulkan;
    _ = textureSet;

    const drawCount = @as(*u32, @ptrCast(@alignCast(userdata.?))).*;

    try commands.addCommand(.drawMeshIndirect, .{ .drawMeshIndirect = .{
        .descriptorSets = pass.descriptorSet,
        .pipeline = pass.pipeline[0],
        .usedBuffers = pass.buffer,
        .pushConstants = pass.pushConstant[0],
        .indirectBuffer = pass.buffer[0],
        .pTextures = pass.texture,
        .drawCount = drawCount,
    } });
    // std.log.debug("addIm_FeatherCommand", .{});

    pass.clearTexture(gpa);
}

const vtableIm_Feather = VTable{
    .init = initIm_Feather,
    .addCommand = addIm_FeatherCommand,
};

fn addIm_FeatherPass() !void {
    const passName = "im_feather";

    const buffer = try renderFlow.createBuffer(
        "im_FeatherCommand",
        @sizeOf(vertexStruct.CustomDrawMeshTasksIndirectCommand) * 2,
        0,
        .indirect,
        false,
        null,
    );
    const meshletSize = math.round(16, @sizeOf(vertexStruct.Meshlet) * 100);
    const verticesSize = math.round(16, @sizeOf(vertexStruct.Vertex_f3pf3nf4tf2u) * 4000);
    const meshletVerticesSize = math.round(16, @sizeOf(u32) * 4000);
    const mehsletTrianglesSize = math.round(16, @sizeOf(u8) * 4000);
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
        @sizeOf(vertexStruct.Vertex_f3pf3nf4tf2u),
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

    try renderFlow.createPass(passName);
    try renderFlow.addPipelineToPass(passName, pipe);
    try renderFlow.addBufferToPass(passName, buffer);
    try renderFlow.addBufferToPass(passName, buffer2);
    try renderFlow.addBufferToPass(passName, buffer3);
    try renderFlow.addBufferToPass(passName, buffer4);
    try renderFlow.addBufferToPass(passName, buffer5);
    try renderFlow.addBufferToPass(passName, buffer6);
    try renderFlow.addBufferToPass(passName, buffer7);
    try renderFlow.addBufferToPass(passName, buffer8);
    try renderFlow.addBufferToPass(passName, buffer9);

    try renderFlow.setPushConstant(
        passName,
        vk.VK_SHADER_STAGE_TASK_BIT_EXT | vk.VK_SHADER_STAGE_MESH_BIT_EXT,
        64,
    );

    try renderFlow.addVTableToPass(passName, &vtableIm_Feather);

    try renderFlow.appendPass(passName);
}

const twoU64 = extern struct {
    a: u64,
    b: u64,
};

const ic_Task_PushConstant = extern struct {
    commands: u64,
    mappings: u64,
    instances: u64,
    meshes: u64,
    payloads: u64,
    iCommands: u64,
    drawCount: u32,
};

const Iv_feather_PushConstant = extern struct {
    meshlet: u64,
    vertices: u64,
    meshletVertices: u64,
    meshletTriangles: u64,
    instances: u64,
    meshes: u64,
    payloads: u64,
    params: u64,

    paramTextureIndex: u32,
};

const IF = struct {
    // merged "i_feather" pass buffer indices
    const drawCommands: usize = 0; // indirectVertex_MeshDrawCommand
    const meshStorage: usize = 1; // featherStorageBuffer
    const meshlet: usize = 2; // featherMeshlet
    const vertices: usize = 3; // featherVertices
    const meshletVertices: usize = 4; // featherMeshletVertices
    const meshletTriangles: usize = 5; // featherMeshletTriangles
    const featherCommands: usize = 6; // iv_FeatherCommand
    const dispatchCommands: usize = 7; // indirectComputeCommand
    const groupMappings: usize = 8;
    const instance3D: usize = 9;
    const meshes: usize = 10;
    const payloads: usize = 11; // computeTaskPayload
    const params: usize = 12; // featherParameters
};

fn initI_Feather(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    commands: *ExternalCommands,
    gpa: std.mem.Allocator,
) !void {
    _ = userdata;

    // c_command_prefix_sum push (pipeline/pushConstant index 0)
    var pushC = twoU64{
        .a = vulkan.getBufferAddress(pass.buffer[IF.featherCommands]),
        .b = vulkan.getBufferAddress(pass.buffer[IF.dispatchCommands]),
    };
    pass.setPushConstants(0, @ptrCast(@alignCast(&pushC)), 0);

    // ic_task push (index 1)
    const pushIc = ic_Task_PushConstant{
        .commands = vulkan.getBufferAddress(pass.buffer[IF.featherCommands]),
        .mappings = vulkan.getBufferAddress(pass.buffer[IF.groupMappings]),
        .instances = vulkan.getBufferAddress(pass.buffer[IF.instance3D]),
        .meshes = vulkan.getBufferAddress(pass.buffer[IF.meshes]),
        .payloads = vulkan.getBufferAddress(pass.buffer[IF.payloads]),
        .iCommands = vulkan.getBufferAddress(pass.buffer[IF.drawCommands]),
        .drawCount = 0,
    };
    const dstIc: *ic_Task_PushConstant = @ptrCast(@alignCast(pass.pushConstant[1].pValues));
    dstIc.* = pushIc;

    // iv_feather push (index 2)
    const storageBufferAddress = vulkan.getBufferAddress(pass.buffer[IF.meshStorage]);
    var bufferContent = vulkan.buffers.getBufferContent(pass.buffer[IF.meshlet]);
    const verticesAddress = storageBufferAddress + bufferContent.size;
    bufferContent = vulkan.buffers.getBufferContent(pass.buffer[IF.vertices]);
    const meshletVerticesAddress = verticesAddress + bufferContent.size;
    bufferContent = vulkan.buffers.getBufferContent(pass.buffer[IF.meshletVertices]);
    const meshletTrianglesAddress = meshletVerticesAddress + bufferContent.size;

    const pushIv = Iv_feather_PushConstant{
        .meshlet = storageBufferAddress,
        .vertices = verticesAddress,
        .meshletVertices = meshletVerticesAddress,
        .meshletTriangles = meshletTrianglesAddress,
        .instances = vulkan.getBufferAddress(pass.buffer[IF.instance3D]),
        .meshes = vulkan.getBufferAddress(pass.buffer[IF.meshes]),
        .payloads = vulkan.getBufferAddress(pass.buffer[IF.payloads]),
        .params = vulkan.getBufferAddress(pass.buffer[IF.params]),
        .paramTextureIndex = 0,
    };
    const dstIv: *Iv_feather_PushConstant = @ptrCast(@alignCast(pass.pushConstant[2].pValues));
    dstIv.* = pushIv;

    // 描述符超集: slot0 纹理, slot1 3d mvp(C/IC 计算命令只取 [0..1])
    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
        vulkan.global3dMVPMatrixDescriptorSet,
    };
    try pass.setDescriptorSets(&descriptorSets, gpa);

    // C 缓存: 预置 dispatch 头 12B = 1
    try commands.externalCommand(.{ .fillBuffer = .{
        .buffer = pass.buffer[IF.dispatchCommands],
        .offset = 0,
        .size = 12,
        .value = 1,
    } });
    // IV 缓存: 预置 draw 命令顶点数 = 1(空首条占位)
    try commands.externalCommand(.{ .fillBuffer = .{
        .buffer = pass.buffer[IF.drawCommands],
        .offset = 4,
        .size = 4,
        .value = 1,
    } });
}

fn addI_FeatherCommand(
    userdata: ?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    textureSet: *TextureSet,
    commands: *Commands,
    gpa: std.mem.Allocator,
) !void {
    _ = textureSet;

    const groupCount = @as(*u32, @ptrCast(@alignCast(userdata.?))).*;

    // ---- c_command_prefix_sum: 清零 dispatch + 前缀和 compute ----
    try commands.addCommand(.fillBuffer, .{ .fillBuffer = .{
        .buffer = pass.buffer[IF.dispatchCommands],
        .offset = 0,
        .size = 4,
        .value = 0,
    } });

    try commands.addCommand(.compute, .{ .compute = .{
        .pipeline = pass.pipeline[0],
        .descriptorSets = pass.descriptorSet[0..1],
        .pTextures = pass.texture,
        .usedBuffers = pass.buffer[IF.featherCommands .. IF.dispatchCommands + 1],
        .pushConstants = pass.pushConstant[0],
        .groupCount = groupCount,
    } });

    vulkan.buffers.writeBuffer(pass.buffer[IF.featherCommands]);
    vulkan.buffers.writeBuffer(pass.buffer[IF.dispatchCommands]);

    // ---- ic_task: 清零 draw 命令 + computeIndirect ----
    pass.setPushConstants(1, @as([*]u8, @ptrCast(@alignCast(userdata)))[0..@sizeOf(u32)], 48);

    try commands.addCommand(.fillBuffer, .{ .fillBuffer = .{
        .buffer = pass.buffer[IF.drawCommands],
        .offset = 0,
        .size = 4,
        .value = 0,
    } });

    try commands.addCommand(.computeIndirect, .{ .computeIndirect = .{
        .pipeline = pass.pipeline[1],
        .descriptorSets = pass.descriptorSet[0..1],
        .pTextures = pass.texture,
        .usedBuffers = pass.buffer,
        .pushConstants = pass.pushConstant[1],
        .indirectBuffer = pass.buffer[IF.dispatchCommands],
    } });

    vulkan.buffers.writeBuffer(pass.buffer[IF.payloads]);
    vulkan.buffers.writeBuffer(pass.buffer[IF.drawCommands]);

    // ---- iv_feather: drawIndirect ----
    try commands.addCommand(.drawIndirect, .{ .drawIndirect = .{
        .descriptorSets = pass.descriptorSet,
        .pipeline = pass.pipeline[2],
        .usedBuffers = pass.buffer,
        .pushConstants = pass.pushConstant[2],
        .indirectBuffer = pass.buffer[IF.drawCommands],
        .pTextures = pass.texture,
    } });

    pass.clearTexture(gpa);
}

const vtableI_Feather = VTable{
    .init = initI_Feather,
    .addCommand = addI_FeatherCommand,
};

fn addI_FeatherPass() !void {
    const passName = "i_feather";

    const buffer0 = try renderFlow.createBuffer(
        "indirectVertex_MeshDrawCommand",
        @sizeOf(vk.VkDrawIndirectCommand),
        @sizeOf(vk.VkDrawIndirectCommand),
        .indirect,
        false,
        null,
    );

    const meshletSize = math.round(16, @sizeOf(vertexStruct.Meshlet) * 100);
    const verticesSize = math.round(16, @sizeOf(vertexStruct.Vertex_f3pf3nf4tf2u) * 4000);
    const meshletVerticesSize = math.round(16, @sizeOf(u32) * 4000);
    const mehsletTrianglesSize = math.round(16, @sizeOf(u8) * 4000);
    // const metadataSize = math.round(16, @sizeOf(vertexStruct.MetaData) * 10);

    const totalSize = verticesSize + meshletSize + meshletVerticesSize + mehsletTrianglesSize;

    const buffer1 = try renderFlow.createBuffer(
        "featherStorageBuffer",
        totalSize,
        0,
        .storage,
        false,
        null,
    );

    const buffer2 = try renderFlow.createBuffer(
        "featherMeshlet",
        meshletSize,
        @sizeOf(vertexStruct.Meshlet),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer3 = try renderFlow.createBuffer(
        "featherVertices",
        verticesSize,
        @sizeOf(vertexStruct.Vertex_f3pf3nf4tf2u),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer4 = try renderFlow.createBuffer(
        "featherMeshletVertices",
        meshletVerticesSize,
        @sizeOf(u32),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer5 = try renderFlow.createBuffer(
        "featherMeshletTriangles",
        mehsletTrianglesSize,
        @sizeOf(u8),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer6 = try renderFlow.createBuffer(
        "iv_FeatherCommand",
        @sizeOf(vertexStruct.CustomDrawMeshTasksIndirectCommand) * 2,
        0,
        .storage,
        false,
        null,
    );

    const buffer7 = try renderFlow.createBuffer(
        "indirectComputeCommand",
        @sizeOf(vk.VkDispatchIndirectCommand),
        0,
        .indirect,
        false,
        null,
    );

    const buffer8 = try renderFlow.createBuffer(
        "groupMappings",
        @sizeOf(vertexStruct.GroupMapping) * 4,
        @sizeOf(vertexStruct.GroupMapping),
        .storage,
        false,
        null,
    );

    const buffer9 = try renderFlow.createBuffer(
        "instance3D",
        @sizeOf(vertexStruct.Instance3D) * 4,
        @sizeOf(vertexStruct.Instance3D),
        .storage,
        false,
        null,
    );

    const buffer10 = try renderFlow.createBuffer(
        "meshes",
        @sizeOf(vertexStruct.Mesh) * 40,
        @sizeOf(vertexStruct.Mesh),
        .storage,
        false,
        null,
    );

    const buffer11 = try renderFlow.createBuffer(
        "computeTaskPayload",
        @sizeOf(vertexStruct.ComputeTaskPayload) * 400,
        @sizeOf(vertexStruct.ComputeTaskPayload),
        .storage,
        false,
        null,
    );

    const buffer12 = try renderFlow.createBuffer(
        "featherParameters",
        20000 * 192 * @sizeOf(f32),
        @sizeOf(f32),
        .storageRead,
        false,
        null,
    );

    const pipeC = try renderFlow.addPipeline("c_commandPrefixSum.pipeb", false);
    const pipeIc = try renderFlow.addPipeline("ic_task.pipeb", false);
    const pipeIv = try renderFlow.addPipeline("iv_feather.pipeb", false);

    try renderFlow.createPass(passName);
    try renderFlow.addPipelineToPass(passName, pipeC);
    try renderFlow.addPipelineToPass(passName, pipeIc);
    try renderFlow.addPipelineToPass(passName, pipeIv);
    try renderFlow.addBufferToPass(passName, buffer0);
    try renderFlow.addBufferToPass(passName, buffer1);
    try renderFlow.addBufferToPass(passName, buffer2);
    try renderFlow.addBufferToPass(passName, buffer3);
    try renderFlow.addBufferToPass(passName, buffer4);
    try renderFlow.addBufferToPass(passName, buffer5);
    try renderFlow.addBufferToPass(passName, buffer6);
    try renderFlow.addBufferToPass(passName, buffer7);
    try renderFlow.addBufferToPass(passName, buffer8);
    try renderFlow.addBufferToPass(passName, buffer9);
    try renderFlow.addBufferToPass(passName, buffer10);
    try renderFlow.addBufferToPass(passName, buffer11);
    try renderFlow.addBufferToPass(passName, buffer12);

    try renderFlow.setPushConstant(passName, vk.VK_SHADER_STAGE_COMPUTE_BIT, 16);
    try renderFlow.setPushConstant(passName, vk.VK_SHADER_STAGE_COMPUTE_BIT, 52);
    try renderFlow.setPushConstant(passName, vk.VK_SHADER_STAGE_VERTEX_BIT, @sizeOf(Iv_feather_PushConstant));

    try renderFlow.addVTableToPass(passName, &vtableI_Feather);

    try renderFlow.appendPass(passName);
}

pub fn setting() !void {
    try addIndirectComputePass();
    try addIndirectDrawPass();
    try addI_FeatherPass();
    // try addIm_FeatherPass();
    try addPresentPass();
}
