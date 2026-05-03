const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl").sdl;

const global = @import("global");
const tracy = @import("tracy");

const VkStruct = @import("video");
const vk = VkStruct.vk;
const processRender = @import("processRender");
const OneTimeCommand = processRender.oneTimeCommand;
const Commands = processRender.commands;
const textureSet = @import("textureSet");
const rendering = @import("rendering");
const vertices = @import("vertices");
const shaderStruct = @import("video/shaderStruct.zig");
const vertexStruct = @import("vertexStruct");

const cglm = @import("cglm");

const math = @import("math");

const Semaphore = std.Io.Semaphore;

const file = @import("fileSystem");

const mesh = @import("mesh");

var debug_allocator: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;

pub fn render_thread_func(
    io: std.Io,
    gpa: std.mem.Allocator,
    thread_count: usize,
    endSemaphore: *Semaphore,
    handles: *global.HandlesType,
    window: *sdl.SDL_Window,
    width: u32,
    height: u32,
) !void {
    tracy.setThreadName("render");
    defer tracy.message("render exit");

    const zone = tracy.initZone(@src(), .{ .name = "render" });
    defer zone.deinit();

    var stackMemory = [_]u8{0} ** global.StackMemorySize;

    var tracyAllocator = tracy.TracingAllocator.initNamed("render thread", gpa);
    defer tracyAllocator.deinit();
    var taa = tracyAllocator.allocator();
    const allocator_t = &taa;

    var pTextureSet = textureSet.init(io, allocator_t.*, handles);
    var vulkan = VkStruct.init(allocator_t.*, handles, window, width, height);
    try vulkan.initVulkan(io, &pTextureSet);
    defer vulkan.deinit();
    defer pTextureSet.deinit(&vulkan);

    var pRendering = rendering.init(io, allocator_t.*, handles);
    defer pRendering.deinit();

    var commands = try Commands.init(
        io,
        allocator_t.*,
        stackMemory[0..global.StackMemorySize],
        &vulkan,
        &pRendering,
        &pTextureSet,
    );
    defer commands.deinit();

    var graphic = OneTimeCommand.init(io, allocator_t.*, &vulkan, &pRendering);
    defer graphic.deinit() catch |err| {
        std.debug.panic("error {s}", .{@errorName(err)});
    };

    try vertices.init(&vulkan, &commands, &pTextureSet, allocator_t.*);
    defer vertices.deinit(allocator_t.*);

    _ = try pTextureSet.createImageTexture(
        comptime file.comptimeGetID("non_exist.png"),
        .pixel2d,
        &vulkan,
        &commands,
    );
    {
        const temp = pTextureSet.createImageTextureEnsureWithErrorImage(
            comptime file.comptimeGetID("circle.png"),
            .pixel2d,
            &vulkan,
            &commands,
        );
        const ix = try vertices.vertexInitialize2D(io, 48, 48, 0, 0, 0.1);
        try pTextureSet.offsetsAdd(temp, ix);
        try vertices.upload(&commands);
    }
    const boxPng = pTextureSet.createImageTextureEnsureWithErrorImage(
        comptime file.comptimeGetID("box.png"),
        .pixel2d,
        &vulkan,
        &commands,
    );

    vulkan.writeCachedDescriptorSetResources();

    try vulkan.readPipelineFileAndAdd(io, comptime file.comptimeGetID("flat2d.pipeb"), .draw);
    try vulkan.readPipelineFileAndAdd(io, comptime file.comptimeGetID("directOut.pipeb"), .present);
    try vulkan.readPipelineFileAndAdd(io, comptime file.comptimeGetID("model.pipeb"), .meshDraw);
    try vulkan.readPipelineFileAndAdd(io, comptime file.comptimeGetID("indirectDraw.pipeb"), .draw);
    try vulkan.readPipelineFileAndAdd(io, comptime file.comptimeGetID("indirectDrawCompute.pipeb"), .compute);

    try vulkan.createAllPipelinesAdded();

    // vk.vkCreateComputePipelines(device: ?*struct_VkDevice_T, pipelineCache: ?*struct_VkPipelineCache_T, createInfoCount: u32, pCreateInfos: [*c]const struct_VkComputePipelineCreateInfo, pAllocator: [*c]const struct_VkAllocationCallbacks, pPipelines: [*c]?*struct_VkPipeline_T)
    // vk.VkComputePipelineCreateInfo

    const o1 = try vulkan.getPipelineOut("flat2d");
    for (o1) |value| {
        std.log.debug("{}", .{value});
    }

    const texture_test = try pTextureSet.create2DTexture(
        &vulkan,
        vulkan.windowWidth,
        vulkan.windowHeight,
        vk.VK_FORMAT_R8G8B8A8_SRGB,
        vk.VK_IMAGE_TILING_OPTIMAL,
        vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | vk.VK_IMAGE_USAGE_SAMPLED_BIT,
        "texture_test",
    );

    var colorAttachment: [1]vk.VkRenderingAttachmentInfo = undefined;
    colorAttachment[0] = vk.VkRenderingAttachmentInfo{
        .sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
        .imageView = pTextureSet.getVkImageView(texture_test),
        .imageLayout = vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
        .loadOp = vk.VK_ATTACHMENT_LOAD_OP_CLEAR,
        .storeOp = vk.VK_ATTACHMENT_STORE_OP_STORE,
        .clearValue = vk.VkClearValue{
            .color = vk.VkClearColorValue{
                .float32 = [_]f32{ 0.0, 0.0, 0.0, 0.0 },
            },
        },
    };

    var texture_test_array = [_]textureSet.Texture_t{texture_test};
    const rendering_test = try pRendering.createRenderingInfo(
        io,
        0,
        vk.VkRect2D{
            .extent = .{
                .width = vulkan.windowWidth,
                .height = vulkan.windowHeight,
            },
            .offset = .{ .x = 0, .y = 0 },
        },

        1,
        0,
        &texture_test_array,
        &colorAttachment,
        null,
        null,
    );
    colorAttachment[0].loadOp = vk.VK_ATTACHMENT_LOAD_OP_LOAD;
    const rendering_mesh_test = try pRendering.createRenderingInfo(
        io,
        0,
        vk.VkRect2D{
            .extent = .{
                .width = vulkan.windowWidth,
                .height = vulkan.windowHeight,
            },
            .offset = .{ .x = 0, .y = 0 },
        },

        1,
        0,
        &texture_test_array,
        &colorAttachment,
        null,
        null,
    );

    var present_texture_test_array = [_]textureSet.Texture_t{undefined};
    const present_rendering_test = try pRendering.createRenderingInfo(
        io,
        0,
        vk.VkRect2D{ .extent = .{
            .width = vulkan.windowWidth,
            .height = vulkan.windowHeight,
        }, .offset = .{ .x = 0, .y = 0 } },
        1,
        0,
        &present_texture_test_array,
        &colorAttachment,
        null,
        null,
    );

    const ubo_test = try vulkan.createBufferByUsage(
        @sizeOf(shaderStruct.UniformBufferObject),
        0,
        .uniform,
        false,
    );
    var pUIUbo: shaderStruct.UniformBufferObject = undefined;
    const ubo = vulkan.buffers.getBufferContent(ubo_test);

    const ubo_test2 = try vulkan.createBufferByUsage(
        @sizeOf(shaderStruct.UniformBufferObject),
        0,
        .uniform,
        false,
    );
    var pUIUbo2: shaderStruct.UniformBufferObject = undefined;
    const ubo2 = vulkan.buffers.getBufferContent(ubo_test2);

    const aspect2: f32 = 1.0 * (@as(f32, @floatFromInt(vulkan.windowHeight))) / 2;
    const aspect: f32 = (@as(f32, @floatFromInt(vulkan.windowWidth)) / @as(f32, @floatFromInt(vulkan.windowHeight))) * aspect2;
    const VIEW_SCALE = 1.0;

    var eye = cglm.vec3{ 0.0, 0.0, 100.0 };
    var center = cglm.vec3{ 0.0, 0.0, 0.0 };
    var up = cglm.vec3{ 0.0, 1.0, 0.0 };
    cglm.glmc_lookat(
        &eye,
        &center,
        &up,
        &pUIUbo.view,
    );
    math.glm_ortho_vulkan(
        -aspect * VIEW_SCALE,
        aspect * VIEW_SCALE,
        -aspect2 * VIEW_SCALE,
        aspect2 * VIEW_SCALE,
        -0.001,
        -100.0,
        &pUIUbo.proj,
    );
    const pData = @as(*shaderStruct.UniformBufferObject, @ptrCast(@alignCast(ubo.pMappedData)));
    pData.* = pUIUbo;

    // var testMatrix: vertexStruct.mat4 align(16) = undefined;
    // var res: vertexStruct.vec4 align(16) = undefined;
    // var value: vertexStruct.vec4 align(16) = vertexStruct.vec4{ 300, 0, 0.1, 1.0 };
    // cglm.glmc_mul(&pUIUbo.proj, &pUIUbo.view, &testMatrix);
    // cglm.glmc_mat4_mulv(&testMatrix, &value, &res);

    // std.log.debug("{d}, {d}, {d}, {d}", .{ res[0], res[1], res[2], res[3] });

    var eye2 = cglm.vec3{ 0.0, 0.0, 10.0 };
    var center2 = cglm.vec3{ 0.0, 0.0, 0.0 };
    var up2 = cglm.vec3{ 0.0, 1.0, 0.0 };
    cglm.glmc_lookat(
        &eye2,
        &center2,
        &up2,
        &pUIUbo2.view,
    );
    cglm.glmc_perspective(std.math.rad_per_deg * 60.0, (aspect / 300) * VIEW_SCALE, 0.1, 100.0, &pUIUbo2.proj);
    const pData2 = @as(*shaderStruct.UniformBufferObject, @ptrCast(@alignCast(ubo2.pMappedData)));
    pData2.* = pUIUbo2;

    const ssbo_test = try vulkan.createBufferByUsage(
        global.MeshletStorageBufferSize,
        0,
        .storage,
        false,
    );
    const ssbo_test_meshlets = try vulkan.createVirtualBlockBuffer(
        0,
        global.StorageBufferMeshletsSize,
        ssbo_test,
        0,
        @sizeOf(vertexStruct.Vertex_f3pf3nf2u),
    );
    const ssbo_test_vertices = try vulkan.createVirtualBlockBuffer(
        0,
        global.StorageBufferVerticesSize,
        ssbo_test,
        global.StorageBufferMeshletsEnd,
        @sizeOf(vertexStruct.Meshlet),
    );
    const ssbo_test_meshletVertices = try vulkan.createVirtualBlockBuffer(
        0,
        global.StorageBufferMeshletVerticesSize,
        ssbo_test,
        global.StorageBufferVerticesEnd,
        @sizeOf(u32),
    );
    const ssbo_test_meshletTriangles = try vulkan.createVirtualBlockBuffer(
        0,
        global.StorageBufferMeshletTrianglesSize,
        ssbo_test,
        global.StorageBufferMeshletVerticesEnd,
        @sizeOf(u8),
    );
    var meshes = mesh.init(
        ssbo_test_meshlets,
        ssbo_test_vertices,
        ssbo_test_meshletVertices,
        ssbo_test_meshletTriangles,
        null,
        io,
    );
    try meshes.loadMeshlet(comptime file.comptimeGetID("Suzanne_0.vtx"), gpa, &vulkan, &commands);

    try vulkan.addWriteDescriptorSetBuffer(
        0,
        vulkan.buffers.getVkBuffer(ubo_test),
        0,
        vulkan.buffers.getBufferSize(ubo_test),
        vulkan.globalFixed2dMVPMatrixDescriptorSet,
        0,
        vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
    );

    try vulkan.addWriteDescriptorSetBuffer(
        0,
        vulkan.buffers.getVkBuffer(ubo_test2),
        0,
        vulkan.buffers.getBufferSize(ubo_test2),
        vulkan.global3dMVPMatrixDescriptorSet,
        0,
        vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
    );

    try vulkan.addWriteDescriptorSetImage(
        0,
        pTextureSet.getVkImageView(texture_test),
        vulkan.samplers.getDefaultSampler(.pixel2d),
        vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
        vulkan.presentSamplerDescriptorSet,
        0,
        vk.VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
    );

    try vulkan.addWriteDescriptorSetBuffer(
        0,
        vulkan.buffers.getVkBuffer(ssbo_test_meshlets),
        vulkan.buffers.getBufferOffset(ssbo_test_meshlets),
        vulkan.buffers.getBufferSize(ssbo_test_meshlets),
        vulkan.meshletsDescriptorSet,
        0,
        vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
    );

    try vulkan.addWriteDescriptorSetBuffer(
        0,
        vulkan.buffers.getVkBuffer(ssbo_test_vertices),
        vulkan.buffers.getBufferOffset(ssbo_test_vertices),
        vulkan.buffers.getBufferSize(ssbo_test_vertices),
        vulkan.meshletsDescriptorSet,
        1,
        vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
    );

    try vulkan.addWriteDescriptorSetBuffer(
        0,
        vulkan.buffers.getVkBuffer(ssbo_test_meshletVertices),
        vulkan.buffers.getBufferOffset(ssbo_test_meshletVertices),
        vulkan.buffers.getBufferSize(ssbo_test_meshletVertices),
        vulkan.meshletsDescriptorSet,
        2,
        vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
    );

    try vulkan.addWriteDescriptorSetBuffer(
        0,
        vulkan.buffers.getVkBuffer(ssbo_test_meshletTriangles),
        vulkan.buffers.getBufferOffset(ssbo_test_meshletTriangles),
        vulkan.buffers.getBufferSize(ssbo_test_meshletTriangles),
        vulkan.meshletsDescriptorSet,
        3,
        vk.VK_DESCRIPTOR_TYPE_STORAGE_BUFFER,
    );

    vulkan.writeCachedDescriptorSetResources();

    const viewport_test = try vulkan.viewports.createViewport(io, .{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(vulkan.windowWidth),
        .height = @floatFromInt(vulkan.windowHeight),
        .maxDepth = 1.0,
        .minDepth = 0.0,
    });

    const scissor_test = try vulkan.scissors.createScissor(io, .{
        .extent = .{
            .width = vulkan.windowWidth,
            .height = vulkan.windowHeight,
        },
        .offset = .{ .x = 0, .y = 0 },
    });

    var testBuffers = [_]VkStruct.Buffer_t{
        vertices.vertexBuffer2D,
    };
    var testDescriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalFixed2dMVPMatrixDescriptorSet, vulkan.globalTextureDescriptorSet,
    };

    var testMeshDescriptorSets = [_]vk.VkDescriptorSet{
        vulkan.global3dMVPMatrixDescriptorSet,
        vulkan.globalTextureDescriptorSet,
        vulkan.meshletsDescriptorSet,
    };

    var presentTextures = [_]textureSet.Texture_t{texture_test};
    var presentDescriptorSets = [_]vk.VkDescriptorSet{vulkan.presentSamplerDescriptorSet};

    var test_meshTextures = [_]textureSet.Texture_t{boxPng};
    var test_meshBuffers = [_]VkStruct.Buffer_t{
        ssbo_test,
    };

    var test_computeBuffers = [_]VkStruct.Buffer_t{
        vertices.instanceBuffer2D,
        vertices.indirectDrawCommandBuffer,
        vertices.instanceIDsBuffer,
    };
    // var test_computeDescriptorSets =

    var test_indirectBuffers = [_]VkStruct.Buffer_t{
        vertices.instanceBuffer2D,
        vertices.instanceIDsBuffer,
    };

    const box1 = try vertices.addInstance(0, 0, 48, 32, 0.1, boxPng);
    _ = try vertices.addInstance(300, 0, 48, 32, 0.1, boxPng);
    _ = try vertices.addInstance(0, 200, 48, 32, 0.1, boxPng);
    _ = try vertices.addInstance(-400, 0, 48, 32, 0.1, boxPng);
    _ = try vertices.addInstance(0, -300, 48, 32, 0.1, boxPng);
    _ = try vertices.addInstance(345, -438, 48, 32, 0.1, boxPng);
    _ = box1;

    try vertices.uploadInstance(&commands);

    commands.setViewport(viewport_test);
    commands.setScissor(scissor_test);

    const renderStart = std.Io.Timestamp.now(io, .real).toNanoseconds();

    const circleTexture = pTextureSet.getTexture(@intCast(file.getID("circle.png"))).?;
    var circleIndex = pTextureSet.getDescriptorSetIndex(circleTexture);
    var vertexBufferAddress = vulkan.getBufferAddress(vulkan.buffers.getVkBuffer(vertices.vertexBuffer2D));
    var instanceBufferAddress = vulkan.getBufferAddress(vulkan.buffers.getVkBuffer(vertices.instanceBuffer2D));
    var instanceIDsBufferAddress = vulkan.getBufferAddress(vulkan.buffers.getVkBuffer(vertices.instanceIDsBuffer));
    const indirectBufferAddress = vulkan.getBufferAddress(vulkan.buffers.getVkBuffer(vertices.indirectDrawCommandBuffer));

    var boxIndex = pTextureSet.getDescriptorSetIndex(boxPng);

    var draw2dPushConstants = [_]processRender.drawC.PushConstantPack{
        .{
            .pValues = &vertexBufferAddress,
            .size = @sizeOf(u64),
            .offset = 0,
            .stageFlag = vk.VK_SHADER_STAGE_VERTEX_BIT,
        },
        .{
            .pValues = &circleIndex,
            .size = @sizeOf(u32),
            .offset = @sizeOf(u64),
            .stageFlag = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
        },
    };
    var drawMeshPushConstants = [_]processRender.drawC.PushConstantPack{
        .{
            .pValues = &boxIndex,
            .size = @sizeOf(u32),
            .offset = @sizeOf(u64),
            .stageFlag = vk.VK_SHADER_STAGE_FRAGMENT_BIT,
        },
    };
    var drawIndirectPushConstants = [_]processRender.drawC.PushConstantPack{
        .{
            .pValues = &instanceBufferAddress,
            .size = @sizeOf(u64),
            .offset = 0,
            .stageFlag = vk.VK_SHADER_STAGE_VERTEX_BIT,
        },
        .{
            .pValues = &instanceIDsBufferAddress,
            .size = @sizeOf(u64),
            .offset = @sizeOf(u64),
            .stageFlag = vk.VK_SHADER_STAGE_VERTEX_BIT,
        },
    };
    var constants = vertexStruct.IndirectDrawComputePushConstants{
        .instanceBuffer = instanceBufferAddress,
        .indirectAddress = indirectBufferAddress,
        .instanceIDs = instanceIDsBufferAddress,
        .viewBounds = vertexStruct.vec4{ -300, 300, -400, 400 },
        .totalSpriteCount = @intCast(vertices.instances2D.items.len),
    };
    const computeIndirectDrawPushConstants = processRender.drawC.PushConstantPack{
        .pValues = &constants,
        .size = @sizeOf(vertexStruct.IndirectDrawComputePushConstants),
        .offset = 0,
        .stageFlag = vk.VK_SHADER_STAGE_COMPUTE_BIT,
    };

    // global.stopNodeDagPrint = false;
    // global.printDagToDot = true;
    // global.stopNodeDagDetailPrint = false;
    // global.stopExecuteNodePrint = false;
    // global.storExecuteSequencePrint = false;
    // global.game_end.store(1, .seq_cst);

    // vulkan.logBufferPtr();
    // vulkan.logPipeline();

    while (true) {
        const frame = vulkan.totalFrame.load(.seq_cst);

        // if (frame == 0) {
        //     global.stopNodeDagPrint = false;
        //     global.printDagToDot = true;
        // }
        // if (frame == 1) {
        //     global.game_end.store(1, .seq_cst);
        // }

        if (frame == 100000) {
            global.stopExecuteNodePrint = true;
            global.stopNodeDagPrint = true;
        }

        try vulkan.waitEndFence();

        try commands.startCommand();
        try commands.addCachedCommand();
        // std.log.debug("draw2d", .{});
        try commands.addCommand(.draw2D, .{ .draw2D = .{
            .pipeline = vulkan.getPipeline("flat2d").?,
            .pTexture = circleTexture,
            .rendering = rendering_test,
            .vertexBuffer = &testBuffers,
            .indexBuffer = vertices.indexBuffer2D,
            .descriptorSets = &testDescriptorSets,
            .pushConstants = &draw2dPushConstants,
        } });
        try commands.addCommand(.compute, .{ .compute = .{
            .pipeline = vulkan.getPipeline("indirectDrawCompute").?,
            .pTextures = &.{},
            .usedBuffers = &test_computeBuffers,
            .descriptorSets = &.{},
            .groupCount = 1,
            .pushConstants = computeIndirectDrawPushConstants,
        } });
        try commands.addCommand(.drawIndirect, .{ .drawIndirect = .{
            .pipeline = vulkan.getPipeline("indirectDraw").?,
            .rendering = rendering_mesh_test,
            .descriptorSets = &testDescriptorSets,
            .pTextures = &test_meshTextures,
            .usedBuffers = &test_indirectBuffers,
            .indirectBuffer = vertices.indirectDrawCommandBuffer,
            .pushConstants = &drawIndirectPushConstants,
        } });
        // std.log.debug("drawmesh", .{});
        try commands.addCommand(.drawMesh, .{ .drawMesh = .{
            .pipeline = vulkan.getPipeline("model").?,
            .rendering = rendering_mesh_test,
            .descriptorSets = &testMeshDescriptorSets,
            .pTextures = &test_meshTextures,
            .usedBuffers = &test_meshBuffers,
            .meshletCount = meshes.meshletCount,
            .pushConstants = &drawMeshPushConstants,
        } });
        // std.log.debug("present", .{});
        try commands.addCommand(.present, .{ .present = .{
            .pipeline = vulkan.getPipeline("directOut").?,
            .pTextures = &presentTextures,
            .rendering = present_rendering_test,
            .descriptorSets = &presentDescriptorSets,
        } });
        try commands.addCommandEnd();

        try graphic.executeCommands(&commands);

        vulkan.nextFrame();

        // if (std.time.milliTimestamp() - renderStart > 1 * std.time.ms_per_s) {
        if (global.game_end.load(.seq_cst) == 1) {
            _ = renderStart;
            break;
        }
    }

    // vulkan.logBufferPtr();

    // textureSett.logImagePtr();

    _ = endSemaphore;
    _ = thread_count;
}
