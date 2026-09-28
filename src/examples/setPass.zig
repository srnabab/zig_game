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
const u8pack = @import("u8pack");

const vec4 = cglm.vec4;

const i_feather = @import("setPass/i_feather.zig");
const indirect2D = @import("setPass/indirect2D.zig");

fn initPresent(
    userdata: *?*anyopaque,
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

    try commands.addCommand(.present, .{
        .present = .{
            .pipeline = pass.pipeline[0],
            .pTextures = pass.texture,
            .descriptorSets = pass.descriptorSet,
            .pushConstants = pass.pushConstant[0],
            .uboOffset = vulkan.getUboOffset(u8pack.toStr("fixed2d")),
        },
    });

    pass.clearTexture(gpa);
}

const vtablePresent = VTable{
    .init = initPresent,
    .addCommand = addPresentCommand,
};

fn addPresentPass(comptime ctx: ?*u8pack.CTX) !void {
    const pipe = try renderFlow.addPipeline(ctx, "directOut.pipeb", false);
    try renderFlow.createPass(ctx, "present");
    try renderFlow.addPipelineToPass(ctx, "present", pipe);
    try renderFlow.setPushConstant(ctx, "present", vk.VK_SHADER_STAGE_VERTEX_BIT, 4);
    try renderFlow.addVTableToPass(ctx, "present", &vtablePresent);

    try renderFlow.appendPass(ctx, "present");
}

pub const ViewBoundsAndTotalSpriteCount = extern struct {
    viewBounds: vec4,
    totalSpriteCount: u32,
};

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

pub fn setting(comptime ctx: ?*u8pack.CTX) !void {
    try indirect2D.addIndirect2DPass(ctx);
    try i_feather.addI_FeatherPass(ctx);
    // try addIm_FeatherPass();
    try addPresentPass(ctx);
}

// pub fn userdataInit(passes: *renderFlow, gpa: std.mem.Allocator) !void {}
