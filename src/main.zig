const std = @import("std");
const process = std.process;

const vk = @import("vulkan").vulkan;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));
const SDL_CheckResult = @import("sdl").SDL_CheckResult;

const Thread = std.Thread;
const builtin = @import("builtin");
const output = @import("output");
const log = std.log;
const ECS = @import("ECS");
const steam = @import("steam");
const steamInner = steam.steamInner;
const textureSet = @import("textureSet");
const rendering = @import("rendering");

const update = @import("update.zig");
const render = @import("render.zig");
const VkStruct = @import("video");
const OneTimeCommand = @import("processRender").oneTimeCommand;
const vertices = @import("vertices");
const math = @import("math");

const shaderStruct = @import("video/shaderStruct.zig");

const file = @import("fileSystem");

const tracy = @import("tracy");

const Allocator = std.mem.Allocator;

const global = @import("global");

var handles: global.HandlesType = undefined;

var thread_count: usize = 0;
var update_thread: usize = 0;
var render_thread: usize = 0;

var debug_allocator: std.heap.DebugAllocator(.{ .stack_trace_frames = 10 }) = .init;
pub fn main() !void {
    const gpa, const is_debug = gpa: {
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };
    var tracyAllocator = tracy.TracingAllocator.initNamed("pool", gpa);
    defer tracyAllocator.deinit();
    var taa = tracyAllocator.allocator();
    const allocator_t = &taa;

    tracy.startupProfiler();
    defer tracy.shutdownProfiler();

    tracy.setThreadName("main");
    defer tracy.message("main thread exit");

    const mainZone = tracy.initZone(@src(), .{ .name = "main" });
    defer mainZone.deinit();

    var stackMemory = [_]u8{0} ** global.StackMemorySize;

    // var tracyStackAllocator = tracy.TracingAllocator.initNamed("stack", stackAllocator.allocator());
    // defer tracyStackAllocator.deinit();

    output.init();

    const args = try process.argsAlloc(allocator_t.*);
    defer process.argsFree(allocator_t.*, args);

    for (args) |arg| {
        // try output.out.print("arg: {s}\n", .{arg});
        std.log.info("arg: {s}", .{arg});
    }

    {
        const zone = tracy.initZone(@src(), .{ .name = "set cwd" });
        defer zone.deinit();

        const index = std.mem.lastIndexOf(u8, args[0], "\\").?;
        var temp = try std.fs.openDirAbsolute(args[0][0..index], .{});
        try temp.setAsCwd();
    }

    handles = try .init(gpa);
    defer handles.deinit(gpa);

    file.init();
    defer file.deinit();

    {
        const zone = tracy.initZone(@src(), .{ .name = "init SDL" });
        defer zone.deinit();

        try SDL_CheckResult(sdl.SDL_Init(sdl.SDL_INIT_EVENTS | sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_AUDIO | sdl.SDL_INIT_GAMEPAD));
    }
    defer sdl.SDL_Quit();
    std.log.debug("SDL Version: {d}.{d}.{d}", .{
        sdl.SDL_MAJOR_VERSION,
        sdl.SDL_MINOR_VERSION,
        sdl.SDL_MICRO_VERSION,
    });

    var textureSett = textureSet.init(allocator_t.*, &handles);
    var vulkan = VkStruct.init(allocator_t.*, &handles);
    try vulkan.initVulkan(&textureSett);
    defer vulkan.deinit();
    defer textureSett.deinit(&vulkan);

    var renderingInfo = rendering.init(allocator_t.*, &handles);
    defer renderingInfo.deinit();

    var graphic = OneTimeCommand.init(allocator_t.*, &stackMemory, &vulkan, &renderingInfo);
    defer graphic.deinit();

    // var tt = try std.Thread.spawn(.{}, testSemaphore, .{&vulkan});
    // defer tt.join();

    try graphic.startCommand();

    try vertices.init(&vulkan, &graphic);
    defer vertices.deinit();

    _ = try textureSett.createImageTexture(
        comptime file.comptimeGetID("non_exist.png"),
        .pixel2d,
        &vulkan,
        &graphic,
    );
    {
        const temp = textureSett.createImageTextureEnsureWithErrorImage(
            comptime file.comptimeGetID("circle.png"),
            .pixel2d,
            &vulkan,
            &graphic,
        );
        const ix = try vertices.vertexInitialize2D(48, 48, 0, 0, 0.1, try textureSett.getDescriptorSetIndex(temp));
        try textureSett.offsetsAdd(temp, ix);
        try vertices.upload(&graphic);
    }

    try graphic.addCommandEnd();

    vulkan.writeCachedDescriptorSetResources();

    try graphic.executeCommands();
    vulkan.nextFrame();

    try vulkan.readPipelineFileAndAdd(comptime file.comptimeGetID("flat2d.pipeb"), .draw);
    try vulkan.readPipelineFileAndAdd(comptime file.comptimeGetID("directOut.pipeb"), .present);

    try vulkan.createAllPipelinesAdded();

    const o1 = try vulkan.getPipelineOut("flat2d");
    for (o1) |value| {
        std.log.debug("{}", .{value});
    }

    const texture_test = try textureSett.create2DTexture(
        &vulkan,
        vulkan.windowWidth,
        vulkan.windowsHeight,
        vk.VK_FORMAT_R8G8B8A8_SRGB,
        vk.VK_IMAGE_TILING_OPTIMAL,
        vk.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | vk.VK_IMAGE_USAGE_SAMPLED_BIT,
        "texture_test",
    );

    var colorAttachment: [1]vk.VkRenderingAttachmentInfo = undefined;
    colorAttachment[0] = vk.VkRenderingAttachmentInfo{
        .sType = vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
        .imageView = textureSett.getVkImageView(texture_test),
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
    const rendering_test = try renderingInfo.createRenderingInfo(
        0,
        vk.VkRect2D{
            .extent = .{
                .width = vulkan.windowWidth,
                .height = vulkan.windowsHeight,
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
    const presetn_rendering_test = try renderingInfo.createRenderingInfo(
        0,
        vk.VkRect2D{ .extent = .{
            .width = vulkan.windowWidth,
            .height = vulkan.windowsHeight,
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

    const aspect2: f32 = 1.0 * (@as(f32, @floatFromInt(vulkan.windowsHeight)) / 600.0);
    const aspect: f32 = (@as(f32, @floatFromInt(vulkan.windowWidth)) / @as(f32, @floatFromInt(vulkan.windowsHeight))) * aspect2;
    const VIEW_SCALE = 1.0;

    var eye = vertices.cglm.vec3{ 0.0, 0.0, 100.0 };
    var center = vertices.cglm.vec3{ 0.0, 0.0, 0.0 };
    var up = vertices.cglm.vec3{ 0.0, 1.0, 0.0 };
    vertices.cglm.glm_lookat(
        &eye,
        &center,
        &up,
        &pUIUbo.view,
    );
    math.glm_ortho_vulkan(-aspect * VIEW_SCALE, aspect * VIEW_SCALE, -aspect2 * VIEW_SCALE, aspect2 * VIEW_SCALE, -0.001, -100.0, &pUIUbo.proj);
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
        textureSett.getVkImageView(texture_test),
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
        .height = @floatFromInt(vulkan.windowsHeight),
        .maxDepth = 1.0,
        .minDepth = 0.0,
    });

    const scissor_test = try vulkan.scissors.createScissor(.{
        .extent = .{
            .width = vulkan.windowWidth,
            .height = vulkan.windowsHeight,
        },
        .offset = .{ .x = 0, .y = 0 },
    });

    var testBuffers = [_]VkStruct.Buffer_t{
        vertices.vertexBuffer2D,
    };
    var testDescriptorSets = [_]vk.VkDescriptorSet{
        vulkan.globalFixed2dMVPMatrixDescriptorSet, vulkan.globalTextureDescriptorSet,
    };

    // std.Thread.sleep(std.time.ns_per_s);

    var presentTextures = [_]textureSet.Texture_t{texture_test};
    var presentDescriptorSets = [_]vk.VkDescriptorSet{vulkan.presentSamplerDescriptorSet};
    // _ = presetn_rendering_test;

    // global.stopNodeDagPrint = false;
    // global.stopExecuteNodePrint = false;

    const renderStart = std.time.milliTimestamp();
    while (true) {
        // log.info("frame {d}", .{vulkan.totalFrame.load(.seq_cst)});
        const frame = vulkan.totalFrame.load(.seq_cst);

        if (frame == 3) global.stopNodeDagPrint = true;

        try graphic.startCommand();
        try graphic.addCommand(.draw2D, .{ .draw2d = .{
            .pipeline = vulkan.getPipeline("flat2d").?,
            .pTexture = textureSett.getTexture(@intCast(file.getID("circle.png"))).?,
            .rendering = rendering_test,
            .vertexBuffer = &testBuffers,
            .indexBuffer = vertices.indexBuffer2D,
            .pTextureSet = &textureSett,
            .descriptorSets = &testDescriptorSets,
            .pViewport = viewport_test,
            .pScissor = scissor_test,
        } });
        try graphic.addCommand(.present, .{ .present = .{
            .pipeline = vulkan.getPipeline("directOut").?,
            .pTextures = &presentTextures,
            .rendering = presetn_rendering_test,
            .pTextureSet = &textureSett,
            .descriptorSets = &presentDescriptorSets,
            .pViewport = viewport_test,
            .pScissor = scissor_test,
        } });
        try graphic.addCommandEnd();
        try graphic.executeCommands();
        vulkan.nextFrame();

        // if (std.time.milliTimestamp() - renderStart > 1 * std.time.ms_per_s) {
        if (vulkan.totalFrame.load(.seq_cst) > 20000) {
            _ = renderStart;
            break;
        }
    }

    thread_count = try Thread.getCpuCount();
    // const thread_count: u32 = 1023;
    const thread_used_count = cot: {
        var count = thread_count;
        if (thread_count < 8) {
            count = count - 1;
        } else {
            count = count - 2;
        }
        break :cot count;
    };
    update_thread = thread_used_count / 2;
    render_thread = thread_used_count - update_thread;
    log.info("logical core count: {d}", .{thread_count});
    log.info("core will be used count: {d}", .{thread_used_count});
    log.info("update thread count {d}", .{update_thread});
    log.info("render thread count {d}", .{render_thread});
    std.log.info("cache line {d}", .{std.atomic.cache_line});

    if (steamInner.SteamAPI_RestartAppIfNecessary_C(@as(u32, steamInner.k_uAppIdInvalid_C))) {
        return error.SteamError;
    }
    if (!steamInner.SteamAPI_Init_C()) {
        return error.SteamError;
    }
    defer steamInner.SteamAPI_Shutdown_C();

    var achievements = steam.Achievement{
        .pUserStats = steamInner.SteamUserStats_C().?,
        .StoreStats = false,
    };
    achievements.UnlockAchievement(@ptrCast(&steam.g_rgAchievements[1]));
    achievements.StoreStatsIfNecessary();

    var endSemaphore: std.Thread.Semaphore = .{};

    var update_t = try Thread.spawn(.{}, update.update_thread_func, .{update_thread});
    defer update_t.join();

    var render_t = try Thread.spawn(
        .{},
        render.render_thread_func,
        .{ render_thread, &endSemaphore },
    );
    defer render_t.join();

    endSemaphore.post();

    // vulkan.logBufferPtr();

    // textureSett.logImagePtr();
}

fn testSemaphore(vulkan: *VkStruct) void {
    const time = std.time.milliTimestamp();

    while (std.time.milliTimestamp() - time < 15) {
        var value: u64 = undefined;
        _ = vk.vkGetSemaphoreCounterValue(vulkan.device, vulkan.globalTimelineSemaphore, &value);
        std.log.debug("semaphore value {d}", .{value});

        std.Thread.sleep(comptime 0.5 * std.time.ns_per_ms);
    }
}
