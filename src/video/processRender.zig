const std = @import("std");
const Thread = std.Thread;
const Atomic = std.atomic;
pub const drawC = @import("drawCommand.zig");
// const drawCProcess = @import("drawCommandProcess.zig");
const texture = @import("textureSet");
const vk = @import("vulkan").vulkan;
const VkStruct = @import("video");
const Queue = @import("queue").Queue;
const global = @import("global");
const tracy = @import("tracy");
const math = @import("math");
const uniqueArrayList = @import("uniqueArrayList").UniqueArrayList;
const rendering = @import("rendering");

var mutex = Thread.Mutex{};

const twoQueueNode = struct {
    a: ?*QueueNode = null,
    b: ?*QueueNode = null,
};

pub const Drawable = struct {
    draw: bool,
    texture_t: *texture,
    time: i128,
};

const SecondaryCommandBuffers = struct {
    const Self = @This();

    commandPool: vk.VkCommandPool,
    available: []i32,
    availableCount: u32 = 0,
    commandBuffers: []vk.VkCommandBuffer,
    count: u32 = 0,

    pub fn initCapacity(allocator: std.mem.Allocator, commandPooll: vk.VkCommandPool, size: usize) !Self {
        const bSlice = try allocator.alloc(i32, size);
        @memset(bSlice, -1);
        const cSlice = try allocator.alloc(vk.VkCommandBuffer, size);
        @memset(cSlice, null);

        return .{
            .commandPool = commandPooll,
            .available = bSlice,
            .commandBuffers = cSlice,
        };
    }

    pub fn getFreeBuffer(self: *Self, vulkan: *VkStruct) !vk.VkCommandBuffer {
        if (self.commandPool) |pool| {
            if (self.available[0] > 0) {
                const idx: usize = @intCast(self.available[0]);
                self.available[0] = self.available[self.availableCount - 1];
                self.available[self.availableCount - 1] = 0;
                self.availableCount -= 1;

                return self.commandBuffers[idx];
            } else {
                if (self.count == self.commandBuffers.len) {
                    return error.OutOfCapacity;
                }

                var cb: vk.VkCommandBuffer = null;

                try vulkan._createCommandBuffers(null, pool, vk.VK_COMMAND_BUFFER_LEVEL_SECONDARY, 1, @ptrCast(&cb));

                self.commandBuffers[self.count] = cb;
                self.count += 1;

                return cb;
            }
        } else {
            return error.InvalidCommandPool;
        }
    }

    pub fn reset(self: *Self) void {
        self.availableCount = self.count;
        for (self.available, 0..) |*item, idx| {
            item.* = @intCast(idx);
        }
    }

    /// not free commandBuffer
    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        allocator.free(self.available);
        for (0..self.count) |i| {
            _ = i;
            // maybe free commandBuffer
        }
        allocator.free(self.commandBuffers);
    }
};

const CommandPool = struct {
    const Self = @This();

    commandPool: vk.VkCommandPool,
    primaryCommandBuffer: [2]vk.VkCommandBuffer,
    secondaryCommandBuffers: ?SecondaryCommandBuffers = null,

    pub fn initPrimary(commandPooll: vk.VkCommandPool, vulkan: *VkStruct) !Self {
        var cbs: [2]vk.VkCommandBuffer = undefined;
        try vulkan._createCommandBuffers(null, commandPooll, vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY, 2, @ptrCast(&cbs));

        return .{
            .commandPool = commandPooll,
            .primaryCommandBuffer = cbs,
        };
    }

    pub fn initWithSecondary(allocator: std.mem.Allocator, commandPooll: vk.VkCommandPool, secondarySize: usize, vulkan: *VkStruct) !Self {
        var cbs: [2]vk.VkCommandBuffer = undefined;
        try vulkan._createCommandBuffers(null, commandPooll, vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY, 2, @ptrCast(&cbs));
        return .{
            .commandPool = commandPooll,
            .primaryCommandBuffer = cbs,
            .secondaryCommandBuffers = try .initCapacity(allocator, commandPooll, secondarySize),
        };
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        if (self.secondaryCommandBuffers) |*cbs| {
            cbs.deinit(allocator);
        }
    }
};

const CommandPools = struct {
    const Self = @This();

    commandPools: [3]?CommandPool = [_]?CommandPool{null} ** 3,
    secondarySizes: [3]u16,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, graphicSecondarySize: usize, transferSecondarySize: usize, computeSecondarySize: usize) Self {
        return .{
            .allocator = allocator,
            .secondarySizes = [3]u16{ @intCast(graphicSecondarySize), @intCast(transferSecondarySize), @intCast(computeSecondarySize) },
        };
    }

    pub fn getPrimaryCommandBuffer(self: *Self, kind: VkStruct.CommandPoolType, index: u32, vulkan: *VkStruct) !vk.VkCommandBuffer {
        const zone = tracy.initZone(@src(), .{ .name = "get primary command buffer" });
        defer zone.deinit();

        const idx: u32 = switch (kind) {
            .graphic => 0,
            .transfer => 1,
            .compute => 2,
            .present, .init => unreachable,
        };
        if (self.commandPools[idx]) |p| {
            return p.primaryCommandBuffer[index];
        } else {
            var commandPool: vk.VkCommandPool = null;
            try vulkan._createCommandPool(null, kind, vk.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT | vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT, @ptrCast(&commandPool));
            self.commandPools[idx] = if (self.secondarySizes[idx] > 0)
                try .initWithSecondary(self.allocator, commandPool, self.secondarySizes[idx], vulkan)
            else
                try .initPrimary(commandPool, vulkan);

            return self.commandPools[idx].?.primaryCommandBuffer[index];
        }
    }

    pub fn getSecondaryCommandBuffer(self: *Self, kind: VkStruct.CommandPoolType, vulkan: *VkStruct) !vk.VkCommandBuffer {
        const zone = tracy.initZone(@src(), .{ .name = "get secondary command buffer" });
        defer zone.deinit();

        const idx: u32 = switch (kind) {
            .graphic => 0,
            .transfer => 1,
            .compute => 2,
            .present, .init => unreachable,
        };

        if (self.commandPools[idx]) |*p| {
            if (self.secondarySizes[idx] > 0)
                return p.secondaryCommandBuffers.?.getFreeBuffer(vulkan);
        } else {
            var commandPool: vk.VkCommandPool = null;
            try vulkan._createCommandPool(null, kind, vk.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT, @ptrCast(&commandPool));
            self.commandPools[idx] = if (self.secondarySizes[idx] > 0)
                try .initWithSecondary(self.allocator, commandPool, self.secondarySizes[idx], vulkan)
            else
                try .initPrimary(commandPool, vulkan);

            if (self.secondarySizes[idx] > 0)
                return self.commandPools[idx].?.secondaryCommandBuffers.?.getFreeBuffer(vulkan);
        }

        return error.NoSecondaryCommandBuffer;
    }

    pub fn markSecondaryCommandBufferFree(self: *Self) void {
        const zone = tracy.initZone(@src(), .{ .name = "mark secondary command buffer free" });
        defer zone.deinit();

        for (0..self.commandPools.len) |i| {
            if (self.commandPools[i]) |*p| {
                if (p.secondaryCommandBuffers) |*cb| {
                    cb.reset();
                }
            }
        }
    }

    pub fn deinit(self: *Self, vulkan: *VkStruct) void {
        for (0..self.commandPools.len) |i| {
            if (self.commandPools[i] != null) {
                self.commandPools[i].?.deinit(self.allocator);
                vulkan.destroyCommandPool(self.commandPools[i].?.commandPool);
            }
        }
    }
};

fn SpecialThreadPool(maxThreads: u32) type {
    return struct {
        const Self = @This();

        threads: [maxThreads]?Thread = [_]?Thread{null} ** maxThreads,
        threadCount: u32 = 0,
        freeList: [maxThreads]i32 = undefined,
        freeCount: u32 = 0,
        info: [maxThreads]?ThreadContext = [_]?ThreadContext{null} ** maxThreads,
        allocator: std.mem.Allocator,
        mutex: Thread.Mutex = .{},

        pub fn init(allocator: std.mem.Allocator) Self {
            var fl: [maxThreads]i32 = undefined;
            for (0..fl.len) |i| {
                fl[i] = -1;
            }
            return .{
                .freeList = fl,
                .allocator = allocator,
            };
        }

        pub fn getFreeThread(self: *Self, commandBufferQueue: commandBufferDAG, commandPoolType: VkStruct.CommandPoolType, vulkan: *VkStruct) !*ThreadContext {
            const zone = tracy.initZone(@src(), .{ .name = "get free thread" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.freeCount > 0) {
                const idx: usize = @intCast(self.freeList[0]);
                self.freeList[0] = self.freeList[self.freeCount - 1];
                self.freeList[self.freeCount - 1] = -1;
                self.freeCount -= 1;

                self.info[idx].?.commandPoolType = commandPoolType;

                return &self.info[idx].?;
            } else {
                if (self.threadCount == maxThreads) {
                    return error.OutOfCapacity;
                }

                var tempTaskQueue: Queue(ThreadContext.task) = undefined;
                tempTaskQueue.init(self.allocator);
                self.info[self.threadCount] = ThreadContext{
                    .semaphore = .{},
                    .taskQueue = tempTaskQueue,
                    .commandPool = .init(self.allocator, 4, 2, 2),
                    .mutex = .{},
                    .commandBuffers = commandBufferQueue,
                    .index = @intCast(self.threadCount),
                    .threadPool = self,
                    .commandPoolType = commandPoolType,
                    .vulkan = vulkan,
                };

                const t = try Thread.spawn(.{}, oneTimeCommand.recordCommand, .{&self.info[self.threadCount].?});
                self.threads[self.threadCount] = t;

                defer self.threadCount += 1;

                return &self.info[self.threadCount].?;
            }
        }

        pub fn releaseThread(self: *Self, index: i32) void {
            const zone = tracy.initZone(@src(), .{ .name = "release thread" });
            defer zone.deinit();

            self.mutex.lock();
            defer self.mutex.unlock();

            if (index < 0 or index >= self.threadCount) return;

            self.freeList[self.freeCount] = index;
            self.freeCount += 1;
        }

        pub fn waitThread(self: *Self, vulkan: *VkStruct) void {
            for (0..self.threads.len) |i| {
                var end = drawC{
                    .ID = 1234124142,
                    .timestamp = std.time.nanoTimestamp(),
                    .commandType = .end,
                    .command = .{ .empty = void{} },
                    .output = .{ .empty = void{} },
                };
                var emptyQueueNode: QueueNode = .{
                    .children = undefined,
                    .parents = undefined,
                };

                if (self.info[i] != null) {
                    self.info[i].?.mutex.lock();
                    defer self.info[i].?.mutex.unlock();

                    self.info[i].?.taskQueue.pushLast(.{ .com = &end, .node = &emptyQueueNode }) catch |err| {
                        std.log.err("failed to push end command to thread task queue: {s}", .{@errorName(err)});
                    };
                    self.info[i].?.semaphore.post();
                }

                if (self.threads[i] != null) {
                    self.threads[i].?.join();
                }

                if (self.info[i] != null) {
                    self.info[i].?.taskQueue.deinit();
                    self.info[i].?.commandPool.deinit(vulkan);
                    self.info[i].?.commandBuffers.deinit();
                }
            }
        }
    };
}

fn Graph(T: type) type {
    return struct {
        const Self = @This();

        ID: u32 = 0,

        parents: uniqueArrayList(*u32),
        parentsLen: u32 = 0,
        parentsDone: u32 = 0,

        children: uniqueArrayList(*u32),
        childrenLen: u32 = 0,
        childrenDone: u32 = 0,

        done: bool = false,

        data: T = undefined,

        pub fn parentsAppend(self: *Self, ID: *u32) !void {
            if (!(try self.parents.append(ID)))
                self.parentsLen += 1;
        }

        pub fn childrenAppend(self: *Self, ID: *u32) !void {
            if (!(try self.children.append(ID)))
                self.childrenLen += 1;
        }

        pub fn clearParents(self: *Self) void {
            self.parents.deinit();
            self.parents = undefined;
            self.parentsLen = 0;
            self.parentsDone = 0;
        }

        pub fn clearChildren(self: *Self) void {
            self.children.deinit();
            self.children = undefined;
            self.childrenLen = 0;
            self.childrenDone = 0;
        }

        // pub fn insertPrev(self: *Self, prev: *Self) void {
        //     const parents = self.parents;
        //     prev.parents = parents;
        //     prev.parentsLen = self.parentsLen;
        //     self.clearParents();
        //     self.parentsAppend(&prev.node);
        //     prev.childrenAppend(&self.node);

        //     var first = parents.first;
        //     while (first) |nn| {
        //         var ll: *Self = @fieldParentPtr("node", nn);

        //         ll.children.remove(&self.node);
        //         ll.children.append(&prev.node);

        //         first = nn.next;
        //     }
        // }

        // pub fn insertNext(self: *Self, next: *Self) void {
        //     const children = self.children;
        //     next.children = children;
        //     next.childrenLen = self.parentsLen;
        //     self.clearChildren();
        //     self.childrenAppend(&next.node);
        //     next.parentsAppend(&self.node);

        //     var first = children.first;
        //     while (first) |nn| {
        //         var ll: *Self = @fieldParentPtr("node", nn);

        //         ll.parents.remove(&self.node);
        //         ll.parents.append(&next.node);

        //         first = nn.next;
        //     }
        // }

        pub fn nodeDone(self: *Self) void {
            const zone = tracy.initZone(@src(), .{ .name = "node done" });
            defer zone.deinit();

            self.done = true;

            for (self.children.list.items) |ID| {
                var ll: *Self = @alignCast(@fieldParentPtr("ID", ID));

                ll.parentsDone += 1;

                // std.log.debug("child node {}\n", .{ll.*});
            }

            for (self.parents.list.items) |ID| {
                var ll: *Self = @alignCast(@fieldParentPtr("ID", ID));

                ll.childrenDone += 1;

                // std.log.debug("parent node {}\n", .{ll.*});
            }
        }

        pub fn getFirstUndoneChild(self: *Self) ?*Self {
            const zone = tracy.initZone(@src(), .{ .name = "get first undone child" });
            defer zone.deinit();

            if (self.childrenLen == self.childrenDone) return null;

            for (self.children.list.items) |ID| {
                const ll: *Self = @alignCast(@fieldParentPtr("ID", ID));

                if (ll.done) {
                    continue;
                } else {
                    return ll;
                }
            }

            return null;
        }
    };
}
const CommandBufferRecordKind = enum {
    Graphic,
    Compute,
    Raytracing,
    Video,
    Other,
};

const CommandBufferBelong = struct {
    commandBufer: vk.VkCommandBuffer,
    kind: CommandBufferRecordKind,
    semaphore: Thread.Semaphore = .{},
    commandBufferID: u32 = 0,
};

fn DAG(T: type) type {
    return struct {
        const Self = @This();
        pub const Inner = Graph(T);

        innerID: u32 = 0,
        mem: std.heap.MemoryPoolExtra(Inner, .{}),
        map: std.hash_map.AutoHashMap(u32, *Inner),
        allocator: std.heap.ArenaAllocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .mem = .init(allocator),
                .map = .init(allocator),
                .allocator = .init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.deinit();
            self.mem.deinit();
            self.map.deinit();
        }

        pub fn get(self: *Self, id: u32) ?*Inner {
            const zone = tracy.initZone(@src(), .{ .name = "dag get inner" });
            defer zone.deinit();

            return self.map.get(id);
        }

        pub fn create(self: *Self) !*Inner {
            const node = try self.mem.create();
            node.* = .{
                .ID = self.innerID,
                .children = .init(self.allocator.allocator()),
                .parents = .init(self.allocator.allocator()),
            };

            self.innerID += 1;

            const res = try self.map.getOrPut(node.ID);
            if (res.found_existing) {
                self.mem.destroy(res.value_ptr.*);
            }
            res.key_ptr.* = node.ID;
            res.value_ptr.* = node;

            return node;
        }

        pub fn clearRetainCapacity(self: *Self) void {
            const zone = tracy.initZone(@src(), .{ .name = "DAG clear" });
            defer zone.deinit();

            _ = self.mem.reset(.retain_capacity);
            self.map.clearRetainingCapacity();
            self.innerID = 0;
        }

        pub fn undoneAllNodes(self: *Self) void {
            const zone = tracy.initZone(@src(), .{ .name = "undone all nodes" });
            defer zone.deinit();

            var it = self.map.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.*.done = false;
                entry.value_ptr.*.parentsDone = 0;
                entry.value_ptr.*.childrenDone = 0;

                // std.log.debug("node {}\n", .{entry.value_ptr.*});
            }
        }

        pub fn print(self: *Self) void {
            const zone = tracy.initZone(@src(), .{ .name = "dag print" });
            defer zone.deinit();

            var buffer = [_]u8{0} ** 1024;
            var buffer2 = [_]u8{0} ** 1024;
            var writer = std.Io.Writer.fixed(&buffer);
            var writer2 = std.Io.Writer.fixed(&buffer2);

            for (0..self.innerID) |i| {
                if (self.map.get(@intCast(i))) |n| {
                    for (n.parents.list.items) |ID| {
                        const ll: *Inner = @alignCast(@fieldParentPtr("ID", ID));

                        writer.print("{d} ", .{ll.ID}) catch |err| {
                            std.log.err("write err: {s}", .{@errorName(err)});
                        };
                    }

                    for (n.children.list.items) |ID| {
                        const ll: *Inner = @alignCast(@fieldParentPtr("ID", ID));

                        writer2.print("{d} ", .{ll.ID}) catch |err| {
                            std.log.err("write err: {s}", .{@errorName(err)});
                        };
                    }

                    std.log.debug("[{s}] => ID: {d} => [{s}]", .{ buffer[0..if (writer.end > 1) writer.end - 1 else 0], n.ID, buffer2[0..if (writer2.end > 1) writer2.end - 1 else 0] });
                    _ = writer.consumeAll();
                    _ = writer2.consumeAll();
                }
            }
            std.log.debug("\n", .{});
        }
    };
}

fn nodeDagPrint(self: *QueueNodes) void {
    const zone = tracy.initZone(@src(), .{ .name = "dag print" });
    defer zone.deinit();

    var buffer = [_]u8{0} ** 1024;
    var buffer2 = [_]u8{0} ** 1024;
    var writer = std.Io.Writer.fixed(&buffer);
    var writer2 = std.Io.Writer.fixed(&buffer2);

    for (0..self.innerID) |i| {
        if (self.map.get(@intCast(i))) |n| {
            for (n.parents.list.items) |ID| {
                const ll: *QueueNode = @alignCast(@fieldParentPtr("ID", ID));

                writer.print("{d} {s} ", .{ ll.ID, @tagName(self.map.get(ID.*).?.data.commandPoolType) }) catch |err| {
                    std.log.err("write err: {s}", .{@errorName(err)});
                };
            }

            for (n.children.list.items) |ID| {
                const ll: *QueueNode = @alignCast(@fieldParentPtr("ID", ID));

                writer2.print("{d} {s} ", .{ ll.ID, @tagName(self.map.get(ID.*).?.data.commandPoolType) }) catch |err| {
                    std.log.err("write err: {s}", .{@errorName(err)});
                };
            }

            std.log.debug("[{s}] => ID: {d} => [{s}]", .{ buffer[0..if (writer.end > 1) writer.end - 1 else 0], n.ID, buffer2[0..if (writer2.end > 1) writer2.end - 1 else 0] });
            _ = writer.consumeAll();
            _ = writer2.consumeAll();
        }
    }
    std.log.debug("\n", .{});
}

const MaxThreads = 8;

const ThreadContext = struct {
    pub const task = struct {
        node: *QueueNode,
        com: *drawC,
    };
    semaphore: Thread.Semaphore,

    taskQueue: Queue(task),
    commandPool: CommandPools,
    mutex: Thread.Mutex,
    index: i32,
    threadPool: *SpecialThreadPool(MaxThreads),
    commandPoolType: VkStruct.CommandPoolType,

    /// only one
    commandBuffers: commandBufferDAG,
    vulkan: *VkStruct,
};

const dependencyData = struct {
    const NodeType = enum {
        Stright,
        Split,
        SplitStright,
        Merge,
        MergeAndSplit,
    };

    cost: u32 = 0,
    startThread: bool = false,
    isSecondary: bool = false,
    nodeType: NodeType = .Stright,
    commandPoolType: VkStruct.CommandPoolType = .graphic,
    commandBufferID: u32 = 0,
};

const QueueNodes = DAG(dependencyData);
pub const QueueNode = QueueNodes.Inner;

const commandBufferDAG = DAG(CommandBufferBelong);

const garbageDataTag = enum {
    buffer,
    bufferAndRegion,
    regions,
    barriers,
    empty,
};
const garbageData = union(garbageDataTag) {
    buffer: VkStruct.Buffer_t,
    bufferAndRegion: struct {
        buffer: VkStruct.Buffer_t,
        region: []vk.VkBufferCopy2,
    },
    regions: []vk.VkBufferCopy2,
    barriers: []drawC.Barrier,
    empty: void,
};
const GarbageData = struct {
    data: garbageData,
    semaphoreValue: u64,
};

pub const oneTimeCommand = struct {
    const Self = @This();

    // pub const TaskCallback = *const fn (ctx: *anyopaque) VkStruct.VkError!void;
    // const EnqueueTaskCallback = *const fn (taskCallback: TaskCallback, taskCtx: *anyopaque, userCtx: *anyopaque) *anyopaque;
    // const FinishTaskCallback = *const fn (userTask: *anyopaque, userCtx: *anyopaque) void;
    vulkan: *VkStruct,
    pRendering: *rendering,

    innerID: u32 = 0,
    innerCommandBufferID: u32 = 0,
    queue: std.hash_map.AutoHashMap(u32, drawC),
    nodeDag: QueueNodes,
    combineMap: std.AutoHashMap(u64, *QueueNode),

    primaryCommandPool: CommandPools,

    allocator: std.mem.Allocator,
    stackAllocator: std.mem.Allocator,

    threadPool: SpecialThreadPool(MaxThreads),
    mutex: Thread.Mutex = .{},
    executeSemaphore: Thread.Semaphore = .{},

    cacheMap: std.AutoHashMap(*anyopaque, u32),
    garbageData: std.array_list.Managed(GarbageData),

    // commandPools: std.array_list.Managed(vk.VkCommandPool),

    pub fn init(allocator: std.mem.Allocator, stackAllocator: std.mem.Allocator, vulkan: *VkStruct, pRendering: *rendering) Self {
        std.log.info("command size: {d}", .{@sizeOf(drawC.comm)});
        std.log.info("vk struct Buffer size: {d}", .{@sizeOf(VkStruct.Buffer_t)});
        return Self{
            .queue = .init(allocator),
            .allocator = allocator,
            .nodeDag = .init(allocator),
            .threadPool = .init(allocator),
            .primaryCommandPool = .init(allocator, 0, 0, 0),
            .garbageData = .init(allocator),
            .stackAllocator = stackAllocator,
            .combineMap = .init(allocator),
            .cacheMap = .init(allocator),
            .vulkan = vulkan,
            .pRendering = pRendering,
        };
    }

    pub fn deinit(self: *Self) void {
        const zone = tracy.initZone(@src(), .{ .name = "deinit OnetimeCommand" });
        defer zone.deinit();

        var waitValue = self.vulkan.globalTimelineValue.load(.seq_cst);
        self.vulkan.waitSemaphore(
            1,
            &self.vulkan.globalTimelineSemaphore,
            &waitValue,
        ) catch |err| {
            std.log.err("wait semaphore error {s}\n", .{@errorName(err)});
        };
        self.queue.deinit();
        self.nodeDag.deinit();
        self.threadPool.waitThread(self.vulkan);
        self.primaryCommandPool.deinit(self.vulkan);
        self.cleanGarbage() catch |err| {
            std.log.err("clean garbage error {s}\n", .{@errorName(err)});
        };
        self.combineMap.deinit();
        self.garbageData.deinit();
        self.cacheMap.deinit();
    }

    fn getOuput(commandType: drawC.CommandType, command: drawC.comm) drawC.Output {
        const zone = tracy.initZone(@src(), .{ .name = "get output OnetimeCommand" });
        defer zone.deinit();

        return rs: switch (commandType) {
            .start, .beginPrimaryRecord, .beginRendering, .beginSecondaryRecord, .endRendering, .endRecord, .present, .draw2D, .graphicTransfer, .transfer, .end, .pipelineBarrier => {
                break :rs drawC.Output{ .empty = void{} };
            },
            .copyBufferToImage => {
                break :rs drawC.Output{ .image = command.copyBufferToImage.dstImage };
            },
            .copyBuffer => {
                break :rs drawC.Output{ .buffer = command.copyBuffer.dstBuffer };
            },
            // .transLayout => {
            //     break :rs drawC.Output{ .image = command.transLayout.pTexture.image.vkImage };
            // },
            else => {
                std.debug.panic("not support {s}", .{@tagName(commandType)});
            },
        };
    }

    fn commandCost(commandType: drawC.CommandType) u32 {
        const zone = tracy.initZone(@src(), .{ .name = "calculate command cost" });
        defer zone.deinit();

        return switch (commandType) {
            .graphic => 100,
            .copyBufferToImage => 100,
            .transLayout => 100,
        };
    }

    fn inferTransLayoutFlagsByOldLayoutAndNewLayout(command: *drawC.comm) struct {
        srcAccessMask: vk.VkAccessFlags2,
        dstAccessMask: vk.VkAccessFlags2,
        aspectMask: vk.VkImageAspectFlags,
        sourceStage: vk.VkPipelineStageFlags2,
        destinationStage: vk.VkPipelineStageFlags2,
    } {
        const zone = tracy.initZone(@src(), .{ .name = "infer trans layout" });
        defer zone.deinit();

        var srcAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_2_NONE;
        var dstAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_2_NONE;
        var aspectMask: vk.VkImageAspectFlags = vk.VK_IMAGE_ASPECT_NONE;
        var sourceStage: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE;
        var destinationStage: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE;

        switch (command.transLayout.oldLayout) {
            vk.VK_IMAGE_LAYOUT_UNDEFINED => {
                srcAccessMask = vk.VK_ACCESS_2_NONE;
                sourceStage = vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT;
                aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL => {
                srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT;
                sourceStage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT;
                aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL => {
                srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
                sourceStage = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
                aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL,
            vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
            => {
                srcAccessMask = vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;
                sourceStage = vk.VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT;
                aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT;
            },

            // vk.VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_OPTIMAL,
            // vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL,
            // => {
            //     command.command.transLayout.srcAccessMask = vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT;
            //     command.command.transLayout.sourceStage = vk.VK_PIPELINE_STAGE_EA;
            //     command.command.transLayout.aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT;
            // },

            else => {
                std.debug.panic("unsupported layout {s}", .{@typeName(@TypeOf(command.transLayout.newLayout))});
            },
        }

        switch (command.transLayout.newLayout) {
            vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL => {
                dstAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT;
                destinationStage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT;
                aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL => {
                dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT;
                destinationStage = vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT;
                aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL => {
                dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
                destinationStage = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
                aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR => {
                dstAccessMask = vk.VK_ACCESS_2_NONE;
                destinationStage = vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
                aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            else => {
                std.debug.panic("unsupported layout {s}", .{@typeName(@TypeOf(command.transLayout.newLayout))});
            },
        }

        return .{
            .srcAccessMask = srcAccessMask,
            .dstAccessMask = dstAccessMask,
            .aspectMask = aspectMask,
            .sourceStage = sourceStage,
            .destinationStage = destinationStage,
        };
    }

    fn inferReleasePipelinBarrierInfoByCommandTypeAndBufferUsage(
        commandType: drawC.PublicCommandType,
        bufferUsage: drawC.BufferUsage,
        srcQueue: VkStruct.CommandPoolType,
        dstQueue: VkStruct.CommandPoolType,
    ) struct {
        srcAccessMask: vk.VkAccessFlags2,
        dstAccessMask: vk.VkAccessFlags2,
        sourceStage: vk.VkPipelineStageFlags2,
        destinationStage: vk.VkPipelineStageFlags2,
    } {
        const zone = tracy.initZone(@src(), .{ .name = "infer release pipelin barrier info" });
        defer zone.deinit();

        _ = commandType;
        _ = bufferUsage;
        var srcAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_2_NONE;
        const dstAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_2_NONE;
        var sourceStage: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE;
        const destinationStage: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;

        if (srcQueue == .transfer) {
            if (dstQueue == .graphic) {
                sourceStage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT;
                srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT;
            } else {
                std.debug.panic("unsupported dst queue {s}", .{@typeName(@TypeOf(dstQueue))});
            }
        } else {
            std.debug.panic("unsupported src queue {s}", .{@typeName(@TypeOf(srcQueue))});
        }

        return .{
            .srcAccessMask = srcAccessMask,
            .dstAccessMask = dstAccessMask,
            .sourceStage = sourceStage,
            .destinationStage = destinationStage,
        };
    }

    fn inferAcquirePipelinBarrierInfoByCommandTypeAndBufferUsage(
        commandType: drawC.PublicCommandType,
        bufferUsage: drawC.BufferUsage,
        srcQueue: VkStruct.CommandPoolType,
        dstQueue: VkStruct.CommandPoolType,
    ) struct {
        srcAccessMask: vk.VkAccessFlags2,
        dstAccessMask: vk.VkAccessFlags2,
        sourceStage: vk.VkPipelineStageFlags2,
        destinationStage: vk.VkPipelineStageFlags2,
    } {
        const zone = tracy.initZone(@src(), .{ .name = "infer acquire pipelin barrier info" });
        defer zone.deinit();

        _ = commandType;
        const srcAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_2_NONE;
        var dstAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_2_NONE;
        const sourceStage: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT;
        var destinationStage: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE;

        if (srcQueue == .transfer) {
            if (dstQueue == .graphic) {
                switch (bufferUsage) {
                    .vertex => {
                        destinationStage = vk.VK_PIPELINE_STAGE_VERTEX_INPUT_BIT;
                        dstAccessMask = vk.VK_ACCESS_VERTEX_ATTRIBUTE_READ_BIT;
                    },
                    else => std.debug.panic("unsupported buffer usage {s}", .{@typeName(@TypeOf(bufferUsage))}),
                }
            } else {
                std.debug.panic("unsupported dst queue {s}", .{@typeName(@TypeOf(dstQueue))});
            }
        } else {
            std.debug.panic("unsupported src queue {s}", .{@typeName(@TypeOf(srcQueue))});
        }

        return .{
            .srcAccessMask = srcAccessMask,
            .dstAccessMask = dstAccessMask,
            .sourceStage = sourceStage,
            .destinationStage = destinationStage,
        };
    }

    fn inferReleasePipelineBarrierInfoByImageUsage(
        commandType: drawC.PublicCommandType,
        srcQueue: VkStruct.CommandPoolType,
        dstQueue: VkStruct.CommandPoolType,
        layout: vk.VkImageLayout,
    ) struct {
        srcAccessMask: vk.VkAccessFlags2,
        dstAccessMask: vk.VkAccessFlags2,
        aspectMask: vk.VkImageAspectFlags,
        sourceStage: vk.VkPipelineStageFlags2,
        destinationStage: vk.VkPipelineStageFlags2,
    } {
        const zone = tracy.initZone(@src(), .{ .name = "infer release pipelin barrier info" });
        defer zone.deinit();

        _ = commandType;
        _ = layout;
        var srcAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_2_NONE;
        const dstAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_2_NONE;
        var aspectMask: vk.VkImageAspectFlags = vk.VK_IMAGE_ASPECT_COLOR_BIT;
        var sourceStage: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE;
        const destinationStage: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;

        if (srcQueue == .transfer) {
            if (dstQueue == .graphic) {
                sourceStage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT;
                srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT;
                aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            } else {
                std.debug.panic("unsupported dst queue {s}", .{@tagName(dstQueue)});
            }
        } else {
            std.debug.panic("unsupported src queue {s}", .{@tagName(srcQueue)});
        }

        return .{
            .srcAccessMask = srcAccessMask,
            .dstAccessMask = dstAccessMask,
            .aspectMask = aspectMask,
            .sourceStage = sourceStage,
            .destinationStage = destinationStage,
        };
    }

    fn inferAcquirePipelineBarrierInfoByImageUsage(
        commandType: drawC.PublicCommandType,
        // imageUsage: drawC.TextureUsage,
        srcQueue: VkStruct.CommandPoolType,
        dstQueue: VkStruct.CommandPoolType,
        layout: vk.VkImageLayout,
    ) struct {
        srcAccessMask: vk.VkAccessFlags2,
        dstAccessMask: vk.VkAccessFlags2,
        aspectMask: vk.VkImageAspectFlags,
        sourceStage: vk.VkPipelineStageFlags2,
        destinationStage: vk.VkPipelineStageFlags2,
    } {
        const zone = tracy.initZone(@src(), .{ .name = "infer acquire pipelin barrier info" });
        defer zone.deinit();

        _ = commandType;
        _ = layout;
        const srcAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_2_NONE;
        var dstAccessMask: vk.VkAccessFlags2 = vk.VK_ACCESS_2_NONE;
        var aspectMask: vk.VkImageAspectFlags = vk.VK_IMAGE_ASPECT_COLOR_BIT;
        const sourceStage: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT;
        var destinationStage: vk.VkPipelineStageFlags2 = vk.VK_PIPELINE_STAGE_2_NONE;

        dstAccessMask = vk.VK_ACCESS_2_NONE;
        destinationStage = vk.VK_PIPELINE_STAGE_2_NONE;

        if (srcQueue == .transfer) {
            if (dstQueue == .graphic) {
                aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
                // switch (imageUsage) {
                //     .color => {
                //         destinationStage = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
                //         dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT;
                //     },
                //     else => std.debug.panic("unsupported image usage {s}", .{@tagName(imageUsage))}),
                // }
                std.debug.panic("unsupported dst queue {s}", .{@tagName(dstQueue)});
            } else {
                std.debug.panic("unsupported dst queue {s}", .{@tagName(dstQueue)});
            }
        } else {
            std.debug.panic("unsupported src queue {s}", .{@tagName(srcQueue)});
        }

        return .{
            .srcAccessMask = srcAccessMask,
            .dstAccessMask = dstAccessMask,
            .aspectMask = aspectMask,
            .sourceStage = sourceStage,
            .destinationStage = destinationStage,
        };
    }

    pub fn startCommand(self: *Self) !void {
        const zone = tracy.initZone(@src(), .{ .name = "start vulkan commands" });
        defer zone.deinit();

        const node = try self.nodeDag.create();

        const ptr = try self.queue.getOrPut(node.ID);
        ptr.value_ptr.* = drawC{
            .ID = node.ID,
            .timestamp = std.time.nanoTimestamp(),
            .commandType = .start,
            .command = .{ .start = .{} },
            .output = .{ .empty = void{} },
        };
    }

    fn addCommand2(self: *Self, commandType: drawC.PrivateCommandType, command: drawC.comm, enterCommandType: drawC.PublicCommandType) !twoQueueNode {
        const zone = tracy.initZone(@src(), .{ .name = "add command 2" });
        defer zone.deinit();

        // const allCommandType = drawC.PrivateCommandTypeToCommandType(commandType);
        var commandCopy = command;

        var resNode: ?*QueueNode = null;
        var resNode2: ?*QueueNode = null;

        switch (commandType) {
            .transLayout => {
                const zone2 = tracy.initZone(@src(), .{ .name = "transLayout" });
                defer zone2.deinit();

                const transLayout = commandCopy.transLayout;

                if (transLayout.srcQueueFamily != .init and transLayout.srcQueueFamily != transLayout.dstQueueFamily) {
                    const releaseFlags = inferReleasePipelineBarrierInfoByImageUsage(
                        enterCommandType,
                        transLayout.srcQueueFamily,
                        transLayout.dstQueueFamily,
                        0,
                    );

                    const releaseHash: u64 = releaseFlags.sourceStage + releaseFlags.destinationStage;

                    const release = try self.combineMap.getOrPut(releaseHash);

                    const release_barrier = drawC.Barrier{ .imageMemory = .{
                        .srcStageMask = releaseFlags.sourceStage,
                        .srcAccessMask = releaseFlags.srcAccessMask,
                        .dstStageMask = releaseFlags.destinationStage,
                        .dstAccessMask = releaseFlags.dstAccessMask,
                        .oldLayout = transLayout.oldLayout,
                        .newLayout = transLayout.newLayout,
                        .srcQueueFamilyIndex = self.vulkan.getQueueIndex(transLayout.srcQueueFamily),
                        .dstQueueFamilyIndex = self.vulkan.getQueueIndex(transLayout.dstQueueFamily),
                        .image = transLayout.image,
                        .subresourceRange = .{
                            .aspectMask = releaseFlags.aspectMask,
                            .baseMipLevel = transLayout.baseMipLevel,
                            .levelCount = transLayout.levelCount,
                            .baseArrayLayer = transLayout.baseLayer,
                            .layerCount = transLayout.layerCount,
                        },
                    } };

                    const releaseNode =
                        if (release.found_existing) blk: {
                            const node = release.value_ptr.*;
                            const cmd = self.queue.getPtr(node.ID).?;

                            if (cmd.commandType != .pipelineBarrier) std.debug.panic("not supported commandType {s}", .{@tagName(cmd.commandType)});

                            break :blk node;
                        } else blk: {
                            const node = try self.nodeDag.create();
                            release.value_ptr.* = node;
                            const ptr = try self.queue.getOrPut(node.ID);
                            ptr.value_ptr.* = drawC{
                                .ID = node.ID,
                                .timestamp = std.time.nanoTimestamp(),
                                .command = .{
                                    .pipelineBarrier = .{
                                        .barriers = &[_]drawC.Barrier{}, // 初始化为空切片，统一在下面做 append
                                    },
                                },
                                .commandType = .pipelineBarrier,
                                .output = .{ .empty = void{} },
                            };
                            break :blk node;
                        };
                    releaseNode.data.commandPoolType = transLayout.srcQueueFamily;

                    var releasePipelineBarrier = &self.queue.getPtr(releaseNode.ID).?.command.pipelineBarrier;
                    const new_len = releasePipelineBarrier.barriers.len + 1;
                    releasePipelineBarrier.barriers = try self.allocator.realloc(releasePipelineBarrier.barriers, new_len);
                    for (
                        releasePipelineBarrier.barriers[new_len - 1 ..],
                    ) |*barrier| {
                        barrier.* = release_barrier;
                    }

                    const acquireFlags = inferAcquirePipelineBarrierInfoByImageUsage(
                        enterCommandType,
                        transLayout.srcQueueFamily,
                        transLayout.dstQueueFamily,
                        0,
                    );

                    const acquireHash =
                        acquireFlags.sourceStage + acquireFlags.destinationStage;

                    const acquire = try self.combineMap.getOrPut(acquireHash);
                    const acquire_barrier = drawC.Barrier{
                        .imageMemory = .{
                            .srcStageMask = acquireFlags.sourceStage,
                            .srcAccessMask = acquireFlags.srcAccessMask,
                            .dstStageMask = acquireFlags.destinationStage,
                            .dstAccessMask = acquireFlags.dstAccessMask,
                            .oldLayout = transLayout.oldLayout,
                            .newLayout = transLayout.newLayout,
                            .srcQueueFamilyIndex = self.vulkan.getQueueIndex(transLayout.srcQueueFamily),
                            .dstQueueFamilyIndex = self.vulkan.getQueueIndex(transLayout.dstQueueFamily),
                            .image = transLayout.image,
                            .subresourceRange = .{
                                .aspectMask = releaseFlags.aspectMask,
                                .baseMipLevel = transLayout.baseMipLevel,
                                .levelCount = transLayout.levelCount,
                                .baseArrayLayer = transLayout.baseLayer,
                                .layerCount = transLayout.layerCount,
                            },
                        },
                    };

                    const acquireNode =
                        if (acquire.found_existing) blk: {
                            const node = acquire.value_ptr.*;
                            const cmd = self.queue.getPtr(node.ID).?;
                            if (cmd.commandType != .pipelineBarrier) std.debug.panic("not supported commandType {s}", .{@tagName(cmd.commandType)});
                            break :blk node;
                        } else blk: {
                            const node = try self.nodeDag.create();
                            // acquire.value_ptr.* = node;
                            const ptr = try self.queue.getOrPut(node.ID);
                            ptr.value_ptr.* = drawC{
                                .ID = node.ID,
                                .timestamp = std.time.nanoTimestamp(),
                                .command = .{
                                    .pipelineBarrier = .{
                                        .barriers = &[_]drawC.Barrier{}, // 初始化为空切片，统一在下面做 append
                                    },
                                },
                                .commandType = .pipelineBarrier,
                                .output = .{ .empty = void{} },
                            };
                            break :blk node;
                        };
                    acquireNode.data.commandPoolType = transLayout.dstQueueFamily;

                    var acquirePipelineBarrier = &self.queue.getPtr(acquireNode.ID).?.command.pipelineBarrier;
                    const new_len_2 = acquirePipelineBarrier.barriers.len + 1;
                    acquirePipelineBarrier.barriers = try self.allocator.realloc(acquirePipelineBarrier.barriers, new_len_2);
                    for (
                        acquirePipelineBarrier.barriers[new_len_2 - 1 ..],
                    ) |*barrier| {
                        barrier.* = acquire_barrier;
                    }

                    resNode = releaseNode;
                    resNode2 = acquireNode;
                } else {
                    var flags = inferTransLayoutFlagsByOldLayoutAndNewLayout(&commandCopy);

                    if (commandCopy.transLayout.newLayout == vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL) {
                        flags.destinationStage = vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT;
                    }

                    const hash: u64 = flags.sourceStage + flags.destinationStage;

                    const res = try self.combineMap.getOrPut(hash);
                    const new_barrier = drawC.Barrier{ .imageMemory = .{
                        .srcStageMask = flags.sourceStage,
                        .srcAccessMask = flags.srcAccessMask,
                        .dstStageMask = flags.destinationStage,
                        .dstAccessMask = flags.dstAccessMask,
                        .oldLayout = transLayout.oldLayout,
                        .newLayout = transLayout.newLayout,
                        .srcQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
                        .dstQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
                        .image = transLayout.image,
                        .subresourceRange = .{
                            .aspectMask = flags.aspectMask,
                            .baseMipLevel = transLayout.baseMipLevel,
                            .levelCount = transLayout.levelCount,
                            .baseArrayLayer = transLayout.baseLayer,
                            .layerCount = transLayout.layerCount,
                        },
                    } };

                    const rootNode =
                        if (res.found_existing) blk: {
                            const node = res.value_ptr.*;
                            // 简单的类型检查，panic 放在这一行保持紧凑
                            const cmd = self.queue.getPtr(node.ID).?;
                            if (cmd.commandType != .pipelineBarrier) std.debug.panic("not supported commandType {s}", .{@tagName(cmd.commandType)});

                            break :blk node;
                        } else blk: {
                            // 2. 新节点的创建逻辑
                            const node = try self.nodeDag.create();
                            res.value_ptr.* = node;
                            const ptr = try self.queue.getOrPut(node.ID);
                            ptr.value_ptr.* = drawC{
                                .ID = node.ID,
                                .timestamp = std.time.nanoTimestamp(),
                                .command = .{
                                    .pipelineBarrier = .{
                                        .lastSrcStageMask = flags.sourceStage,
                                        .barriers = &[_]drawC.Barrier{}, // 初始化为空切片，统一在下面做 append
                                    },
                                },
                                .commandType = .pipelineBarrier,
                                .output = .{ .empty = void{} },
                            };
                            break :blk node;
                        };

                    // 3. 统一的 Barrier 添加逻辑 (利用 realloc 自动处理空切片情况)
                    var pipelineBarrier = &self.queue.getPtr(rootNode.ID).?.command.pipelineBarrier;
                    const new_len = pipelineBarrier.barriers.len + 1;
                    pipelineBarrier.barriers = try self.allocator.realloc(pipelineBarrier.barriers, new_len);
                    pipelineBarrier.barriers[new_len - 1] = new_barrier;
                    pipelineBarrier.lastSrcStageMask = @min(pipelineBarrier.lastSrcStageMask, flags.sourceStage);

                    // if (prev) |n| {
                    //     if (!res.found_existing) rootNode.data.commandPoolType = n.data.commandPoolType;

                    //     try rootNode.parentsAppend(&n.ID);
                    //     try n.childrenAppend(&rootNode.ID);
                    // }
                    // if (next) |p| {
                    //     if (!res.found_existing) rootNode.data.commandPoolType = p.data.commandPoolType;

                    //     try rootNode.childrenAppend(&p.ID);
                    //     try p.parentsAppend(&rootNode.ID);
                    // }

                    resNode = rootNode;
                }
            },
            .changeBufferQueue => {
                const zone2 = tracy.initZone(@src(), .{ .name = "changeBufferQueue" });
                defer zone2.deinit();

                const changeBufferQueue = command.changeBufferQueue;
                const bufferUsage = self.vulkan.buffers.getBufferUsage(changeBufferQueue.buffer);

                const releaseFlags = inferReleasePipelinBarrierInfoByCommandTypeAndBufferUsage(
                    enterCommandType,
                    bufferUsage,
                    changeBufferQueue.srcQueueFamily,
                    changeBufferQueue.dstQueueFamily,
                );

                const releaseHash =
                    releaseFlags.sourceStage + releaseFlags.destinationStage;

                const release = try self.combineMap.getOrPut(releaseHash);
                const release_new_barrier = drawC.Barrier{
                    .bufferMemory = .{
                        .srcStageMask = releaseFlags.sourceStage,
                        .srcAccessMask = releaseFlags.srcAccessMask,
                        .dstStageMask = releaseFlags.destinationStage,
                        .dstAccessMask = releaseFlags.dstAccessMask,
                        .srcQueueFamilyIndex = self.vulkan.getQueueIndex(changeBufferQueue.srcQueueFamily),
                        .dstQueueFamilyIndex = self.vulkan.getQueueIndex(changeBufferQueue.dstQueueFamily),
                        .buffer = self.vulkan.buffers.getVkBuffer(changeBufferQueue.buffer),
                        // assigned later
                        .offset = 0,
                        .size = 0,
                    },
                };

                const releaseNode =
                    if (release.found_existing) blk: {
                        const node = release.value_ptr.*;
                        const cmd = self.queue.getPtr(node.ID).?;

                        if (cmd.commandType != .pipelineBarrier) std.debug.panic("not supported commandType {s}", .{@tagName(cmd.commandType)});

                        break :blk node;
                    } else blk: {
                        const node = try self.nodeDag.create();
                        release.value_ptr.* = node;
                        const ptr = try self.queue.getOrPut(node.ID);
                        ptr.value_ptr.* = drawC{
                            .ID = node.ID,
                            .timestamp = std.time.nanoTimestamp(),
                            .command = .{
                                .pipelineBarrier = .{
                                    .barriers = &[_]drawC.Barrier{}, // 初始化为空切片，统一在下面做 append
                                },
                            },
                            .commandType = .pipelineBarrier,
                            .output = .{ .empty = void{} },
                        };
                        break :blk node;
                    };
                releaseNode.data.commandPoolType = changeBufferQueue.srcQueueFamily;

                var releasePipelineBarrier = &self.queue.getPtr(releaseNode.ID).?.command.pipelineBarrier;
                const new_len = releasePipelineBarrier.barriers.len + changeBufferQueue.regions.len;
                releasePipelineBarrier.barriers = try self.allocator.realloc(releasePipelineBarrier.barriers, new_len);
                for (
                    changeBufferQueue.regions,
                    releasePipelineBarrier.barriers[new_len - changeBufferQueue.regions.len ..],
                ) |region, *barrier| {
                    barrier.* = release_new_barrier;
                    barrier.bufferMemory.offset = region.offset;
                    barrier.bufferMemory.size = region.size;
                }

                const acquireFlags = inferAcquirePipelinBarrierInfoByCommandTypeAndBufferUsage(
                    enterCommandType,
                    bufferUsage,
                    changeBufferQueue.srcQueueFamily,
                    changeBufferQueue.dstQueueFamily,
                );

                const acquireHash =
                    acquireFlags.sourceStage + acquireFlags.destinationStage;

                const acquire = try self.combineMap.getOrPut(acquireHash);
                const acquire_new_barrier = drawC.Barrier{
                    .bufferMemory = .{
                        .srcStageMask = acquireFlags.sourceStage,
                        .srcAccessMask = acquireFlags.srcAccessMask,
                        .dstStageMask = acquireFlags.destinationStage,
                        .dstAccessMask = acquireFlags.dstAccessMask,
                        .srcQueueFamilyIndex = self.vulkan.getQueueIndex(changeBufferQueue.srcQueueFamily),
                        .dstQueueFamilyIndex = self.vulkan.getQueueIndex(changeBufferQueue.dstQueueFamily),
                        .buffer = self.vulkan.buffers.getVkBuffer(changeBufferQueue.buffer),
                        // assigned later
                        .offset = 0,
                        .size = 0,
                    },
                };

                const acquireNode =
                    if (acquire.found_existing) blk: {
                        const node = acquire.value_ptr.*;
                        const cmd = self.queue.getPtr(node.ID).?;
                        if (cmd.commandType != .pipelineBarrier) std.debug.panic("not supported commandType {s}", .{@tagName(cmd.commandType)});
                        break :blk node;
                    } else blk: {
                        const node = try self.nodeDag.create();
                        acquire.value_ptr.* = node;
                        const ptr = try self.queue.getOrPut(node.ID);
                        ptr.value_ptr.* = drawC{
                            .ID = node.ID,
                            .timestamp = std.time.nanoTimestamp(),
                            .command = .{
                                .pipelineBarrier = .{
                                    .barriers = &[_]drawC.Barrier{}, // 初始化为空切片，统一在下面做 append
                                },
                            },
                            .commandType = .pipelineBarrier,
                            .output = .{ .empty = void{} },
                        };
                        break :blk node;
                    };
                acquireNode.data.commandPoolType = changeBufferQueue.dstQueueFamily;

                var acquirePipelineBarrier = &self.queue.getPtr(acquireNode.ID).?.command.pipelineBarrier;
                const new_len_2 = acquirePipelineBarrier.barriers.len + changeBufferQueue.regions.len;
                acquirePipelineBarrier.barriers = try self.allocator.realloc(acquirePipelineBarrier.barriers, new_len_2);
                for (
                    changeBufferQueue.regions,
                    acquirePipelineBarrier.barriers[new_len_2 - changeBufferQueue.regions.len ..],
                ) |region, *barrier| {
                    barrier.* = acquire_new_barrier;
                    barrier.bufferMemory.offset = region.offset;
                    barrier.bufferMemory.size = region.size;
                }

                try releaseNode.childrenAppend(&acquireNode.ID);
                try acquireNode.parentsAppend(&releaseNode.ID);

                resNode = releaseNode;
                resNode2 = acquireNode;

                // if (prev) |n| {
                //     resNode = releaseNode;

                //     try resNode.parentsAppend(&n.ID);
                //     try n.childrenAppend(&resNode.ID);
                // }
                // if (next) |p| {
                //     resNode = acquireNode;

                //     try resNode.childrenAppend(&p.ID);
                //     try p.parentsAppend(&resNode.ID);
                // }
            },
            // .changeTextureQueue => {},
            else => {
                std.debug.panic("not supported commandType {s}", .{@tagName(commandType)});
            },
        }

        // const hash: u64 = hs: {
        //     switch (ptr.value_ptr.commandType) {
        //         .transLayout => {
        //             const transLayout = ptr.value_ptr.command.transLayout;
        //             break :hs math.szudzikPairing(transLayout.sourceStage, transLayout.destinationStage);
        //         },
        //         .copyBufferToImage => {
        //             var wyHash = std.hash.Wyhash.init(0);
        //             const copyBufferToImage = ptr.value_ptr.command.copyBufferToImage;
        //             const a = @intFromPtr(copyBufferToImage.buffer.vkBuffer);
        //             const b = @intFromPtr(copyBufferToImage.pTexture.image.vkImage);
        //             wyHash.update(std.mem.asBytes(&a));
        //             wyHash.update(std.mem.asBytes(&b));
        //             break :hs wyHash.final();
        //         },
        //         else => {
        //             std.debug.panic("not supported commandType {s}", .{@tagName(command.commandType)});
        //         },
        //     }
        // };

        return .{
            .a = resNode,
            .b = resNode2,
        };
    }

    fn transLayoutHelper(
        self: *Self,
        textureSet: *texture,
        texture_: texture.Texture_t,
        baseArrayLayer: u32,
        layerCount: u32,
        newLayout: vk.VkImageLayout,
        newQueue: VkStruct.CommandPoolType,
        commandType: drawC.PublicCommandType,
    ) !twoQueueNode {
        const textureContent = textureSet.getTextureCotent(texture_);
        const oldLayouts = textureContent.layouts;
        const oldQueue = textureContent.image.queueIndex;
        const dstImage = textureContent.image.vkImage;

        var currentLayout = oldLayouts[0];
        var currentBase = baseArrayLayer;
        var count: u32 = 0;
        var transNode: twoQueueNode = .{};

        for (oldLayouts) |layout| {
            if (currentLayout == newLayout) {
                currentLayout = layout;
                currentBase += 1;
                continue;
            }

            if (layout == currentLayout) {
                count += 1;
            } else {
                transNode = try self.addCommand2(.transLayout, .{ .transLayout = .{
                    .image = dstImage,
                    .oldLayout = currentLayout,
                    .newLayout = newLayout,
                    .baseLayer = currentBase,
                    .layerCount = count,
                    .srcQueueFamily = oldQueue,
                    .dstQueueFamily = newQueue,
                } }, commandType);

                currentLayout = layout;
                currentBase += count;
                if (currentLayout != newLayout) {
                    count = 1;
                }
            }
        }
        if (count > 0) {
            transNode = try self.addCommand2(.transLayout, .{ .transLayout = .{
                .image = dstImage,
                .oldLayout = currentLayout,
                .newLayout = newLayout,
                .baseLayer = currentBase,
                .layerCount = count,
                .srcQueueFamily = oldQueue,
                .dstQueueFamily = newQueue,
            } }, commandType);
        }
        textureSet.changeTextureLayout(texture_, baseArrayLayer, layerCount, newLayout);
        textureSet.changeTextureQueue(texture_, newQueue);

        return transNode;
    }

    fn nodeConnect(self: *Self, nodes: []twoQueueNode) !twoQueueNode {
        const newNodesA = self.stackAllocator.alloc(?*QueueNode, nodes.len) catch unreachable;
        defer self.stackAllocator.free(newNodesA);

        const newNodesB = self.stackAllocator.alloc(?*QueueNode, nodes.len) catch unreachable;
        defer self.stackAllocator.free(newNodesB);

        for (newNodesA, newNodesB) |*a, *b| {
            a.* = null;
            b.* = null;
        }

        for (nodes) |node| {
            for (newNodesA) |*value| {
                if (value.* == null) {
                    value.* = node.a;
                    break;
                }
                if (value.* == node.a) {
                    break;
                }
            }

            for (newNodesB) |*value| {
                if (value.* == null) {
                    value.* = node.b;
                    break;
                }
                if (value.* == node.b) {
                    break;
                }
            }
        }

        var lastA: ?*QueueNode = null;
        var midA: ?*QueueNode = null;
        var lastB: ?*QueueNode = null;
        var midB: ?*QueueNode = null;
        for (newNodesA, newNodesB) |a, b| {
            if (a) |aa| {
                if (lastA == null) {
                    lastA = aa;
                    midA = aa;
                } else {
                    try aa.childrenAppend(&lastA.?.ID);
                    try lastA.?.parentsAppend(&aa.ID);

                    lastA = aa;
                }
            }

            if (b) |bb| {
                if (lastB == null) {
                    lastB = bb;
                    midB = bb;
                    try midA.?.childrenAppend(&midB.?.ID);
                    try midB.?.parentsAppend(&midA.?.ID);
                } else {
                    try bb.parentsAppend(&lastB.?.ID);
                    try lastB.?.childrenAppend(&bb.ID);

                    lastB = bb;
                }
            }
        }

        // try midA.?.childrenAppend(&midB.?.ID);
        // try midB.?.parentsAppend(&midA.?.ID);

        return .{ .a = lastA, .b = if (lastB == null) midA else lastB };
    }

    pub fn addCommand(self: *Self, commandType: drawC.PublicCommandType, command: drawC.comm) !void {
        const zone = tracy.initZone(@src(), .{ .name = "add command" });
        defer zone.deinit();

        self.mutex.lock();
        defer self.mutex.unlock();

        const allCommandType = drawC.PublicCommandTypeToCommandType(commandType);

        const node = try self.nodeDag.create();
        const ID = node.ID;

        var currentNode = node;
        const ptr = try self.queue.getOrPut(ID);
        // ptr.value_ptr.ID = ID;
        // ptr.value_ptr.timestamp = std.time.nanoTimestamp();

        ptr.value_ptr.* = drawC{
            .ID = ID,
            .timestamp = std.time.nanoTimestamp(),
            .command = command,
            .commandType = allCommandType,
            .output = getOuput(allCommandType, command),
        };

        // dependcy infer
        // combine memory barrier operation with same src stage mask
        // combine same image draw call
        // combine buffer copy to image with same src buffer and dst image
        const zone2 = tracy.initZone(@src(), .{ .name = "infer dependency 1" });
        errdefer zone2.deinit();
        switch (commandType) {
            .draw2D => {
                node.data.commandPoolType = .graphic;

                const draw2D = ptr.value_ptr.command.draw2d;
                const pTextureSet = draw2D.pTextureSet;

                const imageQueueNode = try self.transLayoutHelper(
                    pTextureSet,
                    draw2D.pTexture,
                    0,
                    1,
                    vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                    .graphic,
                    commandType,
                );
                _ = imageQueueNode;

                if (!self.pRendering.renderingStarted(draw2D.rendering)) {
                    const renderingInfo = self.pRendering.getRenderingInfoContent(draw2D.rendering);
                    const renderingColorTextureLen = bl: {
                        var count: u32 = 0;
                        if (renderingInfo.depthAttachment != null) {
                            count += 1;
                        }
                        if (renderingInfo.stencilAttachment != null) {
                            count += 1;
                        }
                        break :bl renderingInfo.textures.len - count;
                    };

                    var renderingImageQueueNodes = try self.stackAllocator.alloc(twoQueueNode, renderingInfo.textures.len);
                    defer self.stackAllocator.free(renderingImageQueueNodes);
                    if (renderingInfo.pColorAttachments) |v| {
                        for (renderingInfo.textures[0..renderingColorTextureLen], v, 0..) |value, attachment, i| {
                            renderingImageQueueNodes[i] = try self.transLayoutHelper(
                                pTextureSet,
                                value,
                                0,
                                1,
                                attachment.imageLayout,
                                .graphic,
                                commandType,
                            );
                        }
                    }

                    var depthImageQueueNode: twoQueueNode = .{};
                    if (renderingInfo.depthAttachment) |v| {
                        depthImageQueueNode = try self.transLayoutHelper(
                            pTextureSet,
                            renderingInfo.textures[renderingColorTextureLen],
                            0,
                            1,
                            v[0].imageLayout,
                            .graphic,
                            commandType,
                        );
                    }

                    var stencilImageQueueNode: twoQueueNode = .{};
                    if (renderingInfo.stencilAttachment) |v| {
                        stencilImageQueueNode = try self.transLayoutHelper(
                            pTextureSet,
                            renderingInfo.textures[renderingColorTextureLen + 1],
                            0,
                            1,
                            v[0].imageLayout,
                            .graphic,
                            commandType,
                        );
                    }
                }

                // const oldSrcQueueType = self.vulkan.buffers.getBufferQueueType(copyBuffer.srcBuffer);
                // if (oldSrcQueueType != .transfer) {
                //     if (oldSrcQueueType != .init) {
                //         const regions = self.stackAllocator.alloc(drawC.SizeOffset, tempRegions.len) catch unreachable;
                //         defer self.stackAllocator.free(regions);
                //         for (tempRegions, regions) |region, *sizeOffset| {
                //             sizeOffset.offset = region.srcOffset;
                //             sizeOffset.size = region.size;
                //         }
                //         srcBufferNode = try self.addCommand2(.changeBufferQueue, .{ .changeBufferQueue = .{
                //             .buffer = copyBuffer.srcBuffer,
                //             .srcQueueFamily = oldSrcQueueType,
                //             .dstQueueFamily = .transfer,
                //             .regions = regions,
                //         } }, commandType);
                //     }
                //     self.vulkan.buffers.changeQueueType(ptr.value_ptr.command.copyBuffer.srcBuffer, .transfer);
                // }
            },
            .copyBuffer => {
                node.data.commandPoolType = .transfer;

                const copyBuffer = ptr.value_ptr.command.copyBuffer;
                const tempRegions = copyBuffer.regions;
                var srcBufferNode: twoQueueNode = .{};
                var dstBufferNode: twoQueueNode = .{};

                const oldSrcQueueType = self.vulkan.buffers.getBufferQueueType(copyBuffer.srcBuffer);
                if (oldSrcQueueType != .transfer) {
                    if (oldSrcQueueType != .init) {
                        const regions = self.stackAllocator.alloc(drawC.SizeOffset, tempRegions.len) catch unreachable;
                        defer self.stackAllocator.free(regions);
                        for (tempRegions, regions) |region, *sizeOffset| {
                            sizeOffset.offset = region.srcOffset;
                            sizeOffset.size = region.size;
                        }
                        srcBufferNode = try self.addCommand2(.changeBufferQueue, .{ .changeBufferQueue = .{
                            .buffer = copyBuffer.srcBuffer,
                            .srcQueueFamily = oldSrcQueueType,
                            .dstQueueFamily = .transfer,
                            .regions = regions,
                        } }, commandType);
                    }
                    self.vulkan.buffers.changeQueueType(ptr.value_ptr.command.copyBuffer.srcBuffer, .transfer);
                }

                const oldDstQueueType = self.vulkan.buffers.getBufferQueueType(copyBuffer.dstBuffer);
                if (oldDstQueueType != .transfer) {
                    if (oldDstQueueType != .init) {
                        const regions = self.stackAllocator.alloc(drawC.SizeOffset, tempRegions.len) catch unreachable;
                        defer self.stackAllocator.free(regions);
                        for (tempRegions, regions) |region, *sizeOffset| {
                            sizeOffset.offset = region.dstOffset;
                            sizeOffset.size = region.size;
                        }

                        dstBufferNode = try self.addCommand2(.changeBufferQueue, .{ .changeBufferQueue = .{
                            .buffer = copyBuffer.dstBuffer,
                            .srcQueueFamily = oldDstQueueType,
                            .dstQueueFamily = .transfer,
                            .regions = regions,
                        } }, commandType);
                    }
                    self.vulkan.buffers.changeQueueType(ptr.value_ptr.command.copyBuffer.dstBuffer, .transfer);
                }

                var nodes = [_]twoQueueNode{ srcBufferNode, dstBufferNode };
                const res = try self.nodeConnect(&nodes);

                if (res.a) |aa| {
                    try res.b.?.childrenAppend(&currentNode.ID);
                    try currentNode.parentsAppend(&res.b.?.ID);

                    currentNode = aa;
                }

                ptr.value_ptr.*.command.copyBuffer.regions = try self.allocator.dupe(vk.VkBufferCopy2, tempRegions);

                try self.cacheMap.put(@ptrCast(copyBuffer.dstBuffer), ID);
            },
            .copyBufferToImage => {
                node.data.commandPoolType = .transfer;

                const textureSet = ptr.value_ptr.command.copyBufferToImage.pTextureSet;
                ptr.value_ptr.command.copyBufferToImage.dstImage = textureSet.getVkImage(ptr.value_ptr.command.copyBufferToImage.pTexture);

                const copyBufferToImage = ptr.value_ptr.command.copyBufferToImage;

                const imageQueueNode = try self.transLayoutHelper(
                    textureSet,
                    copyBufferToImage.pTexture,
                    copyBufferToImage.baseArrayLayer,
                    copyBufferToImage.layerCount,
                    vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                    .transfer,
                    commandType,
                );

                const bufferQueuqType = self.vulkan.buffers.getBufferQueueType(copyBufferToImage.buffer);
                var bufferQueueNode: twoQueueNode = .{};
                if (bufferQueuqType != .transfer) {
                    if (bufferQueuqType != .init) {
                        var region = [1]drawC.SizeOffset{.{
                            .offset = 0,
                            .size = self.vulkan.buffers.getBufferSize(copyBufferToImage.buffer),
                        }};

                        bufferQueueNode = try self.addCommand2(.changeBufferQueue, .{ .changeBufferQueue = .{
                            .buffer = copyBufferToImage.buffer,
                            .srcQueueFamily = bufferQueuqType,
                            .dstQueueFamily = .transfer,
                            .regions = &region,
                        } }, commandType);
                    }
                    self.vulkan.buffers.changeQueueType(copyBufferToImage.buffer, .transfer);
                }

                var nodes = [_]twoQueueNode{ imageQueueNode, bufferQueueNode };

                const res = try self.nodeConnect(&nodes);
                if (res.a) |aa| {
                    if (res.b) |bb| {
                        try bb.childrenAppend(&currentNode.ID);
                        try currentNode.parentsAppend(&bb.ID);
                    } else {
                        try aa.childrenAppend(&currentNode.ID);
                        try currentNode.parentsAppend(&aa.ID);
                    }

                    currentNode = aa;
                }

                try self.cacheMap.put(@ptrCast(copyBufferToImage.dstImage), ID);
            },
            else => {
                std.debug.panic("not supported commandType {s}", .{@tagName(commandType)});
            },
        }
        zone2.deinit();

        // self.nodeDag.print();

        const zone3 = tracy.initZone(@src(), .{ .name = "infer dependency 2" });
        errdefer zone3.deinit();

        const comm = self.queue.get(currentNode.ID).?;
        switch (comm.commandType) {
            .pipelineBarrier => {
                const pipelineBarrier = comm.command.pipelineBarrier;

                if (pipelineBarrier.lastSrcStageMask == vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT) {
                    const root = self.nodeDag.get(0).?;
                    try root.childrenAppend(&currentNode.ID);
                    try currentNode.parentsAppend(&root.ID);
                } else {
                    std.debug.panic("not supported", .{});
                }
            },
            .copyBuffer => {
                const copyBuffer = comm.command.copyBuffer;

                const index_ = self.cacheMap.get(@ptrCast(copyBuffer.srcBuffer));
                if (index_) |idnex| {
                    const prev = self.nodeDag.get(idnex).?;
                    if (prev == node) {
                        const root = self.nodeDag.get(0).?;
                        try root.childrenAppend(&currentNode.ID);
                        try currentNode.parentsAppend(&root.ID);
                    } else {
                        try prev.childrenAppend(&currentNode.ID);
                        try currentNode.parentsAppend(&prev.ID);
                    }
                } else {
                    const root = self.nodeDag.get(0).?;
                    try root.childrenAppend(&currentNode.ID);
                    try currentNode.parentsAppend(&root.ID);
                }
            },
            .draw2D => {},
            else => {
                std.debug.panic("not supported command type {s}", .{@tagName(comm.commandType)});
            },
        }
        zone3.deinit();

        // self.nodeDag.print();
    }

    /// complete dependency
    pub fn addCommandEnd(self: *Self) !void {
        nodeDagPrint(&self.nodeDag);

        const zone = tracy.initZone(@src(), .{ .name = "add command end" });
        defer zone.deinit();

        self.executeSemaphore.post();
    }

    fn record(command: *drawC, commandBuffer: vk.VkCommandBuffer, stackAllocator: std.mem.Allocator, vulkan: *VkStruct) void {
        const zone = tracy.initZone(@src(), .{ .name = "record vulkan command" });
        defer zone.deinit();

        switch (command.commandType) {
            .copyBufferToImage => {
                const innerZone = tracy.initZone(@src(), .{ .name = "copy buffer to image" });
                defer innerZone.deinit();
                const copyBufferToImage = command.command.copyBufferToImage;
                // std.log.debug("offset {d}", .{copyBufferToImage.buffer.info.offset});
                var region = vk.VkBufferImageCopy2{
                    .sType = vk.VK_STRUCTURE_TYPE_BUFFER_IMAGE_COPY_2,
                    .pNext = null,
                    .bufferImageHeight = copyBufferToImage.bufferImageHegiht,
                    .bufferOffset = 0,
                    .bufferRowLength = copyBufferToImage.bufferRowLength,
                    .imageExtent = .{
                        .width = copyBufferToImage.width,
                        .height = copyBufferToImage.height,
                        .depth = copyBufferToImage.depth,
                    },
                    .imageOffset = copyBufferToImage.imageOffset,
                    .imageSubresource = .{
                        .aspectMask = copyBufferToImage.aspectMask,
                        .mipLevel = copyBufferToImage.mipLevel,
                        .layerCount = copyBufferToImage.layerCount,
                        .baseArrayLayer = copyBufferToImage.baseArrayLayer,
                    },
                };

                std.log.debug("buffer usage {s}", .{
                    @tagName(vulkan.buffers.getBufferUsage(copyBufferToImage.buffer)),
                });
                var copyBufferToImageInfo2 = vk.VkCopyBufferToImageInfo2{
                    .sType = vk.VK_STRUCTURE_TYPE_COPY_BUFFER_TO_IMAGE_INFO_2,
                    .pNext = null,
                    .srcBuffer = vulkan.buffers.getVkBuffer(copyBufferToImage.buffer),
                    .dstImage = copyBufferToImage.dstImage,
                    .dstImageLayout = copyBufferToImage.dstImageLayout,
                    .regionCount = 1,
                    .pRegions = &region,
                };

                vk.vkCmdCopyBufferToImage2(
                    commandBuffer,
                    &copyBufferToImageInfo2,
                );
            },
            .start => {},
            .pipelineBarrier => {
                const innerZone = tracy.initZone(@src(), .{ .name = "pipeline barrier" });
                defer innerZone.deinit();

                const pipelineBarrier = command.command.pipelineBarrier;
                var imageMemoryBarrierCount: u32 = 0;
                var bufferMemoryBarrierCount: u32 = 0;
                var memoryBarrierCount: u32 = 0;

                for (pipelineBarrier.barriers) |barrier| {
                    switch (barrier) {
                        .imageMemory => {
                            imageMemoryBarrierCount += 1;
                        },
                        .bufferMemory => {
                            bufferMemoryBarrierCount += 1;
                        },
                        .memory => {
                            memoryBarrierCount += 1;
                        },
                    }
                }

                var imageMemoryBarriers = std.ArrayList(vk.VkImageMemoryBarrier2).initCapacity(stackAllocator, imageMemoryBarrierCount) catch |err| {
                    std.log.err("stack alloc error {s}\n", .{@errorName(err)});
                    std.debug.panic("stack alloc error", .{});
                };
                defer imageMemoryBarriers.deinit(stackAllocator);
                var bufferMemoryBarriers = std.ArrayList(vk.VkBufferMemoryBarrier2).initCapacity(stackAllocator, bufferMemoryBarrierCount) catch |err| {
                    std.log.err("stack alloc error {s}\n", .{@errorName(err)});
                    std.debug.panic("stack alloc error", .{});
                };
                defer bufferMemoryBarriers.deinit(stackAllocator);
                var memoryBarriers = std.ArrayList(vk.VkMemoryBarrier2).initCapacity(stackAllocator, memoryBarrierCount) catch |err| {
                    std.log.err("stack alloc error {s}\n", .{@errorName(err)});
                    std.debug.panic("stack alloc error", .{});
                };
                defer memoryBarriers.deinit(stackAllocator);

                for (pipelineBarrier.barriers) |barrier| {
                    switch (barrier) {
                        .imageMemory => {
                            const ptr = imageMemoryBarriers.addOneAssumeCapacity();
                            ptr.* = vk.VkImageMemoryBarrier2{
                                .sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
                                .pNext = null,
                                .srcStageMask = barrier.imageMemory.srcStageMask,
                                .srcAccessMask = barrier.imageMemory.srcAccessMask,
                                .dstStageMask = barrier.imageMemory.dstStageMask,
                                .dstAccessMask = barrier.imageMemory.dstAccessMask,
                                .oldLayout = barrier.imageMemory.oldLayout,
                                .newLayout = barrier.imageMemory.newLayout,
                                .srcQueueFamilyIndex = barrier.imageMemory.srcQueueFamilyIndex,
                                .dstQueueFamilyIndex = barrier.imageMemory.dstQueueFamilyIndex,
                                .image = barrier.imageMemory.image,
                                .subresourceRange = barrier.imageMemory.subresourceRange,
                            };
                        },
                        .bufferMemory => {
                            const ptr = bufferMemoryBarriers.addOneAssumeCapacity();
                            ptr.* = vk.VkBufferMemoryBarrier2{
                                .sType = vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER_2,
                                .pNext = null,
                                .srcStageMask = barrier.bufferMemory.srcStageMask,
                                .srcAccessMask = barrier.bufferMemory.srcAccessMask,
                                .dstStageMask = barrier.bufferMemory.dstStageMask,
                                .dstAccessMask = barrier.bufferMemory.dstAccessMask,
                                .srcQueueFamilyIndex = barrier.bufferMemory.srcQueueFamilyIndex,
                                .dstQueueFamilyIndex = barrier.bufferMemory.dstQueueFamilyIndex,
                                .buffer = barrier.bufferMemory.buffer,
                                .offset = barrier.bufferMemory.offset,
                                .size = barrier.bufferMemory.size,
                            };
                        },
                        .memory => {
                            const ptr = memoryBarriers.addOneAssumeCapacity();
                            ptr.* = vk.VkMemoryBarrier2{
                                .sType = vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER_2,
                                .pNext = null,
                                .srcStageMask = barrier.memory.srcStageMask,
                                .srcAccessMask = barrier.memory.srcAccessMask,
                                .dstStageMask = barrier.memory.dstStageMask,
                                .dstAccessMask = barrier.memory.dstAccessMask,
                            };
                        },
                    }
                }
                var dependencyInfo = vk.VkDependencyInfo{
                    .sType = vk.VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
                    .pNext = null,
                    .dependencyFlags = 0,
                    .memoryBarrierCount = memoryBarrierCount,
                    .pMemoryBarriers = memoryBarriers.items.ptr,
                    .bufferMemoryBarrierCount = bufferMemoryBarrierCount,
                    .pBufferMemoryBarriers = bufferMemoryBarriers.items.ptr,
                    .imageMemoryBarrierCount = imageMemoryBarrierCount,
                    .pImageMemoryBarriers = imageMemoryBarriers.items.ptr,
                };
                vk.vkCmdPipelineBarrier2(
                    commandBuffer,
                    &dependencyInfo,
                );
            },
            .copyBuffer => {
                const innerZone = tracy.initZone(@src(), .{ .name = "copy buffer" });
                defer innerZone.deinit();

                const copyBuffer = command.command.copyBuffer;
                var bufferCopyInfo = vk.VkCopyBufferInfo2{
                    .sType = vk.VK_STRUCTURE_TYPE_COPY_BUFFER_INFO_2,
                    .pNext = null,
                    .srcBuffer = vulkan.buffers.getVkBuffer(copyBuffer.srcBuffer),
                    .dstBuffer = vulkan.buffers.getVkBuffer(copyBuffer.dstBuffer),
                    .regionCount = @intCast(copyBuffer.regions.len),
                    .pRegions = @ptrCast(copyBuffer.regions.ptr),
                };
                vk.vkCmdCopyBuffer2(
                    commandBuffer,
                    &bufferCopyInfo,
                );
            },
            else => {
                std.debug.panic("unsupported command type {s}", .{@tagName(command.commandType)});
            },
        }
    }

    fn judgeStage(command: *drawC) vk.VkPipelineStageFlags {
        const zone = tracy.initZone(@src(), .{ .name = "judge pipeline stage" });
        defer zone.deinit();

        _ = command;
        return vk.VK_PIPELINE_STAGE_ALL_COMMANDS_BIT;
    }

    pub fn recordCommand(ctx: *ThreadContext) !void {
        tracy.setThreadName("record command");
        defer tracy.message("record command exit");

        var stackMemory = [_]u8{0} ** global.StackMemorySize;
        var stackAllocator = std.heap.FixedBufferAllocator.init(stackMemory[0..]);
        const sma = stackAllocator.allocator();

        var commandBuffer: vk.VkCommandBuffer = null;
        var cbb: *CommandBufferBelong = undefined;

        while (true) {
            ctx.semaphore.wait();

            const command = ctx.taskQueue.popFirst();
            if (command) |comm| {
                const com = comm.com;
                if (com.commandType == .beginSecondaryRecord) {
                    commandBuffer = try ctx.commandPool.getSecondaryCommandBuffer(ctx.commandPoolType, ctx.vulkan);
                    {
                        ctx.mutex.lock();
                        defer ctx.mutex.unlock();

                        const temp = try ctx.commandBuffers.create();
                        temp.data = CommandBufferBelong{
                            .commandBufer = commandBuffer,
                            .kind = if (ctx.commandPoolType == .graphic) .Graphic else if (ctx.commandPoolType == .compute) .Compute else .Other,
                            .commandBufferID = temp.ID,
                        };
                        cbb = &temp.data;
                        comm.node.data.commandBufferID = cbb.commandBufferID;
                    }

                    const renderinged = com.command.beginRecoed.rendering;
                    var flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
                    if (renderinged) flags |= vk.VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT;

                    var InRenderingInfo = if (renderinged) vk.VkCommandBufferInheritanceRenderingInfo{
                        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_RENDERING_INFO,
                        .flags = com.command.beginRecoed.flags,
                        .pNext = null,
                        .viewMask = com.command.beginRecoed.viewMask,
                        .colorAttachmentCount = @intCast(com.command.beginRecoed.pColorAttachmentFormats.len),
                        .pColorAttachmentFormats = @ptrCast(com.command.beginRecoed.pColorAttachmentFormats.ptr),
                        .depthAttachmentFormat = com.command.beginRecoed.depthAttachmentFormat,
                        .stencilAttachmentFormat = com.command.beginRecoed.stencilAttachmentFormat,
                        .rasterizationSamples = com.command.beginRecoed.rasterizationSamples,
                    } else null;
                    var InInfo = vk.VkCommandBufferInheritanceInfo{
                        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO,
                        .pNext = if (renderinged) @ptrCast(&InRenderingInfo) else null,
                        .renderPass = null,
                        .framebuffer = null,
                        .subpass = 0,
                        .occlusionQueryEnable = if (renderinged) com.command.beginRecoed.occulusionQueryEnable else vk.VK_FALSE,
                        .queryFlags = if (renderinged) com.command.beginRecoed.queryFlags else vk.VK_FALSE,
                        .pipelineStatistics = if (renderinged) com.command.beginRecoed.pipelineStatistics else vk.VK_FALSE,
                    };
                    try VkStruct._beginCommandBuffer(commandBuffer, null, @intCast(flags), &InInfo);
                    continue;
                }

                comm.node.data.commandBufferID = cbb.commandBufferID;

                if (com.commandType == .endRecord) {
                    try VkStruct.endCommandBuffer(commandBuffer);
                    ctx.threadPool.releaseThread(ctx.index);
                    cbb.semaphore.post();
                } else if (com.commandType == .end) {
                    break;
                } else {
                    record(com, cbb.commandBufer, sma, ctx.vulkan);
                }
            } else {
                break;
            }
        }
    }

    fn getGarbage(command: *drawC) ?garbageData {
        const zone = tracy.initZone(@src(), .{ .name = "get garbage" });
        defer zone.deinit();

        return rs: switch (command.commandType) {
            .copyBufferToImage => {
                if (command.command.copyBufferToImage.clean) {
                    break :rs garbageData{ .buffer = command.command.copyBufferToImage.buffer };
                } else {
                    break :rs null;
                }
            },
            .pipelineBarrier => break :rs garbageData{ .barriers = command.command.pipelineBarrier.barriers },
            .copyBuffer => {
                if (command.command.copyBuffer.clean) {
                    break :rs garbageData{ .bufferAndRegion = .{
                        .buffer = command.command.copyBuffer.srcBuffer,
                        .region = command.command.copyBuffer.regions,
                    } };
                } else {
                    break :rs garbageData{ .regions = command.command.copyBuffer.regions };
                }
            },
            .start => null,
            else => {
                std.debug.panic("not support {s}", .{@tagName(command.commandType)});
            },
        };
    }

    fn collectGarbage(self: *Self, command: *drawC, currentSemaphoreValue: u64) !void {
        const zone = tracy.initZone(@src(), .{ .name = "collect garbage" });
        defer zone.deinit();

        if (getGarbage(command)) |g| {
            const temp = try self.garbageData.addOne();
            temp.* = .{ .data = g, .semaphoreValue = currentSemaphoreValue + 1 };
        }
    }

    pub fn cleanGarbage(self: *Self) !void {
        const zone = tracy.initZone(@src(), .{ .name = "clean garbage" });
        defer zone.deinit();

        const currentSemaphoreValue = try self.vulkan.getSemaphoreCounterValue(self.vulkan.globalTimelineSemaphore);

        for (self.garbageData.items, 0..) |g, i| {
            switch (g.data) {
                .buffer => {
                    if (currentSemaphoreValue < g.semaphoreValue) continue;
                    self.vulkan.destroyBuffer(g.data.buffer);
                    self.garbageData.items[i] = .{ .data = .{ .empty = void{} }, .semaphoreValue = 0 };
                },
                .barriers => {
                    self.allocator.free(g.data.barriers);
                    self.garbageData.items[i] = .{ .data = .{ .empty = void{} }, .semaphoreValue = 0 };
                },
                .bufferAndRegion => {
                    if (currentSemaphoreValue < g.semaphoreValue) continue;
                    self.vulkan.destroyBuffer(g.data.bufferAndRegion.buffer);
                    self.allocator.free(g.data.bufferAndRegion.region);
                    self.garbageData.items[i] = .{ .data = .{ .empty = void{} }, .semaphoreValue = 0 };
                },
                .regions => {
                    self.allocator.free(g.data.regions);
                    self.garbageData.items[i] = .{ .data = .{ .empty = void{} }, .semaphoreValue = 0 };
                },
                .empty => {},
            }
        }

        var saveLen: usize = 0;
        for (self.garbageData.items, 0..) |g, i| {
            if (g.data != .empty) {
                if (saveLen != i) {
                    self.garbageData.items[saveLen] = g;
                }
                saveLen += 1;
            }
        }

        // self.garbageData.clearRetainingCapacity();
        self.garbageData.items.len = saveLen;
    }

    // a thread pool specialy for render
    // task queue, semaphore,
    pub fn executeCommands(self: *Self) !void {
        const zone = tracy.initZone(@src(), .{ .name = "execute all command in one time command" });
        defer zone.deinit();

        self.executeSemaphore.wait();

        self.mutex.lock();
        defer self.mutex.unlock();

        // self.nodeDag.print();

        try self.cleanGarbage();

        defer {
            self.nodeDag.clearRetainCapacity();
            self.queue.clearRetainingCapacity();
            self.cacheMap.clearRetainingCapacity();

            self.innerCommandBufferID = 0;
            self.innerID = 0;
        }

        const taskQueueStruct = struct {
            queueNode: *QueueNode,
            threadCtx: ?*ThreadContext,
        };
        var prepareToExecuteQueue: Queue(taskQueueStruct) = undefined;
        prepareToExecuteQueue.init(self.allocator);
        defer prepareToExecuteQueue.deinit();

        var inferNodeNextTaskQueue: Queue(taskQueueStruct) = undefined;
        inferNodeNextTaskQueue.init(self.allocator);
        defer inferNodeNextTaskQueue.deinit();

        var finalPrimaryTaskQueue = std.array_list.Managed(*QueueNode).init(self.allocator);
        defer finalPrimaryTaskQueue.deinit();

        var commandBufferss = commandBufferDAG.init(self.allocator);
        defer commandBufferss.deinit();

        // xxx
        const root = self.nodeDag.get(0);
        if (root) |rr| {
            try prepareToExecuteQueue.pushLast(taskQueueStruct{
                .queueNode = rr,
                .threadCtx = null,
            });
        } else {
            return;
        }

        var iterateCount: u64 = 0;
        while (true) {
            // std.log.debug("0", .{});
            iterateCount += 1;
            const pTotalSize = prepareToExecuteQueue.totalSize;
            // std.log.debug("pTotalSize: {d}", .{pTotalSize});
            if (pTotalSize == 0) break;

            var pNode = prepareToExecuteQueue.popFirst();

            var executeCount: u32 = 0;
            while (pNode) |nn| {
                const zone2 = tracy.initZone(@src(), .{ .name = "execute a" });
                errdefer zone2.deinit(); // std.log.debug("1", .{}); if (executeCount >= pTotalSize) { zone2.deinit(); break; }
                // judge dependencies first
                if (nn.queueNode.parentsDone < nn.queueNode.parentsLen) {
                    try prepareToExecuteQueue.pushLast(nn);
                    executeCount += 1;
                    try inferNodeNextTaskQueue.pushLast(nn);
                    continue;
                }

                var ctx: ?*ThreadContext = null;
                if (nn.threadCtx == null) {
                    if (nn.queueNode.data.startThread) {
                        ctx = try self.threadPool.getFreeThread(commandBufferss, nn.queueNode.data.commandPoolType, self.vulkan);

                        pNode.?.threadCtx = ctx;
                    }

                    nn.queueNode.data.commandBufferID = std.math.maxInt(u32);

                    if (!nn.queueNode.data.isSecondary) {
                        const temp = try finalPrimaryTaskQueue.addOne();
                        temp.* = nn.queueNode;
                    }
                } else {
                    nn.threadCtx.?.mutex.lock();
                    defer nn.threadCtx.?.mutex.unlock();

                    // nn.queueNode.data.commandBufferID = nn.threadCtx.?.commandBufferID.*;
                    try nn.threadCtx.?.taskQueue.pushLast(.{ .com = self.queue.getPtr(nn.queueNode.ID).?, .node = nn.queueNode });

                    nn.threadCtx.?.semaphore.post();
                }

                nn.queueNode.nodeDone();

                executeCount += 1;
                try inferNodeNextTaskQueue.pushLast(pNode.?);
                pNode = prepareToExecuteQueue.popFirst();
                zone2.deinit();
            }

            var iNode = inferNodeNextTaskQueue.popFirst();
            while (iNode) |nn| {
                const zone2 = tracy.initZone(@src(), .{ .name = "execute b" });
                errdefer zone2.deinit();
                // std.log.debug("2", .{});

                const node = nn.queueNode;
                // std.log.debug("parent {*}", .{node});
                for (node.children.list.items) |ID| {
                    const zone3 = tracy.initZone(@src(), .{ .name = "execute c" });
                    errdefer zone3.deinit();
                    // std.log.debug("3", .{});

                    var first = prepareToExecuteQueue.list.first;
                    const ccc: *QueueNode = @alignCast(@fieldParentPtr("ID", ID));
                    while (first) |jjj| {
                        const aaa: *Queue(taskQueueStruct).DataNode = @fieldParentPtr("node", jjj);
                        if (aaa.data.queueNode == ccc) {
                            prepareToExecuteQueue.remove(aaa.data);
                            break;
                        }
                        first = jjj.next;
                    }

                    try prepareToExecuteQueue.pushLast(.{
                        .queueNode = ccc,
                        .threadCtx = if (ccc.data.isSecondary) nn.threadCtx else null,
                    });
                    // std.log.debug("child {*}", .{ccc});
                    zone3.deinit();
                }
                iNode = inferNodeNextTaskQueue.popFirst();
                zone2.deinit();
            }
            // std.log.debug("", .{});
        }

        // std.log.debug("iterateCount: {d}", .{iterateCount});

        self.nodeDag.undoneAllNodes();

        const nextNodeQueueSemaphoreValue = struct {
            node: *QueueNode,
            semaphoreValue: u64,
        };
        var nextNodeQueue: Queue(nextNodeQueueSemaphoreValue) = undefined;
        nextNodeQueue.init(self.allocator);
        defer nextNodeQueue.deinit();

        var cbIdxs = std.array_list.Managed(u32).init(self.allocator);
        defer cbIdxs.deinit();

        var cbs = std.array_list.Managed(vk.VkCommandBuffer).init(self.allocator);
        defer cbs.deinit();

        // std.log.debug("2\n\n\n\n", .{});
        {
            mutex.lock();
            defer mutex.unlock();

            const currentFrames = self.vulkan.currentFrame.load(.seq_cst);

            const graphicCommandBuffer = try self.primaryCommandPool.getPrimaryCommandBuffer(
                .graphic,
                currentFrames,
                self.vulkan,
            );
            const transferCommandBuffer = try self.primaryCommandPool.getPrimaryCommandBuffer(
                .transfer,
                currentFrames,
                self.vulkan,
            );
            const computeCommandBuffer = try self.primaryCommandPool.getPrimaryCommandBuffer(
                .compute,
                currentFrames,
                self.vulkan,
            );
            var graphicSemaphoreValue, var transferSemaphoreValue, var computeSemaphoreValue, var currentSemaphoreValue =
                va: {
                    const value = self.vulkan.globalTimelineValue.load(.seq_cst);
                    break :va .{ value, value, value, value };
                };

            var waitSemaphoreSubmitInfos =
                std.array_list.Managed(vk.VkSemaphoreSubmitInfo).init(self.allocator);
            defer waitSemaphoreSubmitInfos.deinit();

            var signalSemaphoreSubmitInfos =
                std.array_list.Managed(vk.VkSemaphoreSubmitInfo).init(self.allocator);
            defer signalSemaphoreSubmitInfos.deinit();

            var firstStage: vk.VkPipelineStageFlags = vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT;
            var lastStage: vk.VkPipelineStageFlags = vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;

            var currentCommandBuffer: vk.VkCommandBuffer = null;
            var currentType: VkStruct.CommandPoolType = .graphic;
            var begin = false;
            var first = false;
            var firstSubmit = true;
            var currentIndex: u32 = 0;

            var firstNode = self.nodeDag.get(0);
            const startComm = self.queue.get(0).?;
            const present = startComm.command.start.present;

            var submitInfo = vk.VkSubmitInfo2{
                .sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO_2,
                .pNext = null,
                .flags = 0,
            };

            var timelinewaitValue: u64 = currentSemaphoreValue;
            while (firstNode) |nn| {
                // var it = self.nodeDag.map.valueIterator();
                // while (it.next()) |value| {
                //     std.log.debug("ID: {d} {*}, childrenLen: {d}, childrenDone: {d}, parentLen: {d}, parentDone: {d}, done: {}", .{ value.*.ID, &value.*.node, value.*.childrenLen, value.*.childrenDone, value.*.parentsLen, value.*.parentsDone, value.*.done });
                // }
                // std.log.debug("\n\n", .{});

                if (nn.childrenLen > 1) {
                    try nextNodeQueue.pushLast(.{
                        .node = nn,
                        .semaphoreValue = currentSemaphoreValue,
                    });
                }

                if (begin and nn.data.commandPoolType != currentType) {
                    defer signalSemaphoreSubmitInfos.clearRetainingCapacity();
                    defer waitSemaphoreSubmitInfos.clearRetainingCapacity();

                    try VkStruct.endCommandBuffer(currentCommandBuffer);
                    const temp = try waitSemaphoreSubmitInfos.addOne();
                    // const temp = try waitSemaphores.addOne();
                    temp.sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO;
                    temp.pNext = null;
                    temp.deviceIndex = 0;
                    temp.semaphore = self.vulkan.globalTimelineSemaphore;
                    if (firstSubmit) {
                        temp.stageMask = vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT;
                        firstSubmit = false;
                    } else {
                        temp.stageMask = firstStage;
                    }
                    temp.value = timelinewaitValue;

                    const temp2 = try signalSemaphoreSubmitInfos.addOne();
                    temp2.sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO;
                    temp2.pNext = null;
                    temp2.deviceIndex = 0;
                    temp2.semaphore = self.vulkan.globalTimelineSemaphore;
                    temp2.stageMask = vk.VK_PIPELINE_STAGE_2_BOTTOM_OF_PIPE_BIT;
                    temp2.value = currentSemaphoreValue;

                    var temp3 = vk.VkCommandBufferSubmitInfo{
                        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_SUBMIT_INFO,
                        .pNext = null,
                        .commandBuffer = currentCommandBuffer,
                        .deviceMask = 0,
                    };

                    submitInfo.waitSemaphoreInfoCount = @intCast(waitSemaphoreSubmitInfos.items.len);
                    submitInfo.pWaitSemaphoreInfos = @ptrCast(waitSemaphoreSubmitInfos.items.ptr);
                    submitInfo.commandBufferInfoCount = 1;
                    submitInfo.pCommandBufferInfos = @ptrCast(&temp3);
                    submitInfo.signalSemaphoreInfoCount = @intCast(signalSemaphoreSubmitInfos.items.len);
                    submitInfo.pSignalSemaphoreInfos = @ptrCast(signalSemaphoreSubmitInfos.items.ptr);

                    try self.vulkan.queueSubmit(currentType, 1, &submitInfo, null);

                    switch (currentType) {
                        .graphic => graphicSemaphoreValue = currentSemaphoreValue,
                        .transfer => transferSemaphoreValue = currentSemaphoreValue,
                        .compute => computeSemaphoreValue = currentSemaphoreValue,
                        .present, .init => unreachable,
                    }

                    begin = false;
                }

                if (!begin) {
                    switch (nn.data.commandPoolType) {
                        .graphic => {
                            currentCommandBuffer = graphicCommandBuffer;
                            currentType = .graphic;
                            if (firstSubmit) {
                                try self.vulkan.acquireNextImage(&currentIndex);
                                const temp = try waitSemaphoreSubmitInfos.addOne();
                                temp.sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO;
                                temp.pNext = null;
                                temp.deviceIndex = 0;
                                temp.semaphore = self.vulkan.imageAvailableSemaphore[currentIndex];
                                temp.stageMask = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
                                temp.value = 0;
                            }
                            try self.vulkan.waitSemaphore(1, &self.vulkan.globalTimelineSemaphore, &graphicSemaphoreValue);
                        },
                        .transfer => {
                            currentCommandBuffer = transferCommandBuffer;
                            currentType = .transfer;
                            try self.vulkan.waitSemaphore(1, &self.vulkan.globalTimelineSemaphore, &transferSemaphoreValue);
                        },
                        .compute => {
                            currentCommandBuffer = computeCommandBuffer;
                            currentType = .compute;
                            try self.vulkan.waitSemaphore(1, &self.vulkan.globalTimelineSemaphore, &computeSemaphoreValue);
                        },
                        .init, .present => unreachable,
                    }
                    // try VkStruct.resetCommandBuffer(currentCommandBuffer);
                    try VkStruct._beginCommandBuffer(currentCommandBuffer, null, vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT, null);
                    begin = true;
                    first = true;
                }

                if (nn.parentsDone >= nn.parentsLen) {
                    nn.nodeDone();

                    const command = self.queue.getPtr(nn.ID).?;
                    try self.collectGarbage(command, currentSemaphoreValue);
                    lastStage = judgeStage(command);
                    if (first) {
                        firstStage = lastStage;
                        first = false;
                    }

                    if (nn.data.isSecondary) {
                        if (!bs: {
                            for (cbIdxs.items) |id| {
                                if (id == nn.data.commandBufferID) break :bs true;
                            }
                            break :bs false;
                        }) {
                            const ptr = try cbIdxs.addOne();
                            ptr.* = nn.data.commandBufferID;
                        }
                        continue;
                    } else {
                        for (cbIdxs.items) |id| {
                            const cb = commandBufferss.get(id);
                            if (cb) |cbb| {
                                const cbPtr = try cbs.addOne();
                                cbPtr.* = cbb.data.commandBufer;

                                cbb.data.semaphore.wait();
                            }
                        }
                        if (cbs.items.len > 0)
                            vk.vkCmdExecuteCommands(currentCommandBuffer, @intCast(cbs.items.len), @ptrCast(cbs.items.ptr));

                        record(self.queue.getPtr(nn.ID).?, currentCommandBuffer, self.stackAllocator, self.vulkan);
                    }
                    firstNode = nn.getFirstUndoneChild();
                    if (firstNode == null) {
                        var node = nextNodeQueue.peekLast();
                        while (node) |value| {
                            firstNode = value.node.getFirstUndoneChild();
                            if (firstNode == null) {
                                _ = nextNodeQueue.popLast();
                                node = nextNodeQueue.peekLast();
                            } else {
                                timelinewaitValue = value.semaphoreValue;
                                break;
                            }
                        } else {
                            firstNode = null;
                        }
                    }
                } else {
                    var node = nextNodeQueue.peekLast();
                    while (node) |value| {
                        firstNode = value.node.getFirstUndoneChild();
                        if (firstNode == null) {
                            _ = nextNodeQueue.popLast();
                            node = nextNodeQueue.peekLast();
                        } else {
                            timelinewaitValue = value.semaphoreValue;
                            break;
                        }
                    } else {
                        firstNode = null;
                    }
                }
            }
            // var it = self.nodeDag.map.valueIterator();
            // while (it.next()) |value| {
            //     std.log.debug("ID: {d} {*}, childrenLen: {d}, childrenDone: {d}, parentLen: {d}, parentDone: {d}, done: {}", .{ value.*.ID, &value.*.node, value.*.childrenLen, value.*.childrenDone, value.*.parentsLen, value.*.parentsDone, value.*.done });
            // }
            // std.log.debug("\n\n", .{});

            if (begin) {
                try VkStruct.endCommandBuffer(currentCommandBuffer);

                const temp = try waitSemaphoreSubmitInfos.addOne();
                temp.sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO;
                temp.pNext = null;
                temp.deviceIndex = 0;
                temp.semaphore = self.vulkan.globalTimelineSemaphore;
                if (firstSubmit) {
                    temp.stageMask = vk.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT;
                    firstSubmit = false;
                } else {
                    temp.stageMask = vk.VK_PIPELINE_STAGE_ALL_COMMANDS_BIT;
                }
                temp.value = timelinewaitValue;

                const temp2 = try signalSemaphoreSubmitInfos.addOne();
                temp2.sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO;
                temp2.pNext = null;
                temp2.deviceIndex = 0;
                temp2.semaphore = self.vulkan.globalTimelineSemaphore;
                temp2.stageMask = vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
                currentSemaphoreValue += 1;
                temp2.value = currentSemaphoreValue;

                if (present) {
                    const temp3 = try signalSemaphoreSubmitInfos.addOne();
                    temp3.sType = vk.VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO;
                    temp3.pNext = null;
                    temp3.deviceIndex = 0;
                    temp3.semaphore = self.vulkan.renderFinishSemaphore[currentFrames];
                    temp3.stageMask = vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
                    temp3.value = 0;
                }

                var temp4 = vk.VkCommandBufferSubmitInfo{
                    .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_SUBMIT_INFO,
                    .pNext = null,
                    .commandBuffer = currentCommandBuffer,
                    .deviceMask = 0,
                };

                submitInfo.waitSemaphoreInfoCount = @intCast(waitSemaphoreSubmitInfos.items.len);
                submitInfo.pWaitSemaphoreInfos = @ptrCast(waitSemaphoreSubmitInfos.items.ptr);
                submitInfo.commandBufferInfoCount = 1;
                submitInfo.pCommandBufferInfos = @ptrCast(&temp4);
                submitInfo.signalSemaphoreInfoCount = @intCast(signalSemaphoreSubmitInfos.items.len);
                submitInfo.pSignalSemaphoreInfos = @ptrCast(signalSemaphoreSubmitInfos.items.ptr);

                try self.vulkan.queueSubmit(currentType, 1, &submitInfo, null);
            }

            if (present) {
                var presentInfo = vk.VkPresentInfoKHR{
                    .sType = vk.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
                    .pNext = null,
                    .waitSemaphoreCount = 1,
                    .pWaitSemaphores = @ptrCast(&self.vulkan.renderFinishSemaphore[currentFrames]),
                    .swapchainCount = 1,
                    .pSwapchains = @ptrCast(&self.vulkan.swapchain),
                    .pImageIndices = @ptrCast(&currentIndex),
                    .pResults = null,
                };
                try self.vulkan.presentSubmit(@ptrCast(&presentInfo));
            }

            self.vulkan.globalTimelineValue.store(currentSemaphoreValue, .seq_cst);
        }

        for (0..self.threadPool.info.len) |i| {
            if (self.threadPool.info[i]) |*ctxA| {
                self.threadPool.releaseThread(ctxA.index);

                ctxA.commandPool.markSecondaryCommandBufferFree();
            }
        }
    }
};
