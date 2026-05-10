const std = @import("std");
const builtin = @import("builtin");

const ECS = @import("ECS");
const process = @import("processRender");
const global = @import("global");
const tracy = @import("tracy");
const sdl = @import("sdl").sdl;

const input = @import("input");
const inputFunc = @import("input/inputFunc.zig");

const textureSet = @import("textureSet");
const VkStruct = @import("video");
const ringBuffer = @import("ringBuffer");

const stb_image = @import("stb_image");

const file = @import("fileSystem");
const resource = @import("resource");
const Handles = global.Handles;
const Handle = Handles.Handle;

fn MutexArray(T: type) type {
    return struct {
        const Self = @This();

        mutex: std.Io.Mutex,
        array: std.array_list.Managed(T),

        pub fn init(gpa: std.mem.Allocator) Self {
            return .{
                .mutex = .init,
                .array = .init(gpa),
            };
        }

        pub fn deinit(self: *Self) void {
            self.array.deinit();
        }
    };
}

const sqlite3 = ?*file.sqlite.sqlite3;
const DrawableC = ECS.CompentPool(process.Drawable);
const Io = std.Io;
const ResourcesQueue = MutexArray(resource.Resource);

const Name_FileType_Handle = struct {
    name: []u8,
    fileType: file.FileType,
    handle: Handle,
};

const NameQueue = MutexArray(Name_FileType_Handle);
const DataBaseHandleArrayType = ringBuffer.RingBuffer(sqlite3, 8);

const ResourceThreadArgs = struct {
    io: std.Io,
    group: *std.Io.Group,
    gpa: std.mem.Allocator,
    resourceArray: *ResourcesQueue,
    nameArray: *NameQueue,
    handleArray: *DataBaseHandleArrayType,
    handleMutex: *Io.Mutex,
    handles: *global.HandlesType,
    vulkan: *VkStruct,
};

pub const Args = struct {
    io: std.Io,
    gpa: std.mem.Allocator,
    thread_count: usize,
    pInput: *input,
    resourceArrays: *global.ResourceArrayType,
    stateBuffering: *global.StateBufferingType,
    handles: *global.HandlesType,
    vulkan: *VkStruct,
};

const inputProcessInterval = std.time.ns_per_ms * 5;

pub fn update_thread_func(args: Args) !void {
    const io = args.io;
    const gpa = args.gpa;
    const thread_count = args.thread_count;
    const pInput = args.pInput;
    const resourceArrays = args.resourceArrays;
    const stateBuffering = args.stateBuffering;
    const handles = args.handles;

    var tracyAllocator = tracy.TracingAllocator.initNamed("pool", gpa);
    defer tracyAllocator.deinit();
    var taa = tracyAllocator.allocator();
    const allocator_t = &taa;

    tracy.setThreadName("update");
    defer tracy.message("update exit");

    const zone = tracy.initZone(@src(), .{ .name = "update" });
    defer zone.deinit();

    var inputFunc1 = try inputFunc.init(allocator_t.*);
    defer inputFunc1.deinit();

    var inputTrigger1 = try inputFunc1.createInputTrigger();
    defer inputTrigger1.deinit();

    const exit = try inputFunc1.registerAction(
        inputTrigger1,
        "exit",
        sdl.SDL_SCANCODE_ESCAPE,
        null,
        null,
        true,
    );

    const test_A = try inputFunc1.registerAction(
        inputTrigger1,
        "test_A",
        sdl.SDL_SCANCODE_A,
        null,
        null,
        false,
    );

    var resourceGroup: Io.Group = .init;

    var rwSqlite: sqlite3 = null;
    var mainRoSqlite: sqlite3 = null;
    var handleMutex: Io.Mutex = .init;
    var databaseHandleArray: DataBaseHandleArrayType = .init();
    const dbs = try file.initManyDb(8, &rwSqlite, gpa);
    defer file.deinitManyDB(rwSqlite, dbs, gpa);

    mainRoSqlite = dbs[0];
    for (dbs[1..]) |value| {
        _ = databaseHandleArray.push(value);
    }

    var resourceArray: ResourcesQueue = .init(gpa);
    defer resourceArray.deinit();

    var nameArray: NameQueue = .init(gpa);
    defer nameArray.deinit();

    const resourceArg = ResourceThreadArgs{
        .io = io,
        .group = &resourceGroup,
        .gpa = gpa,
        .resourceArray = &resourceArray,
        .nameArray = &nameArray,
        .handleArray = &databaseHandleArray,
        .handleMutex = &handleMutex,
        .handles = handles,
        .vulkan = args.vulkan,
    };

    for (0..7) |_| {
        try resourceGroup.concurrent(io, processResource, .{resourceArg});
    }
    defer resourceGroup.cancel(io);

    // var resourceValue: u32 = 0;

    // var stateBufferValue: u32 = 0;

    var sceneChanged = true;

    var lastMouseX: f32 = 0;
    var lastMouseY: f32 = 0;

    var inputs: []input.Input = &.{};
    var lastTimestamp = sdl.SDL_GetTicksNS();

    var accumulateTime: u64 = 0;

    out: while (true) {
        {
            if (accumulateTime > inputProcessInterval) {
                defer accumulateTime -= inputProcessInterval;

                inputs = try pInput.getCurrentInput(io);

                for (inputs) |*value| {
                    const r = inputTrigger1.set(value);
                    if (r) continue;

                    switch (value.*) {
                        .mouse => |mouse| {
                            lastMouseX = mouse.x;
                            lastMouseY = mouse.y;
                        },
                        else => {},
                    }
                }

                try pInput.releaseCurrentInput(io, inputs);
                inputs = &.{};
            }

            if (test_A.down) {
                // sceneChanged = true;
            }

            if (sceneChanged) {
                sceneChanged = false;

                // std.log.debug("update: idx {d}", .{resourceArrayIndex});
                const boxPng = try readResource(
                    io,
                    gpa,
                    handles,
                    &nameArray,
                    mainRoSqlite,
                    "box.png",
                );
                _ = boxPng;

                // resourceArray.mutex.lock(io);
                // defer resourceArray.mutex.unlock(io);
                // const ptr = try resourceArray.array.addOne();
                // ptr.* = resourceValue;

                // resourceValue += 1;
            }

            {
                resourceArray.mutex.lockUncancelable(io);
                defer resourceArray.mutex.unlock(io);
                if (resourceArray.array.items.len > 0) {
                    const array = resourceArrays.getEmpty();

                    if (array) |a| {
                        try a.appendSlice(resourceArray.array.items);
                        resourceArrays.pushReady(a);
                        resourceArray.array.clearRetainingCapacity();
                    }
                }
            }

            const infos = stateBuffering.getWriteBuffer();
            defer stateBuffering.returnWriteBuffer(infos);

            // try infos.append(stateBufferValue);
            // stateBufferValue += 1;

            accumulateTime += sdl.SDL_GetTicksNS() - lastTimestamp;

            lastTimestamp = sdl.SDL_GetTicksNS();

            if (exit.down) {
                endGame();
            }

            if (global.game_end.load(.seq_cst) == 1) {
                break :out;
            }
        }
    }

    _ = thread_count;
}

fn endGame() void {
    global.game_end.store(1, .seq_cst);
}

fn readResource(io: Io, gpa: std.mem.Allocator, handles: *global.HandlesType, nameArray: *NameQueue, mainSqlite: sqlite3, fileName: []const u8) !?Handle {
    const fileType = file.getFileType(fileName, mainSqlite) catch |err| {
        std.log.err("{s}", .{@errorName(err)});
        return null;
    };

    var handleType: Handles.ResourceType = .others;
    switch (fileType) {
        .PNG => {
            handleType = .texture;
        },
        .UNKNOWN => {},
        else => return null,
    }

    const handle_ = handles.createHandle(Handles.WaitFill, handleType);

    try nameArray.mutex.lock(io);
    defer nameArray.mutex.unlock(io);

    const name = try gpa.dupe(u8, fileName);
    try nameArray.array.append(.{
        .fileType = fileType,
        .handle = handle_,
        .name = name,
    });

    return handle_;
}

fn processResource(args: ResourceThreadArgs) Io.Cancelable!void {
    const io = args.io;
    const gpa = args.gpa;
    const nameArray = args.nameArray;
    const handleMutex = args.handleMutex;
    const handleArray = args.handleArray;
    const resourceArray = args.resourceArray;
    const vulkan = args.vulkan;

    while (true) {
        try nameArray.mutex.lock(io);
        const pack_ = nameArray.array.pop();
        nameArray.mutex.unlock(io);

        if (pack_) |pack| {
            errdefer args.handles.destroyHandle(pack.handle);
            defer gpa.free(pack.name);

            var sqlite: ?sqlite3 = null;
            while (sqlite == null) {
                try handleMutex.lock(io);
                defer handleMutex.unlock(io);
                sqlite = handleArray.pop();
                try std.Io.sleep(io, .fromMilliseconds(1), .real);
            }

            switch (pack.fileType) {
                .UNKNOWN => {
                    const fileID = file.getID(pack.name);
                    const f = file.getFile(io, fileID, sqlite.?) catch |err| {
                        std.log.err("{s}", .{@errorName(err)});
                        continue;
                    };
                    defer f.close(io);

                    const stat = f.stat(io) catch |err| {
                        std.log.err("{s}", .{@errorName(err)});
                        continue;
                    };

                    var buffer = [_]u8{0} ** 8;
                    var reader = f.reader(io, &buffer);
                    reader.seekTo(0) catch continue;

                    const content = reader.interface.readAlloc(gpa, stat.size) catch |err| {
                        std.log.err("{s}", .{@errorName(err)});
                        continue;
                    };

                    {
                        try resourceArray.mutex.lock(io);
                        defer resourceArray.mutex.unlock(io);
                        const ptr = resourceArray.array.addOne() catch |err| {
                            std.log.err("{s}", .{@errorName(err)});
                            continue;
                        };
                        ptr.* = .{ .others = .{
                            .fileID = @intCast(fileID),
                            .mem = content,
                            .handle = pack.handle,
                        } };
                    }
                },
                .PNG => {
                    const fileID = file.getID(pack.name);
                    const img = file.getImageLoadParam(io, fileID, sqlite.?) catch |err| {
                        std.log.err("{s}", .{@errorName(err)});
                        continue;
                    };
                    defer img.file.close(io);

                    const imgStat = img.file.stat(io) catch |err| {
                        std.log.err("{s}", .{@errorName(err)});
                        continue;
                    };

                    var buffer = [_]u8{0} ** 8;
                    var reader = img.file.reader(io, &buffer);
                    reader.seekTo(0) catch continue;

                    const fileMem = reader.interface.readAlloc(gpa, imgStat.size) catch |err| {
                        std.log.err("{s}", .{@errorName(err)});
                        continue;
                    };
                    defer gpa.free(fileMem);

                    var imgWidth: c_int = 0;
                    var imgHeight: c_int = 0;
                    var channel: c_int = 0;

                    const imageMem = stb_image.stbi_load_from_memory(
                        @ptrCast(fileMem.ptr),
                        @intCast(fileMem.len),
                        @ptrCast(&imgWidth),
                        @ptrCast(&imgHeight),
                        @ptrCast(&channel),
                        stb_image.STBI_rgb_alpha,
                    );
                    const pixelSize: u64 = @intCast(@sizeOf(u8) * imgWidth * imgHeight * channel);

                    const stagingBuffer = vulkan.createBufferByUsage(pixelSize, 0, .staging, false) catch |err| {
                        std.log.err("{s}", .{@errorName(err)});
                        continue;
                    };
                    errdefer vulkan.destroyBuffer(stagingBuffer);

                    vulkan.buffers.copyDataToMapped(stagingBuffer, u8, imageMem[0..pixelSize]);

                    const image = vulkan.createImage2D(
                        @intCast(imgWidth),
                        @intCast(imgHeight),
                        img.image.format,
                        img.image.tiling,
                        img.image.usage,
                    ) catch |err| {
                        std.log.err("{s}", .{@errorName(err)});
                        continue;
                    };
                    errdefer vulkan.destroyImage(image);

                    const imageView = vulkan.createImageView2D(image.vkImage, img.image.format) catch |err| {
                        std.log.err("{s}", .{@errorName(err)});
                        continue;
                    };

                    {
                        try resourceArray.mutex.lock(io);
                        defer resourceArray.mutex.unlock(io);
                        const ptr = resourceArray.array.addOne() catch |err| {
                            std.log.err("{s}", .{@errorName(err)});
                            continue;
                        };
                        ptr.* = .{ .texture = .{
                            .width = @intCast(imgWidth),
                            .height = @intCast(imgHeight),
                            .fileID = @intCast(fileID),
                            .vkImage = image.vkImage,
                            .vkImageView = imageView,
                            .allocation = image.allocation,
                            .staginfBuffer = stagingBuffer,
                            .format = img.image.format,
                            .handle = pack.handle,
                        } };
                    }
                },
                else => continue,
            }

            var pushSuccess = false;
            while (pushSuccess == false) {
                {
                    try handleMutex.lock(io);
                    defer handleMutex.unlock(io);
                    pushSuccess = handleArray.push(sqlite.?);
                    try std.Io.sleep(io, .fromMilliseconds(1), .real);
                }
            }
        }

        try std.Io.sleep(io, .fromMilliseconds(1), .real);
    }
}
