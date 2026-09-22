const std = @import("std");
const Io = std.Io;

const builtin = @import("builtin");
const sdl = @import("sdl").sdl;
const mstd = @import("ms_std");
const Queue = mstd.Queue;

const upload = @import("renderUpload").upload;
const addEvent = @import("renderEventAdd").addEvent;

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
const Handles = @import("handle");
const setUbo = @import("setUbo");

const PassGroupMapping = @import("passGroupMapping");

const cglm = @import("cglm");

const math = mstd.Math;

const Semaphore = std.Io.Semaphore;

const file = @import("fileSystem");

const mesh = @import("mesh");
const pass = @import("pass");

const meshInstance = @import("meshInstance");

const resourceProcess = @import("resourceProcess");

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

    setUbo.initUbo(vulkan);

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

    var pUIUbo2: shaderStruct.UniformBufferObjectCamera align(16) = undefined;

    const aspect2: f32 = 1.0 * (@as(f32, @floatFromInt(vulkan.windowHeight))) / 2;
    const aspect: f32 = (@as(f32, @floatFromInt(vulkan.windowWidth)) / @as(f32, @floatFromInt(vulkan.windowHeight))) * aspect2;
    const VIEW_SCALE = 1.0;
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

    std.log.debug("f3pf3nf2u size {d}", .{@sizeOf(vertexStruct.Vertex_f3pf3nf2u)});
    std.log.debug("f3pf3nf4tf2u size {d}", .{@sizeOf(vertexStruct.Vertex_f3pf3nf4tf2u)});

    // vulkan.logBufferPtr();
    // vulkan.logPipeline();
    try initWriteDescriptorSetUbos(vulkan);

    const renderStart = std.Io.Timestamp.now(io, .real).toNanoseconds();

    while (true) {
        // if (tests) @breakpoint();

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

                        const index: u32 = try field.renderLoad(io, gpa, args.vulkan, &commands, &uctx, v.handle, &pt.child);
                        args.handles.setIndex(v.handle, index);
                    } else {
                        args.handles.setIndex(v.handle, Handles.WaitFill);
                    }
                },
            }
        }

        try addEvent(args.uctx, args.updateEventQueue);

        var u_it = args.updateEventQueue.iterateC();
        while (u_it.next()) |event| {
            switch (event.ptr.*) {
                inline else => |c| {
                    c.process(io, gpa, args.handles, args.uctx) catch {
                        continue;
                    };
                },
            }
            args.updateEventQueue.removeAt(event.index);
        }
        args.updateEventQueue.swap();

        const infos = stateBuffering.getReadyBuffer();
        defer stateBuffering.returnReadyBuffer(infos);

        // ----------------------------------------------------------------------------------------------------------------------------------------
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

                    vulkan.copyToUbo(&pUIUbo2, toStr("camera3d"), ._3d);
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

    // vulkan.logBufferPtr();

    // textureSett.logImagePtr();

    _ = endSemaphore;
    _ = thread_count;
}

fn initWriteDescriptorSetUbos(vulkan: *VkStruct) !void {
    const ubo_ui = vulkan.buffers.getBuffer(toStr("ubo_ui"));
    const ubo_2d = vulkan.buffers.getBuffer(toStr("ubo_2d"));
    const ubo_3d = vulkan.buffers.getBuffer(toStr("ubo_3d"));

    if (ubo_ui) |b| {
        try vulkan.addWriteDescriptorSetBuffer(
            0,
            vulkan.buffers.getVkBuffer(b),
            0,
            vk.VK_WHOLE_SIZE,
            vulkan.globalFixed2dMVPMatrixDescriptorSet,
            0,
            vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
        );
    }

    if (ubo_2d) |b| {
        try vulkan.addWriteDescriptorSetBuffer(
            0,
            vulkan.buffers.getVkBuffer(b),
            0,
            vk.VK_WHOLE_SIZE,
            vulkan.global2dMVPMatrixDescriptorSet,
            0,
            vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
        );
    }

    if (ubo_3d) |b| {
        try vulkan.addWriteDescriptorSetBuffer(
            0,
            vulkan.buffers.getVkBuffer(b),
            0,
            vk.VK_WHOLE_SIZE,
            vulkan.global3dMVPMatrixDescriptorSet,
            0,
            vk.VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC,
        );
    }

    vulkan.writeCachedDescriptorSetResources();
}
