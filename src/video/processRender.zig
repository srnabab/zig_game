const std = @import("std");
const Thread = std.Thread;
const Atomic = std.atomic;
const drawC = @import("drawCommand.zig");
// const drawCProcess = @import("drawCommandProcess.zig");
const texture = @import("textureSet");
const vk = @import("vulkan").vulkan;
const VkStruct = @import("video");
const Queue = @import("queue").Queue;
const global = @import("global");
const tracy = @import("tracy");

var mutex = Thread.Mutex{};

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

    pub fn getFreeBuffer(self: *Self) !vk.VkCommandBuffer {
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

                try global.vulkan._createCommandBuffers(null, pool, vk.VK_COMMAND_BUFFER_LEVEL_SECONDARY, 1, @ptrCast(&cb));

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

    pub fn initPrimary(commandPooll: vk.VkCommandPool) !Self {
        var cbs: [2]vk.VkCommandBuffer = undefined;
        try global.vulkan._createCommandBuffers(null, commandPooll, vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY, 2, @ptrCast(&cbs));

        return .{
            .commandPool = commandPooll,
            .primaryCommandBuffer = cbs,
        };
    }

    pub fn initWithSecondary(allocator: std.mem.Allocator, commandPooll: vk.VkCommandPool, secondarySize: usize) !Self {
        var cbs: [2]vk.VkCommandBuffer = undefined;
        try global.vulkan._createCommandBuffers(null, commandPooll, vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY, 2, @ptrCast(&cbs));
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

    pub fn getPrimaryCommandBuffer(self: *Self, kind: VkStruct.CommandPoolType, index: u32) !vk.VkCommandBuffer {
        const zone = tracy.initZone(@src(), .{ .name = "get primary command buffer" });
        defer zone.deinit();

        const idx: u32 = switch (kind) {
            .graphic => 0,
            .transfer => 1,
            .compute => 2,
        };
        if (self.commandPools[idx]) |p| {
            return p.primaryCommandBuffer[index];
        } else {
            var commandPool: vk.VkCommandPool = null;
            try global.vulkan._createCommandPool(null, kind, vk.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT, @ptrCast(&commandPool));
            self.commandPools[idx] = if (self.secondarySizes[idx] > 0)
                try .initWithSecondary(self.allocator, commandPool, self.secondarySizes[idx])
            else
                try .initPrimary(commandPool);

            return self.commandPools[idx].?.primaryCommandBuffer[index];
        }
    }

    pub fn getSecondaryCommandBuffer(self: *Self, kind: VkStruct.CommandPoolType) !vk.VkCommandBuffer {
        const zone = tracy.initZone(@src(), .{ .name = "get secondary command buffer" });
        defer zone.deinit();

        const idx: u32 = switch (kind) {
            .graphic => 0,
            .transfer => 1,
            .compute => 2,
        };

        if (self.commandPools[idx]) |*p| {
            if (self.secondarySizes[idx] > 0)
                return p.secondaryCommandBuffers.?.getFreeBuffer();
        } else {
            var commandPool: vk.VkCommandPool = null;
            try global.vulkan._createCommandPool(null, kind, vk.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT, @ptrCast(&commandPool));
            self.commandPools[idx] = if (self.secondarySizes[idx] > 0)
                try .initWithSecondary(self.allocator, commandPool, self.secondarySizes[idx])
            else
                try .initPrimary(commandPool);

            if (self.secondarySizes[idx] > 0)
                return self.commandPools[idx].?.secondaryCommandBuffers.?.getFreeBuffer();
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

    pub fn deinit(self: *Self) void {
        for (0..self.commandPools.len) |i| {
            if (self.commandPools[i] != null) {
                self.commandPools[i].?.deinit(self.allocator);
                global.vulkan.destroyCommandPool(self.commandPools[i].?.commandPool);
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

        pub fn getFreeThread(self: *Self, commandBufferQueue: commandBufferDAG, commandPoolType: VkStruct.CommandPoolType) !*ThreadContext {
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

        pub fn waitThread(self: *Self) void {
            for (0..self.threads.len) |i| {
                var end = drawC{
                    .commandType = .end,
                    .ID = 1234124142,
                    .command = .{ .empty = void{} },
                    .output = .{ .empty = void{} },
                };
                var emptyQueueNode: QueueNode = .{};

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
                    self.info[i].?.commandPool.deinit();
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

        parents: std.DoublyLinkedList = .{},
        parentsLen: u32 = 0,
        parentsDone: u32 = 0,

        children: std.DoublyLinkedList = .{},
        childrenLen: u32 = 0,
        childrenDone: u32 = 0,

        done: bool = false,

        data: T = undefined,

        node: std.DoublyLinkedList.Node = .{},

        pub fn parentsAppend(self: *Self, node: *std.DoublyLinkedList.Node) void {
            self.parents.append(node);
            self.parentsLen += 1;
        }

        pub fn parentsPopFirst(self: *Self) ?*std.DoublyLinkedList.Node {
            self.parentsLen -= 1;
            return self.parents.popFirst();
        }

        pub fn childrenAppend(self: *Self, node: *std.DoublyLinkedList.Node) void {
            self.children.append(node);
            self.childrenLen += 1;
        }

        pub fn childrenPopFirst(self: *Self) ?*std.DoublyLinkedList.Node {
            self.childrenLen -= 1;
            return self.children.popFirst();
        }

        pub fn childrenParentsLensMinusOne(self: *Self) void {
            var node = self.children.first;
            while (node) |nn| {
                var ll: *Self = @fieldParentPtr("node", nn);
                ll.parentsLen -= 1;
                node = nn.next;
            }
        }

        pub fn clearParents(self: *Self) void {
            self.parents = .{};
            self.parentsLen = 0;
            self.parentsDone = 0;
        }

        pub fn clearChildren(self: *Self) void {
            self.children = .{};
            self.childrenLen = 0;
            self.childrenDone = 0;
        }

        pub fn insertPrev(self: *Self, prev: *Self) void {
            const parents = self.parents;
            prev.parents = parents;
            prev.parentsLen = self.parentsLen;
            self.clearParents();
            self.parentsAppend(&prev.node);
            prev.childrenAppend(&self.node);

            var first = parents.first;
            while (first) |nn| {
                var ll: *Self = @fieldParentPtr("node", nn);

                ll.children.remove(&self.node);
                ll.children.append(&prev.node);

                first = nn.next;
            }
        }

        pub fn insertNext(self: *Self, next: *Self) void {
            const children = self.children;
            next.children = children;
            next.childrenLen = self.parentsLen;
            self.clearChildren();
            self.childrenAppend(&next.node);
            next.parentsAppend(&self.node);

            var first = children.first;
            while (first) |nn| {
                var ll: *Self = @fieldParentPtr("node", nn);

                ll.parents.remove(&self.node);
                ll.parents.append(&next.node);

                first = nn.next;
            }
        }

        pub fn nodeDone(self: *Self) void {
            const zone = tracy.initZone(@src(), .{ .name = "node done" });
            defer zone.deinit();

            self.done = true;

            var first = self.children.first;
            while (first) |nn| {
                var ll: *Self = @fieldParentPtr("node", nn);

                ll.parentsDone += 1;

                first = nn.next;
            }

            first = self.parents.first;
            while (first) |nn| {
                var ll: *Self = @fieldParentPtr("node", nn);

                ll.childrenDone += 1;

                first = nn.next;
            }
        }

        pub fn getFirstUndoneChild(self: *Self) ?*Self {
            const zone = tracy.initZone(@src(), .{ .name = "get first undone child" });
            defer zone.deinit();

            if (self.childrenLen == self.childrenDone) return null;

            var first = self.children.first;
            while (first) |nn| {
                const ll: *Self = @fieldParentPtr("node", nn);

                if (ll.done) {
                    continue;
                } else {
                    return ll;
                }

                first = nn.next;
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

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .mem = .init(allocator),
                .map = .init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
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
            node.* = .{ .ID = self.innerID };

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
            }
        }
    };
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
};
const garbageData = union(garbageDataTag) {
    buffer: VkStruct.Buffer,
};

pub const oneTimeCommand = struct {
    const Self = @This();

    // pub const TaskCallback = *const fn (ctx: *anyopaque) VkStruct.VkError!void;
    // const EnqueueTaskCallback = *const fn (taskCallback: TaskCallback, taskCtx: *anyopaque, userCtx: *anyopaque) *anyopaque;
    // const FinishTaskCallback = *const fn (userTask: *anyopaque, userCtx: *anyopaque) void;

    innerID: u32 = 0,
    innerCommandBufferID: u32 = 0,
    queue: std.hash_map.AutoHashMap(u32, drawC),
    nodeDag: QueueNodes,

    primaryCommandPool: CommandPools,

    allocator: std.mem.Allocator,
    stackAllocator: std.mem.Allocator,

    threadPool: SpecialThreadPool(MaxThreads),
    mutex: Thread.Mutex = .{},
    executeSemaphore: Thread.Semaphore = .{},

    garbageData: std.array_list.Managed(garbageData),

    // commandPools: std.array_list.Managed(vk.VkCommandPool),

    pub fn init(allocator: std.mem.Allocator, stackAllocator: std.mem.Allocator) Self {
        return Self{
            .queue = .init(allocator),
            .allocator = allocator,
            .nodeDag = .init(allocator),
            .threadPool = .init(allocator),
            .primaryCommandPool = .init(allocator, 0, 0, 0),
            .garbageData = .init(allocator),
            .stackAllocator = stackAllocator,
        };
    }

    pub fn deinit(self: *Self) void {
        const zone = tracy.initZone(@src(), .{ .name = "deinit OnetimeCommand" });
        defer zone.deinit();

        var waitValue = global.vulkan.globalTimelineValue.load(.seq_cst);
        global.vulkan.waitSemaphore(
            1,
            &global.vulkan.globalTimelineSemaphore,
            &waitValue,
        ) catch |err| {
            std.log.err("wait semaphore error {s}\n", .{@errorName(err)});
        };
        self.queue.deinit();
        self.nodeDag.deinit();
        self.threadPool.waitThread();
        self.primaryCommandPool.deinit();
        self.cleanGarbage() catch |err| {
            std.log.err("clean garbage error {s}\n", .{@errorName(err)});
        };
        self.garbageData.deinit();
    }

    fn getOuput(commandType: drawC.CommandType, command: drawC.comm) drawC.Output {
        const zone = tracy.initZone(@src(), .{ .name = "get output OnetimeCommand" });
        defer zone.deinit();

        return rs: switch (commandType) {
            .start, .beginPrimaryRecord, .beginRendering, .beginSecondaryRecord, .endRendering, .endRecord, .present, .graphic, .copyBufferToImage, .graphicTransfer, .transfer, .end => {
                break :rs drawC.Output{ .empty = void{} };
            },
            .transLayout => {
                break :rs drawC.Output{ .image = command.transLayout.pTexture.image.vkImage };
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

    fn inferTransLayoutFlagsByOldLayoutAndNewLayout(command: *drawC) void {
        const zone = tracy.initZone(@src(), .{ .name = "infer trans layout" });
        defer zone.deinit();

        if (command.commandType != .transLayout) return;

        switch (command.command.transLayout.oldLayout) {
            vk.VK_IMAGE_LAYOUT_UNDEFINED => {
                command.command.transLayout.srcAccessMask = vk.VK_ACCESS_NONE;
                command.command.transLayout.sourceStage = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
                command.command.transLayout.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL => {
                command.command.transLayout.srcAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT;
                command.command.transLayout.sourceStage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT;
                command.command.transLayout.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL => {
                command.command.transLayout.srcAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
                command.command.transLayout.sourceStage = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
                command.command.transLayout.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_DEPTH_ATTACHMENT_OPTIMAL,
            vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
            => {
                command.command.transLayout.srcAccessMask = vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT;
                command.command.transLayout.sourceStage = vk.VK_PIPELINE_STAGE_LATE_FRAGMENT_TESTS_BIT;
                command.command.transLayout.aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT;
            },

            // vk.VK_IMAGE_LAYOUT_DEPTH_READ_ONLY_OPTIMAL,
            // vk.VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL,
            // => {
            //     command.command.transLayout.srcAccessMask = vk.VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_READ_BIT;
            //     command.command.transLayout.sourceStage = vk.VK_PIPELINE_STAGE_EA;
            //     command.command.transLayout.aspectMask = vk.VK_IMAGE_ASPECT_DEPTH_BIT;
            // },

            else => {
                std.debug.panic("unsupported layout {s}", .{@typeName(@TypeOf(command.command.transLayout.newLayout))});
            },
        }

        switch (command.command.transLayout.newLayout) {
            vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL => {
                command.command.transLayout.dstAccessMask = vk.VK_ACCESS_TRANSFER_WRITE_BIT;
                command.command.transLayout.destinationStage = vk.VK_PIPELINE_STAGE_TRANSFER_BIT;
                command.command.transLayout.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL => {
                command.command.transLayout.dstAccessMask = vk.VK_ACCESS_SHADER_READ_BIT;
                command.command.transLayout.destinationStage = vk.VK_PIPELINE_STAGE_ALL_GRAPHICS_BIT;
                command.command.transLayout.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL => {
                command.command.transLayout.dstAccessMask = vk.VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | vk.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;
                command.command.transLayout.destinationStage = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
                command.command.transLayout.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            vk.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR => {
                command.command.transLayout.dstAccessMask = vk.VK_ACCESS_NONE;
                command.command.transLayout.destinationStage = vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
                command.command.transLayout.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },

            else => {
                std.debug.panic("unsupported layout {s}", .{@typeName(@TypeOf(command.command.transLayout.newLayout))});
            },
        }
    }

    pub fn startCommand(self: *Self) !void {
        const zone = tracy.initZone(@src(), .{ .name = "start vulkan commands" });
        defer zone.deinit();

        const node = try self.nodeDag.create();
        // node.ID = 0;
        const ptr = try self.queue.getOrPut(node.ID);
        ptr.value_ptr.* = drawC{
            .ID = node.ID,
            .commandType = .start,
            .command = .{ .start = .{} },
            .output = .{ .empty = void{} },
        };
    }

    fn addCommand2(self: *Self, commandType: drawC.PrivateCommandType, command: drawC.comm, prev: ?*QueueNode, next: ?*QueueNode) !void {
        const zone = tracy.initZone(@src(), .{ .name = "add command 2" });
        defer zone.deinit();

        const allCommandType = drawC.PrivateCommandTypeToCommandType(commandType);

        const node = try self.nodeDag.create();
        const ID = node.ID;

        const ptr = try self.queue.getOrPut(ID);
        ptr.value_ptr.* = drawC{
            .command = command,
            .commandType = allCommandType,
            .ID = ID,
            .output = getOuput(allCommandType, command),
        };

        if (prev) |p| {
            p.insertPrev(node);
        }
        if (next) |n| {
            n.insertNext(node);
        }

        switch (commandType) {
            .transLayout => {
                inferTransLayoutFlagsByOldLayoutAndNewLayout(ptr.value_ptr);
            },
            else => {},
        }
    }

    pub fn addCommand(self: *Self, commandType: drawC.PublicCommandType, command: drawC.comm) !void {
        const zone = tracy.initZone(@src(), .{ .name = "add command" });
        defer zone.deinit();

        self.mutex.lock();
        defer self.mutex.unlock();

        const allCommandType = drawC.PublicCommandTypeToCommandType(commandType);

        const node = try self.nodeDag.create();
        const ID = node.ID;

        const ptr = try self.queue.getOrPut(ID);
        ptr.value_ptr.* = drawC{
            .command = command,
            .commandType = allCommandType,
            .ID = ID,
            .output = getOuput(allCommandType, command),
        };

        // first command directly add to queue
        if (ID == 1) {
            const root = self.nodeDag.get(0).?;
            root.childrenAppend(&node.node);
            node.parentsAppend(&root.node);
        }

        // dependcy infer
        // combine memory barrier operation with same src stage mask
        // combine same image draw call
        // combine buffer copy to image with same src buffer and dst image
        switch (commandType) {
            .graphic => {},
            .copyBufferToImage => {
                const copyBufferToImage = command.copyBufferToImage;
                const oldLayouts = self.stackAllocator.alloc(vk.VkImageLayout, copyBufferToImage.layerCount) catch |err| mm: {
                    std.log.err("stack alloc error {s}\n", .{@errorName(err)});
                    break :mm try self.allocator.alloc(vk.VkImageLayout, copyBufferToImage.layerCount);
                    // here may have memory leak
                };
                defer self.stackAllocator.free(oldLayouts);

                for (copyBufferToImage.pTexture.layouts[copyBufferToImage.baseArrayLayer..copyBufferToImage.pTexture.layouts.len], oldLayouts) |value, *layout| {
                    layout.* = value;
                }
                var currentLayout = oldLayouts[0];
                var currentBase = copyBufferToImage.baseArrayLayer;
                var count: u32 = 0;
                for (oldLayouts) |layout| {
                    if (currentLayout == vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL) {
                        currentLayout = layout;
                        currentBase += 1;
                        continue;
                    }

                    if (layout == currentLayout) {
                        count += 1;
                    } else {
                        try self.addCommand2(.transLayout, .{ .transLayout = .{
                            .pTexture = copyBufferToImage.pTexture,
                            .oldLayout = currentLayout,
                            .newLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                            .baseLayer = currentBase,
                            .layerCount = count,
                        } }, node, null);
                        currentLayout = layout;
                        currentBase += count;
                        if (currentLayout != vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL) {
                            count = 1;
                        }
                    }
                }
                if (count > 0) {
                    try self.addCommand2(.transLayout, .{ .transLayout = .{
                        .pTexture = copyBufferToImage.pTexture,
                        .oldLayout = currentLayout,
                        .newLayout = vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                        .baseLayer = currentBase,
                        .layerCount = count,
                    } }, node, null);
                }
                copyBufferToImage.pTexture.changeTextureLayout(copyBufferToImage.baseArrayLayer, copyBufferToImage.layerCount, vk.VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL);
            },
            .present => {},
            .graphicTransfer => {},
            .transfer => {},
        }
    }

    /// complete dependency
    pub fn addCommandEnd(self: *Self) !void {
        const zone = tracy.initZone(@src(), .{ .name = "add command end" });
        defer zone.deinit();

        self.executeSemaphore.post();
    }

    fn record(command: *drawC, commandBuffer: vk.VkCommandBuffer) void {
        const zone = tracy.initZone(@src(), .{ .name = "record vulkan command" });
        defer zone.deinit();

        switch (command.commandType) {
            .copyBufferToImage => {
                const innerZone = tracy.initZone(@src(), .{ .name = "copy buffer to image" });
                defer innerZone.deinit();
                const copyBufferToImage = command.command.copyBufferToImage;
                var region = vk.VkBufferImageCopy{
                    .bufferImageHeight = copyBufferToImage.bufferImageHegiht,
                    .bufferOffset = copyBufferToImage.buffer.info.offset,
                    .bufferRowLength = copyBufferToImage.bufferRowLength,
                    .imageExtent = .{
                        .width = copyBufferToImage.pTexture.source_width,
                        .height = copyBufferToImage.pTexture.source_height,
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
                vk.vkCmdCopyBufferToImage(
                    commandBuffer,
                    copyBufferToImage.buffer.vkBuffer,
                    copyBufferToImage.pTexture.image.vkImage,
                    copyBufferToImage.dstImageLayout,
                    1,
                    &region,
                );
            },
            .start => {},
            .transLayout => {
                const innerZone = tracy.initZone(@src(), .{ .name = "trans layout" });
                defer innerZone.deinit();

                const transLayout = command.command.transLayout;
                var imageMemoryBarrier = vk.VkImageMemoryBarrier{
                    .sType = vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
                    .pNext = null,
                    .srcAccessMask = transLayout.srcAccessMask,
                    .dstAccessMask = transLayout.dstAccessMask,
                    .oldLayout = transLayout.oldLayout,
                    .newLayout = transLayout.newLayout,
                    .srcQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
                    .dstQueueFamilyIndex = vk.VK_QUEUE_FAMILY_IGNORED,
                    .image = transLayout.pTexture.image.vkImage,
                    .subresourceRange = .{
                        .aspectMask = transLayout.aspectMask,
                        .baseMipLevel = transLayout.baseMipLevel,
                        .levelCount = transLayout.levelCount,
                        .baseArrayLayer = transLayout.baseLayer,
                        .layerCount = transLayout.layerCount,
                    },
                };
                vk.vkCmdPipelineBarrier(commandBuffer, transLayout.sourceStage, transLayout.destinationStage, 0, 0, null, 0, null, 1, &imageMemoryBarrier);
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

        var commandBuffer: vk.VkCommandBuffer = null;
        var cbb: *CommandBufferBelong = undefined;

        while (true) {
            ctx.semaphore.wait();

            const command = ctx.taskQueue.popFirst();
            if (command) |comm| {
                const com = comm.com;
                if (com.commandType == .beginSecondaryRecord) {
                    commandBuffer = try ctx.commandPool.getSecondaryCommandBuffer(ctx.commandPoolType);
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

                    const rendering = com.command.beginRecoed.rendering;
                    var flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
                    if (rendering) flags |= vk.VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT;

                    var InRenderingInfo = if (rendering) vk.VkCommandBufferInheritanceRenderingInfo{
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
                        .pNext = if (rendering) @ptrCast(&InRenderingInfo) else null,
                        .renderPass = null,
                        .framebuffer = null,
                        .subpass = 0,
                        .occlusionQueryEnable = if (rendering) com.command.beginRecoed.occulusionQueryEnable else vk.VK_FALSE,
                        .queryFlags = if (rendering) com.command.beginRecoed.queryFlags else vk.VK_FALSE,
                        .pipelineStatistics = if (rendering) com.command.beginRecoed.pipelineStatistics else vk.VK_FALSE,
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
                    record(com, cbb.commandBufer);
                }
            } else {
                break;
            }
        }
    }

    fn getGarbage(command: *drawC) ?garbageData {
        const zone = tracy.initZone(@src(), .{ .name = "get garbage" });
        defer zone.deinit();

        return switch (command.commandType) {
            .copyBufferToImage => garbageData{ .buffer = command.command.copyBufferToImage.buffer },
            else => null,
        };
    }

    fn collectGarbage(self: *Self, command: *drawC) !void {
        const zone = tracy.initZone(@src(), .{ .name = "collect garbage" });
        defer zone.deinit();

        if (getGarbage(command)) |g| {
            const temp = try self.garbageData.addOne();
            temp.* = g;
        }
    }

    pub fn cleanGarbage(self: *Self) !void {
        const zone = tracy.initZone(@src(), .{ .name = "clean garbage" });
        defer zone.deinit();

        for (self.garbageData.items) |g| {
            switch (g) {
                .buffer => {
                    global.vulkan.destroyBuffer(g.buffer);
                },
            }
        }

        self.garbageData.clearRetainingCapacity();
    }

    // a thread pool specialy for render
    // task queue, semaphore,
    pub fn executeCommands(self: *Self) !void {
        const zone = tracy.initZone(@src(), .{ .name = "execute all command in one time command" });
        defer zone.deinit();

        self.executeSemaphore.wait();

        self.mutex.lock();
        defer self.mutex.unlock();

        try self.cleanGarbage();

        defer {
            self.nodeDag.clearRetainCapacity();
            self.queue.clearRetainingCapacity();

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
            iterateCount += 1;
            const pTotalSize = prepareToExecuteQueue.totalSize;
            if (pTotalSize == 0) break;

            var pNode = prepareToExecuteQueue.popFirst();

            var executeCount: u32 = 0;
            while (pNode) |nn| {
                if (executeCount >= pTotalSize) break;

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
                        ctx = try self.threadPool.getFreeThread(commandBufferss, nn.queueNode.data.commandPoolType);

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
            }

            var iNode = inferNodeNextTaskQueue.popFirst();
            while (iNode) |nn| {
                const node = nn.queueNode;
                var nodeFirst = node.children.first;
                while (nodeFirst) |cc| {
                    var first = prepareToExecuteQueue.list.first;
                    const ccc: *QueueNode = @fieldParentPtr("node", cc);
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
                    nodeFirst = cc.next;
                }
                iNode = inferNodeNextTaskQueue.popFirst();
            }
        }

        std.log.debug("iterateCount: {d}", .{iterateCount});

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

        {
            mutex.lock();
            defer mutex.unlock();

            const currentFrames = global.vulkan.currentFrame.load(.seq_cst);

            const graphicCommandBuffer = try self.primaryCommandPool.getPrimaryCommandBuffer(.graphic, currentFrames);
            const transferCommandBuffer = try self.primaryCommandPool.getPrimaryCommandBuffer(.transfer, currentFrames);
            const computeCommandBuffer = try self.primaryCommandPool.getPrimaryCommandBuffer(.compute, currentFrames);
            var graphicSemaphoreValue, var transferSemaphoreValue, var computeSemaphoreValue, var currentSemaphoreValue = va: {
                const value = global.vulkan.globalTimelineValue.load(.seq_cst);
                break :va .{ value, value, value, value };
            };

            var waitSemaphores = std.array_list.Managed(vk.VkSemaphore).init(self.allocator);
            defer waitSemaphores.deinit();
            var waitValues = std.array_list.Managed(u64).init(self.allocator);
            defer waitValues.deinit();
            var waitStages = std.array_list.Managed(vk.VkPipelineStageFlags).init(self.allocator);
            defer waitStages.deinit();

            var signalSemaphores = std.array_list.Managed(vk.VkSemaphore).init(self.allocator);
            defer signalSemaphores.deinit();
            var signalValues = std.array_list.Managed(u64).init(self.allocator);
            defer signalValues.deinit();

            var firstStage: vk.VkPipelineStageFlags = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
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

            var timelineSemaphoreSubmitInfo = vk.VkTimelineSemaphoreSubmitInfo{
                .sType = vk.VK_STRUCTURE_TYPE_TIMELINE_SEMAPHORE_SUBMIT_INFO,
            };
            var submitInfo = vk.VkSubmitInfo{
                .sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
                .pNext = @ptrCast(&timelineSemaphoreSubmitInfo),
            };

            var timelinewaitValue: u64 = currentSemaphoreValue;
            while (firstNode) |nn| {
                if (nn.childrenLen > 1) {
                    try nextNodeQueue.pushLast(.{
                        .node = nn,
                        .semaphoreValue = currentSemaphoreValue,
                    });
                }

                if (begin and nn.data.commandPoolType != currentType) {
                    defer waitSemaphores.clearRetainingCapacity();
                    defer waitStages.clearRetainingCapacity();
                    defer waitValues.clearRetainingCapacity();
                    defer signalSemaphores.clearRetainingCapacity();
                    defer signalValues.clearRetainingCapacity();

                    try VkStruct.endCommandBuffer(currentCommandBuffer);
                    const temp = try waitSemaphores.addOne();
                    temp.* = global.vulkan.globalTimelineSemaphore;
                    const temp2 = try waitStages.addOne();
                    if (firstSubmit) {
                        temp2.* = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
                        firstSubmit = false;
                    } else {
                        temp2.* = firstStage;
                    }
                    const temp3 = try waitValues.addOne();
                    temp3.* = timelinewaitValue;

                    const temp4 = try signalSemaphores.addOne();
                    temp4.* = global.vulkan.globalTimelineSemaphore;
                    const temp5 = try signalValues.addOne();
                    currentSemaphoreValue += 1;
                    temp5.* = currentSemaphoreValue;

                    timelineSemaphoreSubmitInfo.waitSemaphoreValueCount = @intCast(waitValues.items.len);
                    timelineSemaphoreSubmitInfo.pWaitSemaphoreValues = @ptrCast(waitValues.items.ptr);
                    timelineSemaphoreSubmitInfo.signalSemaphoreValueCount = @intCast(signalValues.items.len);
                    timelineSemaphoreSubmitInfo.pSignalSemaphoreValues = @ptrCast(signalValues.items.ptr);

                    submitInfo.waitSemaphoreCount = @intCast(waitSemaphores.items.len);
                    submitInfo.pWaitSemaphores = @ptrCast(waitSemaphores.items.ptr);
                    submitInfo.pWaitDstStageMask = @ptrCast(waitStages.items.ptr);
                    submitInfo.commandBufferCount = 1;
                    submitInfo.pCommandBuffers = @ptrCast(&currentCommandBuffer);
                    submitInfo.signalSemaphoreCount = @intCast(signalSemaphores.items.len);
                    submitInfo.pSignalSemaphores = @ptrCast(signalSemaphores.items.ptr);

                    try global.vulkan.queueSubmit(currentType, 1, &submitInfo, null);

                    switch (currentType) {
                        .graphic => graphicSemaphoreValue = currentSemaphoreValue,
                        .transfer => transferSemaphoreValue = currentSemaphoreValue,
                        .compute => computeSemaphoreValue = currentSemaphoreValue,
                    }

                    begin = false;
                }

                if (!begin) {
                    switch (nn.data.commandPoolType) {
                        .graphic => {
                            currentCommandBuffer = graphicCommandBuffer;
                            currentType = .graphic;
                            if (firstSubmit) {
                                try global.vulkan.acquireNextImage(&currentIndex);
                                const temp = try waitSemaphores.addOne();
                                temp.* = global.vulkan.imageAvailableSemaphore[currentFrames];
                                const temp2 = try waitStages.addOne();
                                temp2.* = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
                                const temp3 = try waitValues.addOne();
                                temp3.* = 0;
                            }
                            try global.vulkan.waitSemaphore(1, &global.vulkan.globalTimelineSemaphore, &graphicSemaphoreValue);
                        },
                        .transfer => {
                            currentCommandBuffer = transferCommandBuffer;
                            currentType = .transfer;
                            try global.vulkan.waitSemaphore(1, &global.vulkan.globalTimelineSemaphore, &transferSemaphoreValue);
                        },
                        .compute => {
                            currentCommandBuffer = computeCommandBuffer;
                            currentType = .compute;
                            try global.vulkan.waitSemaphore(1, &global.vulkan.globalTimelineSemaphore, &computeSemaphoreValue);
                        },
                    }
                    // try VkStruct.resetCommandBuffer(currentCommandBuffer);
                    try VkStruct._beginCommandBuffer(currentCommandBuffer, null, vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT, null);
                    begin = true;
                    first = true;
                }

                if (nn.parentsDone >= nn.parentsLen) {
                    nn.nodeDone();

                    const command = self.queue.getPtr(nn.ID).?;
                    try self.collectGarbage(command);
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

                        record(self.queue.getPtr(nn.ID).?, currentCommandBuffer);
                    }
                    firstNode = nn.getFirstUndoneChild();
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

            if (begin) {
                try VkStruct.endCommandBuffer(currentCommandBuffer);

                const temp = try waitSemaphores.addOne();
                temp.* = global.vulkan.globalTimelineSemaphore;
                const temp2 = try waitStages.addOne();
                if (firstSubmit) {
                    temp2.* = vk.VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT;
                    firstSubmit = false;
                } else {
                    temp2.* = vk.VK_PIPELINE_STAGE_ALL_COMMANDS_BIT;
                }
                const temp3 = try waitValues.addOne();
                temp3.* = timelinewaitValue;

                const temp4 = try signalSemaphores.addOne();
                temp4.* = global.vulkan.globalTimelineSemaphore;
                const temp5 = try signalSemaphores.addOne();
                temp5.* = global.vulkan.renderFinishSemaphore[currentFrames];
                const temp6 = try signalValues.addOne();
                currentSemaphoreValue += 1;
                temp6.* = currentSemaphoreValue;
                const temp7 = try signalValues.addOne();
                temp7.* = 0;

                timelineSemaphoreSubmitInfo.waitSemaphoreValueCount = @intCast(waitValues.items.len);
                timelineSemaphoreSubmitInfo.pWaitSemaphoreValues = @ptrCast(waitValues.items.ptr);
                timelineSemaphoreSubmitInfo.signalSemaphoreValueCount = @intCast(signalValues.items.len);
                timelineSemaphoreSubmitInfo.pSignalSemaphoreValues = @ptrCast(signalValues.items.ptr);

                submitInfo.waitSemaphoreCount = @intCast(waitSemaphores.items.len);
                submitInfo.pWaitSemaphores = @ptrCast(waitSemaphores.items.ptr);
                submitInfo.pWaitDstStageMask = @ptrCast(waitStages.items.ptr);
                submitInfo.commandBufferCount = 1;
                submitInfo.pCommandBuffers = @ptrCast(&currentCommandBuffer);
                submitInfo.signalSemaphoreCount = @intCast(signalSemaphores.items.len);
                submitInfo.pSignalSemaphores = @ptrCast(signalSemaphores.items.ptr);

                try global.vulkan.queueSubmit(currentType, 1, &submitInfo, null);
            }

            if (present) {
                var presentInfo = vk.VkPresentInfoKHR{
                    .sType = vk.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
                    .pNext = null,
                    .waitSemaphoreCount = 1,
                    .pWaitSemaphores = @ptrCast(&global.vulkan.renderFinishSemaphore[currentFrames]),
                    .swapchainCount = 1,
                    .pSwapchains = @ptrCast(&global.vulkan.swapchain),
                    .pImageIndices = @ptrCast(&currentIndex),
                    .pResults = null,
                };
                try global.vulkan.presentSubmit(@ptrCast(&presentInfo));
            }

            global.vulkan.globalTimelineValue.store(currentSemaphoreValue, .seq_cst);
        }

        for (0..self.threadPool.info.len) |i| {
            if (self.threadPool.info[i]) |*ctxA| {
                self.threadPool.releaseThread(ctxA.index);

                ctxA.commandPool.markSecondaryCommandBufferFree();
            }
        }
    }
};
