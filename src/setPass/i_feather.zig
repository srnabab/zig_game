const std = @import("std");
const Allocator = std.mem.Allocator;

const mstd = @import("ms_std");

const math = mstd.Math;

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
    userdata: *?*anyopaque,
    pass: *Pass,
    vulkan: *VkStruct,
    commands: *ExternalCommands,
    gpa: std.mem.Allocator,
) !void {
    const ptr = try gpa.create(u32);
    ptr.* = 0;
    userdata.* = ptr;

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

    var descriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalTextureDescriptorSet,
        vulkan.global3dMVPMatrixDescriptorSet,
    };
    try pass.setDescriptorSets(&descriptorSets, gpa);

    try commands.externalCommand(.{ .fillBuffer = .{
        .buffer = pass.buffer[IF.dispatchCommands],
        .offset = 0,
        .size = 12,
        .value = 1,
    } });
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
        .uboOffset = null,
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
        .uboOffset = null,
    } });

    vulkan.buffers.writeBuffer(pass.buffer[IF.payloads]);
    vulkan.buffers.writeBuffer(pass.buffer[IF.drawCommands]);

    // ---- iv_feather: drawIndirect ----
    commands.setViewport(.{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(vulkan.windowWidth),
        .height = @floatFromInt(vulkan.windowHeight),
        .maxDepth = 1.0,
        .minDepth = 0.0,
    });

    commands.setScissor(.{
        .extent = .{
            .width = vulkan.windowWidth,
            .height = vulkan.windowHeight,
        },
        .offset = .{ .x = 0, .y = 0 },
    });

    try commands.addCommand(.drawIndirect, .{ .drawIndirect = .{
        .descriptorSets = pass.descriptorSet,
        .pipeline = pass.pipeline[2],
        .usedBuffers = pass.buffer,
        .pushConstants = pass.pushConstant[2],
        .indirectBuffer = pass.buffer[IF.drawCommands],
        .pTextures = pass.texture,
        .uboOffset = vulkan.getUboOffset(u8pack.toStr("camera3d")),
    } });

    pass.clearTexture(gpa);
}

const vtableI_Feather = VTable{
    .init = initI_Feather,
    .addCommand = addI_FeatherCommand,
};

pub fn addI_FeatherPass(comptime ctx: ?*u8pack.CTX) !void {
    const passName = "i_feather";

    const buffer0 = try renderFlow.createBuffer(
        ctx,
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
        ctx,
        "featherStorageBuffer",
        totalSize,
        0,
        .storage,
        false,
        null,
    );

    const buffer2 = try renderFlow.createBuffer(
        ctx,
        "featherMeshlet",
        meshletSize,
        @sizeOf(vertexStruct.Meshlet),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer3 = try renderFlow.createBuffer(
        ctx,
        "featherVertices",
        verticesSize,
        @sizeOf(vertexStruct.Vertex_f3pf3nf4tf2u),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer4 = try renderFlow.createBuffer(
        ctx,
        "featherMeshletVertices",
        meshletVerticesSize,
        @sizeOf(u32),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer5 = try renderFlow.createBuffer(
        ctx,
        "featherMeshletTriangles",
        mehsletTrianglesSize,
        @sizeOf(u8),
        .storage,
        true,
        "featherStorageBuffer",
    );

    const buffer6 = try renderFlow.createBuffer(
        ctx,
        "iv_FeatherCommand",
        @sizeOf(vertexStruct.CustomDrawMeshTasksIndirectCommand) * 2,
        0,
        .storage,
        false,
        null,
    );

    const buffer7 = try renderFlow.createBuffer(
        ctx,
        "indirectComputeCommand",
        @sizeOf(vk.VkDispatchIndirectCommand),
        0,
        .indirect,
        false,
        null,
    );

    const buffer8 = try renderFlow.createBuffer(
        ctx,
        "groupMappings",
        @sizeOf(vertexStruct.GroupMapping) * 4,
        @sizeOf(vertexStruct.GroupMapping),
        .storage,
        false,
        null,
    );

    const buffer9 = try renderFlow.createBuffer(
        ctx,
        "instance3D",
        @sizeOf(vertexStruct.Instance3D) * 4,
        @sizeOf(vertexStruct.Instance3D),
        .storage,
        false,
        null,
    );

    const buffer10 = try renderFlow.createBuffer(
        ctx,
        "meshes",
        @sizeOf(vertexStruct.Mesh) * 40,
        @sizeOf(vertexStruct.Mesh),
        .storage,
        false,
        null,
    );

    const buffer11 = try renderFlow.createBuffer(
        ctx,
        "computeTaskPayload",
        @sizeOf(vertexStruct.ComputeTaskPayload) * 400,
        @sizeOf(vertexStruct.ComputeTaskPayload),
        .storage,
        false,
        null,
    );

    const buffer12 = try renderFlow.createBuffer(
        ctx,
        "featherParameters",
        20000 * 192 * @sizeOf(f32),
        @sizeOf(f32),
        .storageRead,
        false,
        null,
    );

    const pipeC = try renderFlow.addPipeline(ctx, "c_commandPrefixSum.pipeb", false);
    const pipeIc = try renderFlow.addPipeline(ctx, "ic_task.pipeb", false);
    const pipeIv = try renderFlow.addPipeline(ctx, "iv_feather.pipeb", false);

    try renderFlow.createPass(ctx, passName);
    try renderFlow.addPipelineToPass(ctx, passName, pipeC);
    try renderFlow.addPipelineToPass(ctx, passName, pipeIc);
    try renderFlow.addPipelineToPass(ctx, passName, pipeIv);
    try renderFlow.addBufferToPass(ctx, passName, buffer0);
    try renderFlow.addBufferToPass(ctx, passName, buffer1);
    try renderFlow.addBufferToPass(ctx, passName, buffer2);
    try renderFlow.addBufferToPass(ctx, passName, buffer3);
    try renderFlow.addBufferToPass(ctx, passName, buffer4);
    try renderFlow.addBufferToPass(ctx, passName, buffer5);
    try renderFlow.addBufferToPass(ctx, passName, buffer6);
    try renderFlow.addBufferToPass(ctx, passName, buffer7);
    try renderFlow.addBufferToPass(ctx, passName, buffer8);
    try renderFlow.addBufferToPass(ctx, passName, buffer9);
    try renderFlow.addBufferToPass(ctx, passName, buffer10);
    try renderFlow.addBufferToPass(ctx, passName, buffer11);
    try renderFlow.addBufferToPass(ctx, passName, buffer12);

    try renderFlow.setPushConstant(ctx, passName, vk.VK_SHADER_STAGE_COMPUTE_BIT, 16);
    try renderFlow.setPushConstant(ctx, passName, vk.VK_SHADER_STAGE_COMPUTE_BIT, 52);
    try renderFlow.setPushConstant(ctx, passName, vk.VK_SHADER_STAGE_VERTEX_BIT, @sizeOf(Iv_feather_PushConstant));

    try renderFlow.addVTableToPass(ctx, passName, &vtableI_Feather);

    try renderFlow.appendPass(ctx, passName);
}
