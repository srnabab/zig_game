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
        const bSlice = try allocator.alloc(bool, size);
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
                const idx = self.available[0];
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
    secondaryCommandBuffers: SecondaryCommandBuffers = undefined,

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
        self.secondaryCommandBuffers.deinit(allocator);
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
            .secondarySizes = []u16{ @intCast(graphicSecondarySize), @intCast(transferSecondarySize), @intCast(computeSecondarySize) },
        };
    }

    pub fn getPrimaryCommandBuffer(self: *Self, kind: VkStruct.CommandPoolType, index: u32) !vk.VkCommandBuffer {
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
                .initPrimary(commandPool);

            return self.commandPools[idx].?.primaryCommandBuffer[index];
        }
    }

    pub fn getSecondaryCommandBuffer(self: *Self, kind: VkStruct.CommandPoolType) !vk.VkCommandBuffer {
        const idx: u32 = switch (kind) {
            .graphic => 0,
            .transfer => 1,
            .compute => 2,
        };

        if (self.commandPools[idx]) |p| {
            return p.secondaryCommandBuffers.getFreeBuffer();
        } else {
            var commandPool: vk.VkCommandPool = null;
            try global.vulkan._createCommandPool(null, kind, vk.VK_COMMAND_POOL_CREATE_TRANSIENT_BIT, @ptrCast(&commandPool));
            self.commandPools[idx] = if (self.secondarySizes[idx] > 0)
                try .initWithSecondary(self.allocator, commandPool, self.secondarySizes[idx])
            else
                .initPrimary(commandPool);

            return self.commandPools[idx].?.secondaryCommandBuffers.getFreeBuffer();
        }
    }

    pub fn markSecondaryCommandBufferFree(self: *Self) void {
        for (self.commandPools) |cp| {
            if (cp) |p| {
                p.secondaryCommandBuffers.reset();
            }
        }
    }

    pub fn deinit(self: *Self) void {
        for (self.commandPools) |cp| {
            if (cp) |p| {
                p.deinit(self.allocator);
                global.vulkan.destroyCommandPool(p.commandPool);
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
            self.mutex.lock();
            defer self.mutex.unlock();

            if (self.freeCount > 0) {
                const idx = self.freeList[0];
                self.freeList[0] = self.freeList[self.freeCount - 1];
                self.freeList[self.freeCount - 1] = -1;
                self.freeCount -= 1;

                self.info[idx].commandPoolType = commandPoolType;

                return &self.info[idx].?;
            } else {
                if (self.threadCount == maxThreads) {
                    return error.OutOfCapacity;
                }

                self.info[self.threadCount] = ThreadContext{
                    .semaphore = .{},
                    .taskQueue = .init(self.allocator),
                    .commandPool = .init(self.allocator, 4, 2, 2),
                    .mutex = .{},
                    .commandBuffers = commandBufferQueue,
                    .index = @intCast(self.threadCount),
                    .threadPool = self,
                    .commandPoolType = commandPoolType,
                };

                const t = try Thread.spawn(.{}, oneTimeCommand.recordCommand, .{self.info[self.threadCount].?});
                self.threads[self.threadCount] = t;

                defer self.threadCount += 1;

                return &self.info[self.threadCount].?;
            }
        }

        pub fn releaseThread(self: *Self, index: i32) void {
            self.mutex.lock();
            defer self.mutex.unlock();

            if (index < 0 or index >= self.threadCount) return;

            self.freeList[self.freeCount] = index;
            self.freeCount += 1;
        }

        pub fn waitThread(self: *Self) !void {
            for (self.threads, self.info) |t, info| {
                if (info) |ii| {
                    ii.taskQueue.deinit();
                    ii.commandPool.deinit(self.allocator);
                    ii.commandBuffers.deinit();
                }

                if (t) |tt| {
                    try tt.join();
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

        done: bool,

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

        pub fn nodeDone(self: *Self) void {
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

        pub fn getFirstUndoneChild(self: *Self) ?*std.DoublyLinkedList.Node {
            if (self.childrenLen == self.childrenDone) return null;

            var first = self.children.first;
            while (first) |nn| {
                const ll: *Self = @fieldParentPtr("node", nn);

                if (ll.done) {
                    continue;
                } else {
                    return nn;
                }

                first = nn.next;
            }
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
            _ = self.mem.reset(.retain_capacity);
            self.map.clearRetainingCapacity();
            self.innerID = 0;
        }

        pub fn undoneAllNodes(self: *Self) void {
            var it = self.map.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.*.done = false;
                entry.value_ptr.*.parentsDone = entry.value_ptr.*.parentsLen;
                entry.value_ptr.*.childrenDone = entry.value_ptr.*.childrenLen;
            }
        }
    };
}

const MaxThreads = 8;

const ThreadContext = struct {
    const task = struct {
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
    commandPoolType: VkStruct.CommandPoolType = .graphics,
    commandBufferID: u32 = 0,
};

const QueueNodes = DAG(dependencyData);
pub const QueueNode = QueueNodes.Inner;

const commandBufferDAG = DAG(CommandBufferBelong);

pub const oneTimeCommand = struct {
    const Self = @This();

    pub const TaskCallback = *const fn (ctx: *anyopaque) VkStruct.VkError!void;
    const EnqueueTaskCallback = *const fn (taskCallback: TaskCallback, taskCtx: *anyopaque, userCtx: *anyopaque) *anyopaque;
    const FinishTaskCallback = *const fn (userTask: *anyopaque, userCtx: *anyopaque) void;

    innerID: u32 = 0,
    innerCommandBufferID: u32 = 0,
    queue: std.hash_map.AutoHashMap(u32, drawC),
    nodeDag: QueueNodes,

    primaryCommandPool: CommandPools,

    allocator: std.mem.Allocator,

    threadPool: SpecialThreadPool(MaxThreads),
    mutex: Thread.Mutex = .{},

    // commandPools: std.array_list.Managed(vk.VkCommandPool),

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .queue = .init(allocator),
            .allocator = allocator,
            .nodeDag = .init(allocator),
            .threadPool = .init(allocator),
            .primaryCommandPool = .init(allocator, 0, 0, 0),
        };
    }

    pub fn deinit(self: *Self) void {
        self.queue.deinit();
        self.nodeDag.deinit();
    }

    fn getOuput(commandType: drawC.CommandType, command: drawC.comm) drawC.Output {
        switch (commandType) {
            .graphic => {},
            .copyBufferToImage => {},
            .transLayout => {
                return drawC.Output{ .image = command.transLayout.image };
            },
        }

        return drawC.Output{ .empty = void{} };
    }

    fn commandCost(commandType: drawC.CommandType) u32 {
        return switch (commandType) {
            .graphic => 100,
            .copyBufferToImage => 100,
            .transLayout => 100,
        };
    }

    fn inferTransLayoutFlagsByOldLayoutAndNewLayout(command: *drawC) void {
        if (command.CommandType != .transLayout) return;

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

            else => {},
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

            vk.VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL => {
                command.command.transLayout.dstAccessMask = vk.VK_ACCESS_NONE;
                command.command.transLayout.destinationStage = vk.VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT;
                command.command.transLayout.aspectMask = vk.VK_IMAGE_ASPECT_COLOR_BIT;
            },
        }
    }

    pub fn startCommand(self: *Self) !void {
        const node = try self.nodeDag.create();
        node.ID = 0;
        const ptr = try self.queue.getOrPut(0);
        ptr.value_ptr.* = drawC{
            .ID = 0,
            .commandType = .start,
            .command = .{ .start = .{} },
            .output = .{ .empty = void{} },
        };
    }

    // fn addCommand2(self: *Self, commandType: drawC.PrivateCommandType, command: drawC.comm) !void {}

    pub fn addCommand(self: *Self, commandType: drawC.PublicCommandType, command: drawC.comm) !void {
        self.mutex.lock();
        defer self.mutex.unlock();

        const node = try self.nodeDag.create();
        const ID = node.ID;

        const ptr = try self.queue.getOrPut(ID);
        ptr.value_ptr.* = drawC{
            .command = command,
            .commandType = drawC.PublicCommandTypeToCommandType(commandType),
            .ID = ID,
            .output = getOuput(command),
        };

        switch (commandType) {
            .graphic => {},
            .copyBufferToImage => {},
        }

        // first command directly add to queue
        if (ID == 1) {
            const root = self.nodeDag.get(0).?;
            root.children.append(&node.node);
            node.parents.append(&root.node);

            return;
        }

        // dependcy infer
        // combine memory barrier operation with same src stage mask
        // combine same image draw call
        // combine buffer copy to image with same src buffer and dst image
        switch (commandType) {
            .graphic => {},

            .copyBufferToImage => {},
        }
    }

    /// complete dependency
    pub fn addCommandEnd(self: *Self) !void {
        _ = self;
    }

    fn record(command: *drawC) void {
        _ = command;
    }

    pub fn recordCommand(ctx: ThreadContext) !void {
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
                            .ID = temp.ID,
                            .semaphore = .{},
                        };
                        cbb = &temp.data;
                        comm.node.data.commandBufferID = cbb.ID;
                    }

                    const rendering = com.command.beginRecoed.rendering;
                    var flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
                    if (rendering) flags |= vk.VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT;

                    var InRenderingInfo = if (rendering) vk.VkCommandBufferInheritanceRenderingInfo{
                        .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_RENDERING_INFO,
                        .flags = com.command.beginRecoed.flags,
                        .pNext = null,
                        .viewMask = com.command.beginRecoed.viewMask,
                        .colorAttachmentCount = com.command.beginRecoed.colorAttachmentCount,
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
                    try VkStruct._beginCommandBuffer(commandBuffer, null, flags, &InInfo);
                    continue;
                }

                comm.node.data.commandBufferID = cbb.ID;

                if (com.commandType == .endRecord) {
                    try VkStruct.endCommandBuffer(commandBuffer);
                    ctx.threadPool.releaseThread(ctx.index);
                    cbb.semaphore.post();
                } else if (com.commandType == .end) {
                    break;
                } else {
                    record(com);
                }
            }
        }
    }

    // a thread pool specialy for render
    // task queue, semaphore,

    pub fn executeCommands(self: *Self) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
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

        var commandBufferss = commandBufferDAG.init(self.allocator);
        defer commandBufferss.deinit();

        // xxx
        const root = self.nodeDag.get(0);
        if (root) |rr| {
            try prepareToExecuteQueue.pushLast(taskQueueStruct{
                .queueNode = rr,
                .threadCtx = null,
                .renderingInfo = null,
            });
        } else {
            return;
        }

        while (true) {
            const pTotalSize = prepareToExecuteQueue.totalSize;
            if (pTotalSize == 0) break;

            var pNode = prepareToExecuteQueue.popFirst();

            var executeCount: u32 = 0;
            while (pNode) |nn| {
                if (executeCount >= pTotalSize) break;

                // judge dependencies first
                if (nn.queueNode.parentsDone < nn.queueNode.parentsLen) {
                    prepareToExecuteQueue.pushLast(nn);
                    executeCount += 1;
                    try inferNodeNextTaskQueue.pushLast(nn);
                    continue;
                }

                var ctx: ?*ThreadContext = null;
                if (nn.threadCtx == null) {
                    if (nn.queueNode.data.startThread) {
                        ctx = try self.threadPool.getFreeThread(commandBufferss);

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

                    nn.queueNode.data.commandBufferID = nn.threadCtx.?.commandBufferID.*;
                    try nn.threadCtx.?.taskQueue.pushLast(self.queue.items[nn.queueNode.ID]);

                    nn.threadCtx.?.semaphore.post();
                }

                nn.queueNode.nodeDone();

                executeCount += 1;
                try inferNodeNextTaskQueue.pushLast(pNode.?);
            }

            var iNode = inferNodeNextTaskQueue.popFirst();
            while (iNode) |nn| {
                const node = nn.queueNode;
                while (node.getFirstUndoneChild()) |cc| {
                    const parent: *QueueNode = @fieldParentPtr("node", cc);

                    var first = prepareToExecuteQueue.list.first;
                    while (first) |jjj| {
                        const aaa: *Queue(taskQueueStruct).DataNode = @fieldParentPtr("node", jjj);
                        if (aaa.data.queueNode == parent) {
                            prepareToExecuteQueue.remove(aaa.*);
                            break;
                        }
                        first = jjj.next;
                    }

                    try prepareToExecuteQueue.pushLast(.{
                        .queueNode = parent,
                        .threadCtx = if (parent.data.isSecondary) nn.threadCtx else null,
                    });
                }
                iNode = inferNodeNextTaskQueue.popFirst();
            }
        }

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

            var semaphores = std.array_list.Managed(vk.VkSemaphore).init(self.allocator);
            defer semaphores.deinit();
            var waitStages = std.array_list.Managed(vk.VkPipelineStageFlags).init(self.allocator);
            defer waitStages.deinit();

            var currentCommandBuffer: vk.VkCommandBuffer = null;
            var currentType: VkStruct.CommandPoolType = .graphic;
            var begin = false;
            var firstSubmit = true;
            var currentIndex: u32 = 0;

            var firstNode = self.nodeDag.get(0);

            var timelineSemaphoreSubmitInfo = vk.VkTimelineSemaphoreSubmitInfo{
                .sType = vk.VK_STRUCTURE_TYPE_TIMELINE_SEMAPHORE_SUBMIT_INFO,
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
                    try VkStruct.endCommandBuffer(currentCommandBuffer);
                    const temp = try semaphores.addOne();
                    temp.* = global.vulkan.globalTimelineSemaphore;
                    const temp2 = try waitStages.addOne();

                    begin = false;
                }

                if (!begin) {
                    switch (nn.data.commandPoolType) {
                        .graphic => {
                            currentCommandBuffer = graphicCommandBuffer;
                            currentType = .graphic;
                            if (firstSubmit) {
                                global.vulkan.acquireNextImage(&currentIndex);
                                const temp = try semaphores.addOne();
                                temp.* = global.vulkan.imageAvailableSemaphore[currentFrames];
                                const temp2 = try waitStages.addOne();
                                temp2.* = vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;

                                firstSubmit = false;
                            }
                            try global.vulkan.waitSemaphore(&global.vulkan.globalTimelineSemaphore, &graphicSemaphoreValue);
                        },
                        .transfer => {
                            currentCommandBuffer = transferCommandBuffer;
                            currentType = .transfer;
                            try global.vulkan.waitSemaphore(&global.vulkan.globalTimelineSemaphore, &transferSemaphoreValue);
                        },
                        .compute => {
                            currentCommandBuffer = computeCommandBuffer;
                            currentType = .compute;
                            try global.vulkan.waitSemaphore(&global.vulkan.globalTimelineSemaphore, &computeSemaphoreValue);
                        },
                    }
                    try VkStruct.resetCommandBuffer(currentCommandBuffer);
                    try VkStruct._beginCommandBuffer(currentCommandBuffer, null, vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT, null);
                    begin = true;
                }

                if (nn.parentsDone >= nn.parentsLen) {
                    nn.nodeDone();

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
                            vk.vkCmdExecuteCommands(currentCommandBuffer, cbs.items.len, @ptrCast(cbs.items.ptr));

                        record(self.queue.getPtr(nn.ID).?);
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
        }

        // var finalID: u32 = 0;
        // for (finalPrimaryTaskQueue.items) |value| {
        //     {
        //         defer cbIdxs.clearRetainingCapacity();
        //         defer cbs.clearRetainingCapacity();

        //         if (!begin) {
        //             if (value.data.commandPoolType == .graphic) {
        //                 currentCommandBuffer = graphicCommandBuffer;
        //                 currentType = .graphic;
        //             } else if (value.data.commandPoolType == .transfer) {
        //                 currentCommandBuffer = transferCommandBuffer;
        //                 currentType = .transfer;
        //             } else if (value.data.commandPoolType == .compute) {
        //                 currentCommandBuffer = computeCommandBuffer;
        //                 currentType = .compute;
        //             }
        //             try self.primaryCommandPool.waitPrimaryCommandBuffer(currentType);
        //             try VkStruct.resetCommandBuffer(currentCommandBuffer);
        //             try VkStruct._beginCommandBuffer(currentCommandBuffer, null, vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT, null);
        //             begin = true;
        //         }

        //         var first = value.children.first;
        //         while (first) |nn| {
        //             const aaa: *QueueNode = @fieldParentPtr("node", nn);

        //             if (!bs: {
        //                 for (cbIdxs.items) |id| {
        //                     if (id == aaa.data.commandBufferID) break :bs true;
        //                 }
        //                 break :bs false;
        //             }) {
        //                 const ptr = try cbIdxs.addOne();
        //                 ptr.* = aaa.data.commandBufferID;
        //             }

        //             first = nn.next;
        //         }
        //         record(self.queue.getPtr(value.ID).?);
        //         for (cbIdxs.items) |id| {
        //             const cb = commandBufferss.get(id);
        //             if (cb) |cbb| {
        //                 const cbPtr = try cbs.addOne();
        //                 cbPtr.* = cbb.data.commandBufer;

        //                 cbb.data.semaphore.wait();
        //             }
        //         }
        //         if (cbs.items.len > 0)
        //             vk.vkCmdExecuteCommands(currentCommandBuffer, cbs.items.len, @ptrCast(cbs.items.ptr));

        //         finalID = value.ID;
        //     }
        // }
        // const finalCommand = self.queue.get(finalID).?;
        // if (finalCommand.commandType == .present) {
        //     var imageIndex: u32 = 0;
        //     global.vulkan.acquireNextImage(&imageIndex);

        //     const currentFrame = global.vulkan.currentFrame.load(.seq_cst);

        //     var waitStage = vk.VkPipelineStageFlags{vk.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT};
        //     var submitInfo = vk.VkSubmitInfo{
        //         .sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        //         .pNext = null,
        //         .waitSemaphoreCount = 1,
        //         .pWaitSemaphores = @ptrCast(&global.vulkan.imageAvailableSemaphore[currentFrame]),
        //         .pWaitDstStageMask = @ptrCast(&waitStage),
        //         .commandBufferCount = 1,
        //         .pCommandBuffers = @ptrCast(&primaryCommandBuffer),
        //         .signalSemaphoreCount = 1,
        //         .pSignalSemaphores = @ptrCast(&global.vulkan.renderFinishSemaphore[currentFrame]),
        //     };

        //     try global.vulkan.queueSubmit(.graphic, 1, @ptrCast(&submitInfo), null);

        //     var presentInfo = vk.VkPresentInfoKHR{
        //         .sType = vk.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
        //         .pNext = null,
        //         .waitSemaphoreCount = 1,
        //         .pWaitSemaphores = @ptrCast(&global.vulkan.renderFinishSemaphore[currentFrame]),
        //         .swapchainCount = 1,
        //         .pSwapchains = @ptrCast(&global.vulkan.swapchain),
        //         .pImageIndices = @ptrCast(&imageIndex),
        //         .pResults = null,
        //     };
        //     try global.vulkan.presentSubmit(@ptrCast(&presentInfo));
        // } else if (finalCommand.commandType == .graphicTransfer) {
        //     const currentFrame = global.vulkan.currentFrame.load(.seq_cst);
        //     var submitInfo = vk.VkSubmitInfo{
        //         .sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
        //         .pNext = null,
        //         .waitSemaphoreCount = 0,
        //         .pWaitSemaphores = null,
        //         .pWaitDstStageMask = null,
        //         .commandBufferCount = 1,
        //         .pCommandBuffers = @ptrCast(&primaryCommandBuffer),
        //         .signalSemaphoreCount = 1,
        //         .pSignalSemaphores = @ptrCast(&global.vulkan.renderFinishSemaphore[currentFrame]),
        //     };

        //     try global.vulkan.queueSubmit(.graphic, 1, @ptrCast(&submitInfo), null);
        // }

        for (self.threadPool.info) |ctx| {
            var end = drawC{
                .commandType = .end,
                .ID = 1234124142,
                .command = .{ .empty = void{} },
                .output = .{ .empty = void{} },
            };

            if (ctx) |ctxA| {
                ctxA.mutex.lock();
                defer ctxA.mutex.unlock();

                try ctxA.taskQueue.pushLast(&end);
                ctxA.semaphore.post();

                ctxA.commandPool.markSecondaryCommandBufferFree();
            }
        }
    }
};
