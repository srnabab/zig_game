const std = @import("std");
const Io = std.Io;

const builtin = @import("builtin");
const sdl = @import("sdl").sdl;
const mstd = @import("ms_std");

const upload = @import("renderUpload").upload;

const global = @import("global");
const tracy = @import("tracy");

const renderDebug = @import("renderDebug");
const resource = @import("resource");

const u8pack = @import("u8pack");
const toStr = u8pack.toStr;
const toStr2 = u8pack.toStr2;

const VkStruct = @import("video");
const vk = VkStruct.vk;
const processRender = @import("processRender");
const OneTimeCommand = processRender.oneTimeCommand;
const Commands = processRender.commands;
const textureSet = @import("textureSet");
const shaderStruct = @import("video/shaderStruct.zig");
const vertexStruct = @import("vertexStruct");
const Queue = mstd.Queue;
const Handles = @import("handle");
const vertices2D = @import("vertices");

const PassGroupMapping = @import("passGroupMapping");

const cglm = @import("cglm");

const math = mstd.Math;

const Semaphore = std.Io.Semaphore;

const file = @import("fileSystem");

const mesh = @import("mesh");
const pass = @import("pass");

const meshInstance = @import("meshInstance");

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
    stateBuffering: *global.StateBufferingType,
    vulkan: *VkStruct,
    passes: *pass,
    uctx: *resourceProcess.UserContext,
    instances: *meshInstance,
    externalCommands: *processRender.externalCommands,
    renderQueue: *resource.ReaderQueue,
    updateEventQueue: *global.UpdateEventQueueType,
    renderEventQueue: *global.RenderEventQueueType,
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
    const stateBuffering = args.stateBuffering;
    const pTextureSet = &args.uctx.pTextureSet;
    const vulkan = args.vulkan;
    // const handles = args.handles;
    const passes = args.passes;
    // const meshes = &args.uctx.meshes;
    // const instances = args.instances;
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

    // vulkan.logBufferPtr();

    var graphic = OneTimeCommand.init(io, allocator_t.*, vulkan);
    defer graphic.deinit() catch |err| {
        std.debug.panic("error {s}", .{@errorName(err)});
    };
    {
        var tempDb: file.sqlite3 = null;
        file.init(io, &tempDb);
        defer file.deinit(tempDb);
    }

    try vulkan.createAllPipelinesAdded();

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
    pUIUbo2.lightDirection = cglm.vec3{ 0.0, 0.5, 1.5 };

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

    // vulkan.logBufferPtr();
    // vulkan.logPipeline();

    const renderStart = std.Io.Timestamp.now(io, .real).toNanoseconds();

    while (true) {
        // if (tests) @breakpoint();
        {
            // const frame = vulkan.totalFrame.load(.seq_cst);

            while (args.renderQueue.popFirst()) |v| {
                switch (v.pointer) {
                    inline else => |pt| {
                        defer if (pt.count.fetchSub(1, .seq_cst) == 1) {
                            @TypeOf(pt.child).free(&pt.child, gpa);
                            gpa.destroy(pt);
                        };

                        const field = @TypeOf(pt.child).Parent;
                        if (@hasDecl(field, "renderLoad")) {
                            var uctx: field.Ctx = undefined;
                            const ctxInfo = @typeInfo(field.Ctx);
                            inline for (ctxInfo.@"struct".fields) |f| {
                                @field(uctx, f.name) = &@field(args.uctx, f.name);
                            }

                            const index: u32 = try field.renderLoad(io, gpa, args.vulkan, &commands, &uctx, v.handle, &pt.child, args.updateEventQueue);
                            args.handles.setIndex(v.handle, index);
                        } else {
                            args.handles.setIndex(v.handle, Handles.WaitFill);
                        }
                    },
                }
            }

            // ----------------------------------------------------------------------------------------------------------------------------------------
            {
                var it = args.uctx.layoutQueue.iterate();
                while (it.next()) |p| {
                    const item = p.ptr;
                    const name = item.name;
                    const rdata = args.uctx.renderData.get(name) orelse continue;

                    if (u8pack.eql(toStr("indirect2D"), rdata.pass.name)) {
                        args.updateEventQueue.pushLastC(.{ .createTest2d = .{
                            .pos = item.pos,
                            .scale = item.scale,
                            .rotation = item.rotation,
                            .rdata = name,
                            .handle = item.handle,
                        } }) catch |err| {
                            std.log.err("layout push createTest2d {s}", .{@errorName(err)});
                            continue;
                        };
                    } else if (u8pack.eql(toStr("i_feather"), rdata.pass.name)) {
                        args.updateEventQueue.pushLastC(.{ .createTest3d = .{
                            .pos = item.pos,
                            .scale = item.scale,
                            .rotation = item.rotation,
                            .rdata = name,
                            .handle = item.handle,
                        } }) catch |err| {
                            std.log.err("layout push createTest3d {s}", .{@errorName(err)});
                            continue;
                        };
                    }
                    args.uctx.layoutQueue.remove(p.index);
                }
            }

            while (args.updateEventQueue.popFirst()) |event| {
                switch (event) {
                    .createTest2d => |c| {
                        const rdata = args.uctx.renderData.get(c.rdata) orelse continue;
                        const viewBoundsAndTotalSpriteCount: *ViewBoundsAndTotalSpriteCount = @ptrCast(@alignCast(rdata.pass.userdata));

                        try rdata.pass.useTexture(@ptrCast(rdata.textures[0]), gpa);
                        const textureContent = pTextureSet.getTextureCotent(@ptrCast(rdata.textures[0]));
                        const index = try args.uctx.vertices.addInstance(
                            io,
                            c.pos[0],
                            c.pos[1],
                            c.scale[0] * @as(f32, @floatFromInt(textureContent.source_width)),
                            c.scale[1] * @as(f32, @floatFromInt(textureContent.source_height)),
                            c.pos[2],
                            pTextureSet.getDescriptorSetIndex(@ptrCast(rdata.textures[0])),
                        );
                        viewBoundsAndTotalSpriteCount.totalSpriteCount = args.uctx.vertices.getTotalCount();
                        args.handles.setIndex(c.handle, index);
                    },
                    .createTest3d => |c| {
                        const rdata = args.uctx.renderData.get(c.rdata) orelse unreachable;

                        const ins = try args.uctx.instances1.add(
                            io,
                            null,
                            c.pos,
                            c.scale,
                            c.rotation,
                            c.handle,
                        );
                        const idx1 = Handles.getIndex(@ptrCast(ins)) orelse unreachable;
                        const idx2 = Handles.getIndex(rdata.model.?) orelse unreachable;

                        const tidx = pTextureSet.getDescriptorSetIndex(@ptrCast(rdata.textures[0]));

                        const cs_mesh_drawCount = try args.uctx.passGroupMapping.add(io, rdata.pass.name, .{
                            .instanceID = idx1,
                            .meshID = idx2,
                        });
                        const pU32 = @as(*u32, @ptrCast(@alignCast(rdata.pass.userdata.?)));
                        pU32.* = cs_mesh_drawCount;

                        rdata.pass.setPushConstants(2, @constCast(&std.mem.toBytes(tidx)), 64);
                    },
                }
            }
            args.updateEventQueue.swap();

            const infos = stateBuffering.getReadyBuffer();
            defer stateBuffering.returnReadyBuffer(infos);

            for (infos.items) |value| {
                switch (value) {
                    ._u32 => {
                        var f_v: f32 = @floatFromInt(value._u32);
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
                    },
                    ._2d => |v| {
                        // std.log.debug("({d}, {d})", .{ v.pos[0], v.pos[1] });
                        try args.uctx.vertices.updateInstance(io, v.pos[0], v.pos[1], Handles.getIndex(v.handle) orelse continue);
                    },
                }
            }
            // ----------------------------------------------------------------------------------------------------------------------------------------

            try upload(io, vulkan, passes, pTextureSet, args.uctx, &commands);

            try vulkan.waitEndFence();

            try commands.startCommand();
            try externalCommands.addExternalCommand(&commands);
            try commands.addCachedCommand();

            const zone2 = tracy.initZone(@src(), .{ .name = "pass add" });
            for (args.passes.passes) |*value| {
                if (value.enabled > 0) {
                    value.addCommand(
                        vulkan,
                        pTextureSet,
                        &commands,
                        gpa,
                    ) catch |err| {
                        std.log.err("pass {f} {s}", .{ value.name, @errorName(err) });
                        renderDebug.printToDot();
                        renderDebug.printPassInfo(vulkan, value);

                        return err;
                    };
                }
            }
            zone2.deinit();

            try commands.addCommandEnd();

            vulkan.writeCachedDescriptorSetResources();

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
