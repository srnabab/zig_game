const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl").sdl;

const global = @import("global");
const tracy = @import("tracy");

const vk = @import("vulkan").vulkan;
const VkStruct = @import("video");
const OneTimeCommand = @import("processRender").oneTimeCommand;
const Commands = @import("processRender").commands;
const textureSet = @import("textureSet");
const rendering = @import("rendering");
const vertices = @import("vertices");
const shaderStruct = @import("video/shaderStruct.zig");

const cglm = @import("cglm").cglm;

const math = @import("math");

const Semaphore = std.Thread.Semaphore;

const file = @import("fileSystem");

var debug_allocator: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;

pub fn render_thread_func(
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

    const gpa, const is_debug = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };
    var tracyAllocator = tracy.TracingAllocator.initNamed("render thread", gpa);
    defer tracyAllocator.deinit();
    var taa = tracyAllocator.allocator();
    const allocator_t = &taa;

    var pTextureSet = textureSet.init(allocator_t.*, handles);
    var vulkan = VkStruct.init(allocator_t.*, handles, window, width, height);
    try vulkan.initVulkan(&pTextureSet);
    defer vulkan.deinit();
    defer pTextureSet.deinit(&vulkan);

    var pRendering = rendering.init(allocator_t.*, handles);
    defer pRendering.deinit();

    var commands = Commands.init(
        allocator_t.*,
        stackMemory[0..global.StackMemorySize],
        &vulkan,
        &pRendering,
        &pTextureSet,
    );
    defer commands.deinit();

    var graphic = OneTimeCommand.init(allocator_t.*, &vulkan, &pRendering);
    defer graphic.deinit();

    try vulkan.waitEndFence();
    try commands.startCommand();

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
        const ix = try vertices.vertexInitialize2D(48, 48, 0, 0, 0.1);
        try pTextureSet.offsetsAdd(temp, ix);
        try vertices.upload(&commands);
    }

    try commands.addCommandEnd();

    vulkan.writeCachedDescriptorSetResources();

    try graphic.executeCommands(&commands);
    vulkan.nextFrame();

    try vulkan.readPipelineFileAndAdd(comptime file.comptimeGetID("flat2d.pipeb"), .draw);
    try vulkan.readPipelineFileAndAdd(comptime file.comptimeGetID("directOut.pipeb"), .present);
    try vulkan.readPipelineFileAndAdd(comptime file.comptimeGetID("model.pipeb"), .meshDraw);

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
    // _ = rendering_test;

    var present_texture_test_array = [_]textureSet.Texture_t{undefined};
    const presetn_rendering_test = try pRendering.createRenderingInfo(
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

    try vulkan.addWriteDescriptorSetBuffer(
        0,
        vulkan.buffers.getVkBuffer(ubo_test),
        0,
        vulkan.buffers.getBufferSize(ubo_test),
        vulkan.globalFixed2dMVPMatrixDescriptorSet,
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

    vulkan.writeCachedDescriptorSetResources();

    const viewport_test = try vulkan.viewports.createViewport(.{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(vulkan.windowWidth),
        .height = @floatFromInt(vulkan.windowHeight),
        .maxDepth = 1.0,
        .minDepth = 0.0,
    });

    const scissor_test = try vulkan.scissors.createScissor(.{
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

    var presentTextures = [_]textureSet.Texture_t{texture_test};
    var presentDescriptorSets = [_]vk.VkDescriptorSet{vulkan.presentSamplerDescriptorSet};

    // global.stopNodeDagPrint = false;
    // global.stopExecuteNodePrint = false;

    const renderStart = std.time.milliTimestamp();
    global.game_end.store(1, .seq_cst);

    while (true) {
        const frame = vulkan.totalFrame.load(.seq_cst);

        if (frame == 3) {
            global.stopExecuteNodePrint = true;
            global.stopNodeDagPrint = true;
        }

        try vulkan.waitEndFence();

        try commands.startCommand();
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
        try commands.addCommand(.present, .{ .present = .{
            .pipeline = vulkan.getPipeline("directOut").?,
            .pTextures = &presentTextures,
            .rendering = presetn_rendering_test,
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
