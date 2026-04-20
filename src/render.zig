const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl").sdl;

const global = @import("global");
const tracy = @import("tracy");

const VkStruct = @import("video");
const vk = VkStruct.vk;
const OneTimeCommand = @import("processRender").oneTimeCommand;
const Commands = @import("processRender").commands;
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

    try vertices.init(&vulkan, &commands);
    defer vertices.deinit();

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

    try vulkan.createAllPipelinesAdded();

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

    const ubo_test = try vulkan.createUniformBuffer(@sizeOf(shaderStruct.UniformBufferObject));
    var pUIUbo: shaderStruct.UniformBufferObject = undefined;
    const ubo = vulkan.buffers.getBufferContent(ubo_test);

    const aspect2: f32 = 1.0 * (@as(f32, @floatFromInt(vulkan.windowHeight)) / 600.0);
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

    const ssbo_test = try vulkan.createStorageBuffer(global.MeshletStorageBufferSize);
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
        vulkan.buffers.getVkBuffer(ubo_test),
        0,
        vulkan.buffers.getBufferSize(ubo_test),
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

    global.stopNodeDagPrint = false;
    global.stopNodeDagDetailPrint = false;
    // global.stopExecuteNodePrint = false;

    const renderStart = std.Io.Timestamp.now(io, .real).toNanoseconds();
    global.game_end.store(1, .seq_cst);

    while (true) {
        const frame = vulkan.totalFrame.load(.seq_cst);

        if (frame == 100000) {
            global.stopExecuteNodePrint = true;
            global.stopNodeDagPrint = true;
        }

        try vulkan.waitEndFence();

        try commands.startCommand();
        try commands.addCachedCommand();
        try commands.addCommand(.draw2D, .{ .draw2D = .{
            .pipeline = vulkan.getPipeline("flat2d").?,
            .pTexture = pTextureSet.getTexture(@intCast(file.getID("circle.png"))).?,
            .rendering = rendering_test,
            .vertexBuffer = &testBuffers,
            .indexBuffer = vertices.indexBuffer2D,
            .descriptorSets = &testDescriptorSets,
            .pViewport = viewport_test,
            .pScissor = scissor_test,
        } });
        try commands.addCommand(.drawMesh, .{ .drawMesh = .{
            .pipeline = vulkan.getPipeline("model").?,
            .rendering = rendering_mesh_test,
            .descriptorSets = &testMeshDescriptorSets,
            .pTextures = &test_meshTextures,
            .pViewport = viewport_test,
            .pScissor = scissor_test,
            .usedBuffers = &test_meshBuffers,
            .meshletCount = meshes.meshletCount,
        } });
        try commands.addCommand(.present, .{ .present = .{
            .pipeline = vulkan.getPipeline("directOut").?,
            .pTextures = &presentTextures,
            .rendering = present_rendering_test,
            .descriptorSets = &presentDescriptorSets,
            .pViewport = viewport_test,
            .pScissor = scissor_test,
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
