const std = @import("std");
const builtin = @import("builtin");
const sdl = @import("sdl").sdl;
const mstd = @import("ms_std");

const global = @import("global");
const tracy = @import("tracy");

const renderDebug = @import("renderDebug");

const VkStruct = @import("video");
const vk = VkStruct.vk;
const processRender = @import("processRender");
const OneTimeCommand = processRender.oneTimeCommand;
const Commands = processRender.commands;
const textureSet = @import("textureSet");
const shaderStruct = @import("video/shaderStruct.zig");
const vertexStruct = @import("vertexStruct");
const resource = @import("resource");
const Queue = mstd.Queue;
const Handles = @import("handle");
const vertices2D = @import("video/indirect2D/vertices.zig");

const PassGroupMapping = @import("passGroupMapping");

const cglm = @import("cglm");

const math = mstd.Math;

const Semaphore = std.Io.Semaphore;

const file = @import("fileSystem");

const mesh = @import("mesh");
const pass = @import("pass");

const instance = @import("instance");

const resourceProcess = @import("resourceProcess");

const ViewBoundsAndTotalSpriteCount = @import("setPass").ViewBoundsAndTotalSpriteCount;

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
    vulkan: *VkStruct,
    passes: pass,
    uctx: *resourceProcess.UserContext,
    instances: *instance,
    externalCommands: *processRender.externalCommands,
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
    const pTextureSet = &args.uctx.pTextureSet;
    const vulkan = args.vulkan;
    // const handles = args.handles;
    var passes = args.passes;
    const meshes = &args.uctx.meshes;
    const instances = args.instances;
    const externalCommands = args.externalCommands;

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
    renderDebug.init(io, &commands);

    for (passes.passes) |*value| {
        try value.init(null, vulkan, &commands, allocator_t.*);
    }

    vulkan.logBufferPtr();

    var graphic = OneTimeCommand.init(io, allocator_t.*, vulkan);
    defer graphic.deinit() catch |err| {
        std.debug.panic("error {s}", .{@errorName(err)});
    };
    {
        var tempDb: file.sqlite3 = null;
        file.init(io, &tempDb);
        defer file.deinit(tempDb);

        _ = try pTextureSet.createImageTexture(
            io,
            comptime file.comptimeGetID("non_exist.png"),
            vulkan,
            externalCommands,
            tempDb,
        );
    }

    try vulkan.createAllPipelinesAdded();

    var passGroupMapping = PassGroupMapping.init(gpa);
    defer passGroupMapping.deinit();

    const ubo_test = try vulkan.createBufferByUsage(
        @sizeOf(shaderStruct.UniformBufferObject),
        0,
        .uniform,
        false,
        null,
    );
    var pUIUbo: shaderStruct.UniformBufferObject = undefined;
    const ubo = vulkan.buffers.getBufferContent(ubo_test);

    const ubo_test2 = try vulkan.createBufferByUsage(
        @sizeOf(shaderStruct.UniformBufferObjectCamera),
        0,
        .uniform,
        false,
        null,
    );
    var pUIUbo2: shaderStruct.UniformBufferObjectCamera = undefined;
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

    var eye2 = cglm.vec3{ 1.0, 1.0, 1.0 };
    var center2 = cglm.vec3{ 0.0, 0.0, 0.0 };
    var up2 = cglm.vec3{ 0.0, 0.0, 1.0 };
    cglm.glmc_lookat(
        &eye2,
        &center2,
        &up2,
        &pUIUbo2.view,
    );
    cglm.glmc_perspective(std.math.rad_per_deg * 60.0, (aspect / 300) * VIEW_SCALE, 0.1, 100.0, &pUIUbo2.proj);
    // pUIUbo2.proj[1][1] *= -1;
    pUIUbo2.cameraPos = eye2;
    const pData2 = @as(*shaderStruct.UniformBufferObjectCamera, @ptrCast(@alignCast(ubo2.pMappedData)));
    pData2.* = pUIUbo2;

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

    std.log.debug("f3pf3nf2u size {d}", .{@sizeOf(vertexStruct.Vertex_f3pf3nf2u)});
    std.log.debug("f3pf3nf4tf2u size {d}", .{@sizeOf(vertexStruct.Vertex_f3pf3nf4tf2u)});

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

    var viewBoundsAndTotalSpriteCount = ViewBoundsAndTotalSpriteCount{
        .viewBounds = .{ 0.0, 0.0, 0.0, 0.0 },
        .totalSpriteCount = 0,
    };

    var cs_mesh_drawCount: u32 = 0;
    passes.passMap.get("c_command_prefix_sum").?.setUserdata(&cs_mesh_drawCount);
    passes.passMap.get("ic_task").?.setUserdata(&cs_mesh_drawCount);

    // global.stopExecuteNodePrint = false;
    // global.game_end.store(1, .seq_cst);

    vulkan.logBufferPtr();
    // vulkan.logPipeline();
    var resources: Queue(resource.Resource) = try .init(gpa, io);
    defer resources.deinit();

    const renderStart = std.Io.Timestamp.now(io, .real).toNanoseconds();

    passes.passMap.get("indirectCompute").?.setUserdata(@ptrCast(&viewBoundsAndTotalSpriteCount));

    passes.enablePass("indirectCompute");
    passes.enablePass("indirect2D");
    passes.enablePass("present");

    // var testTime: u32 = 0;
    // var tests = false;

    while (true) {
        // if (tests) @breakpoint();
        {
            const frame = vulkan.totalFrame.load(.seq_cst);
            // @breakpoint();
            // std.log.debug("frame {d}", .{frame});
            // _ = frame;

            if (frame == 0) {
                // global.stopNodeDagPrint = false;
                // global.printDagToDot = true;
                // global.game_end.store(1, .seq_cst);
                // global.stopNodeDagDetailPrint = false;
                // global.storExecuteSequencePrint = false;
                //     passes.enablePass("indirect2D");
                //     passes.enablePass("present");
                //     // testDraw = true;
            }
            if (frame == 1) {
                // global.game_end.store(1, .seq_cst);
                // global.stopNodeDagPrint = true;
                // global.storExecuteSequencePrint = true;
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
                            // std.log.debug("set", .{});
                        },
                        .instance => |i| {
                            const texIdx = if (i.texture) |t|
                                pTextureSet.getDescriptorSetIndex(t)
                            else
                                0;

                            _ = try instances.add(
                                texIdx,
                                i.sampler,
                                i.pos,
                                i.rotation,
                                i.scale,
                                i.handle,
                            );
                        },
                        .meshInstance => |mi| {
                            const idx1 = Handles.getIndex(@ptrCast(mi.instance)) orelse {
                                try resources.pushLast(r);
                                continue;
                            };
                            const idx2 = Handles.getIndex(@ptrCast(mi.mesh)) orelse {
                                try resources.pushLast(r);
                                continue;
                            };
                            const tidx = pTextureSet.getDescriptorSetIndex(@ptrCast(resource.getResourceHandle(file.getID("feather_lut.ktx2"))));

                            cs_mesh_drawCount = try passGroupMapping.add(mi.passName, .{
                                .instanceID = idx1,
                                .meshID = idx2,
                            });
                            std.log.debug("aaaaaaa", .{});
                            // passes.enablePass(mi.passName);
                            passes.passMap.get("iv_feather").?.setPushConstants(@constCast(&std.mem.toBytes(tidx)), 64);
                            passes.enablePass("c_command_prefix_sum");
                            passes.enablePass("ic_task");
                            passes.enablePass("iv_feather");
                            // global.storExecuteSequencePrint = false;
                            // global.stopNodeDagPrint = false;
                            // global.printDagToDot = true;
                            // std.log.debug("name {s}", .{mi.passName});
                        },
                        .others => {},
                    }
                }
            }

            const infos = stateBuffering.getReadyBuffer();
            defer stateBuffering.returnReadyBuffer(infos);

            try meshes.upload(&commands, passes.passMap.get("ic_task").?.buffer[4]);
            try instances.upload(&commands, vulkan, passes.passMap.get("ic_task").?.buffer[3]);
            try passGroupMapping.upload(
                vulkan,
                &commands,
                "ic_task",
                passes.passMap.get("ic_task").?.buffer[1],
                passes.passMap.get("ic_task").?.buffer[2],
            );
            try vertices2D.uploadInstance(&commands, vulkan);

            viewBoundsAndTotalSpriteCount.totalSpriteCount = vertices2D.getTotalCount();
            viewBoundsAndTotalSpriteCount.viewBounds = .{ -300, 300, -400, 400 };

            try vulkan.waitEndFence();

            try commands.startCommand();
            try externalCommands.addExternalCommand(&commands);
            try commands.addCachedCommand();

            for (infos.items) |value| {
                var f_v: f32 = @floatFromInt(value);
                f_v *= 0.1;
                eye2 = cglm.vec3{ 0.0, -f_v, 0.0 };
                pUIUbo2.cameraPos = eye2;

                cglm.glmc_lookat(
                    &eye2,
                    &center2,
                    &up2,
                    &pUIUbo2.view,
                );
                // _ = value;
                // std.log.debug("info {d}", .{value});
                const pData3 = @as(*shaderStruct.UniformBufferObjectCamera, @ptrCast(@alignCast(ubo2.pMappedData)));
                pData3.* = pUIUbo2;
            }

            const zone2 = tracy.initZone(@src(), .{ .name = "pass add" });
            for (args.passes.passes) |*value| {
                if (value.enabled > 0) {
                    // renderDebug.printPassInfo(vulkan, value);
                    value.addCommand(
                        value.userdata,
                        vulkan,
                        pTextureSet,
                        &commands,
                        gpa,
                    ) catch |err| {
                        std.log.err("pass {s} {s}", .{ value.name, @errorName(err) });
                        renderDebug.printToDot();
                        renderDebug.printPassInfo(vulkan, value);

                        return err;
                    };

                    // std.log.debug("pass {s}", .{value.name});
                }
            }
            zone2.deinit();

            try commands.addCommandEnd();
            vulkan.writeCachedDescriptorSetResources();
            // renderDebug.printAllInfoToTxt();

            try graphic.executeCommands(&commands);

            vulkan.nextFrame();

            if (global.game_end.load(.seq_cst) == 1) {
                _ = renderStart;
                break;
            }
        }
    }

    vulkan.logBufferPtr();

    // textureSett.logImagePtr();

    _ = endSemaphore;
    _ = thread_count;
}
