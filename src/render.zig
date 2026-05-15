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
const shaderStruct = @import("video/shaderStruct.zig");
const vertexStruct = @import("vertexStruct");
const resource = @import("resource");
const Queue = @import("queue").Queue;
const Handles = @import("handle");
const vertices2D = @import("video/indirect2D/vertices.zig");

const cglm = @import("cglm");

const math = @import("math");

const Semaphore = std.Io.Semaphore;

const file = @import("fileSystem");

const mesh = @import("mesh");
const pass = @import("pass");

pub const Args = struct {
    io: std.Io,
    gpa: std.mem.Allocator,
    thread_count: usize,
    endSemaphore: *Semaphore,
    handles: *global.HandlesType,
    window: *sdl.SDL_Window,
    width: u32,
    height: u32,
    resourceArrays: *global.ResourceArrayType,
    stateBuffering: *global.StateBufferingType,
    pTextureSet: *textureSet,
    vulkan: *VkStruct,
    passes: pass,
};

pub fn render_thread_func(args: Args) !void {
    tracy.setThreadName("render");
    defer tracy.message("render exit");

    const io = args.io;
    const gpa = args.gpa;
    const thread_count = args.thread_count;
    const endSemaphore = args.endSemaphore;
    // const handles = args.handles;
    // const window = args.window;
    // const width = args.width;
    // const height = args.height;
    const resourceArrays = args.resourceArrays;
    const stateBuffering = args.stateBuffering;
    const pTextureSet = args.pTextureSet;
    const vulkan = args.vulkan;
    var passes = args.passes;

    const zone = tracy.initZone(@src(), .{ .name = "render" });
    defer zone.deinit();

    var stackMemory = [_]u8{0} ** global.StackMemorySize;

    var tracyAllocator = tracy.TracingAllocator.initNamed("render thread", gpa);
    defer tracyAllocator.deinit();
    var taa = tracyAllocator.allocator();
    const allocator_t = &taa;

    var commands = try Commands.init(
        io,
        allocator_t.*,
        stackMemory[0..global.StackMemorySize],
        vulkan,
        pTextureSet,
    );
    defer commands.deinit();

    var graphic = OneTimeCommand.init(io, allocator_t.*, vulkan);
    defer graphic.deinit() catch |err| {
        std.debug.panic("error {s}", .{@errorName(err)});
    };

    try vulkan.createAllPipelinesAdded();

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

    // const ssbo_test = try vulkan.createBufferByUsage(
    //     global.MeshletStorageBufferSize,
    //     0,
    //     .storage,
    //     false,
    // );
    // const ssbo_test_meshlets = try vulkan.createVirtualBlockBuffer(
    //     0,
    //     global.StorageBufferMeshletsSize,
    //     ssbo_test,
    //     0,
    //     @sizeOf(vertexStruct.Vertex_f3pf3nf2u),
    // );
    // const ssbo_test_vertices = try vulkan.createVirtualBlockBuffer(
    //     0,
    //     global.StorageBufferVerticesSize,
    //     ssbo_test,
    //     global.StorageBufferMeshletsEnd,
    //     @sizeOf(vertexStruct.Meshlet),
    // );
    // const ssbo_test_meshletVertices = try vulkan.createVirtualBlockBuffer(
    //     0,
    //     global.StorageBufferMeshletVerticesSize,
    //     ssbo_test,
    //     global.StorageBufferVerticesEnd,
    //     @sizeOf(u32),
    // );
    // const ssbo_test_meshletTriangles = try vulkan.createVirtualBlockBuffer(
    //     0,
    //     global.StorageBufferMeshletTrianglesSize,
    //     ssbo_test,
    //     global.StorageBufferMeshletVerticesEnd,
    //     @sizeOf(u8),
    // );
    // var meshes = mesh.init(
    //     ssbo_test_meshlets,
    //     ssbo_test_vertices,
    //     ssbo_test_meshletVertices,
    //     ssbo_test_meshletTriangles,
    //     null,
    //     io,
    // );
    // try meshes.loadMeshlet(comptime file.comptimeGetID("Suzanne_0.vtx"), gpa, &vulkan, &commands);

    try vulkan.addWriteDescriptorSetBuffer(
        0,
        vulkan.buffers.getVkBuffer(ubo_test),
        0,
        vulkan.buffers.getBufferSize(ubo_test),
        vulkan.globalFixed2dMVPMatrixDescriptorSet,
        0,
        vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER,
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

    commands.setViewport(viewport_test);
    commands.setScissor(scissor_test);
    {
        const indirect2DBuffers = passes.passMap.get("indirect2D").?.buffer;

        // vertices2D.init(instanceIDsBuffer_t: *opaque {}, indirectDrawCommandBuffer_t: *opaque {}, instanceBuffer_t: *opaque {}, allocator: Allocator, commands: *commands)
        try vertices2D.init(
            indirect2DBuffers[2],
            indirect2DBuffers[0],
            indirect2DBuffers[1],
            gpa,
            &commands,
        );
    }
    defer vertices2D.deinit();

    // global.stopNodeDagDetailPrint = false;
    // global.stopExecuteNodePrint = false;
    // global.storExecuteSequencePrint = false;
    // global.game_end.store(1, .seq_cst);

    // vulkan.logBufferPtr();
    // vulkan.logPipeline();
    var resources: Queue(resource.Resource) = try .init(gpa, io);
    defer resources.deinit();

    const renderStart = std.Io.Timestamp.now(io, .real).toNanoseconds();

    passes.enablePass("indirect2D");
    passes.enablePass("present");

    while (true) {
        {
            const frame = vulkan.totalFrame.load(.seq_cst);
            // _ = frame;

            if (frame == 0) {
                global.stopNodeDagPrint = false;
                global.printDagToDot = true;
                //     passes.enablePass("indirect2D");
                //     passes.enablePass("present");
                //     // testDraw = true;
            }
            if (frame == 2) {
                global.stopNodeDagPrint = true;
                //     passes.disablePass("indirect2D");
                //     passes.disablePass("present");
            }

            {
                const resourceArray = resourceArrays.getReady();

                if (resourceArray) |array| {
                    const slices = array.items;

                    defer resourceArrays.pushEmpty(array);
                    defer array.clearRetainingCapacity();

                    try resources.appendSlice(slices);
                }
            }

            {
                try resources.mutex.lock(io);
                var total = resources.totalSize;
                resources.mutex.unlock(io);

                while (total > 0) : (total -= 1) {
                    const r = resources.popFirst() orelse break;
                    switch (r) {
                        .texture => |texture| {
                            _ = try pTextureSet.createTextureFromResource(
                                io,
                                texture,
                                vulkan,
                                &commands,
                            );
                            std.log.debug("r {s} {d}", .{ @tagName(r), frame });
                        },
                        .position2D => |pos2D| {
                            if (!Handles.handleIsValid(@ptrCast(pos2D.texture))) {
                                try resources.pushLast(r);

                                continue;
                            }
                            try passes.passMap.get("indirect2D").?.useTexture(pos2D.texture, gpa);
                            _ = try vertices2D.addInstance(
                                pos2D.x,
                                pos2D.y,
                                pos2D.width,
                                pos2D.height,
                                pos2D.depth,
                                pos2D.texture,
                                pTextureSet,
                            );
                            std.log.debug("set", .{});
                        },
                        .others => {},
                    }
                }
            }

            const infos = stateBuffering.getReadyBuffer();
            defer stateBuffering.returnReadyBuffer(infos);

            try vertices2D.uploadInstance(&commands, vulkan);
            vulkan.writeCachedDescriptorSetResources();
            try vulkan.waitEndFence();

            try commands.startCommand();
            try commands.addCachedCommand();

            for (infos.items) |value| {
                _ = value;
                // std.log.debug("info {d}", .{value});
            }

            for (args.passes.passes) |*value| {
                if (value.enabled) {
                    try value.addCommand(
                        null,
                        vulkan,
                        pTextureSet,
                        &commands,
                        gpa,
                    );

                    // std.log.debug("pass {s}", .{value.name});
                }
            }

            try commands.addCommandEnd();

            try graphic.executeCommands(&commands);

            vulkan.nextFrame();

            if (global.game_end.load(.seq_cst) == 1) {
                _ = renderStart;
                break;
            }
        }
    }

    // vulkan.logBufferPtr();

    // textureSett.logImagePtr();

    _ = endSemaphore;
    _ = thread_count;
}
