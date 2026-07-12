const std = @import("std");

const vertexStruct = @import("vertexStruct");
const VkStruct = @import("video");
const vk = VkStruct.vk;

const ProcessRender = @import("processRender");
const Commands = ProcessRender.commands;

const Self = @This();

const Command = vertexStruct.CustomDrawMeshTasksIndirectCommand;

const Records = struct {
    meshIdList: std.array_list.Aligned(u32, null),
    commands: []Command,

    mappings: []std.array_list.Aligned(vertexStruct.GroupMapping, null),
};

passCommandsMap: std.StringHashMap(Records),
allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) Self {
    return .{
        .passCommandsMap = .init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    var it = self.passCommandsMap.iterator();
    while (it.next()) |entry| {
        entry.value_ptr.meshIdList.deinit(self.allocator);
        self.allocator.free(entry.value_ptr.commands);
        for (entry.value_ptr.mappings) |*value| {
            value.deinit(self.allocator);
        }
        self.allocator.free(entry.value_ptr.mappings);
    }
    self.passCommandsMap.deinit();
}

pub fn add(self: *Self, passName: []const u8, mapping: vertexStruct.GroupMapping) !void {
    const getOrPut = try self.passCommandsMap.getOrPut(passName);

    if (!getOrPut.found_existing) {
        getOrPut.value_ptr.* = .{
            .commands = &.{},
            .mappings = &.{},
            .meshIdList = try .initCapacity(self.allocator, 2),
        };
    }

    const idx = a: {
        for (getOrPut.value_ptr.meshIdList.items, 0..) |id, i| {
            if (id == mapping.meshID) {
                break :a i;
            }
        }

        break :a getOrPut.value_ptr.meshIdList.items.len;
    };

    if (idx == getOrPut.value_ptr.meshIdList.items.len) {
        try getOrPut.value_ptr.meshIdList.append(self.allocator, mapping.meshID);
        getOrPut.value_ptr.commands = try self.allocator.realloc(
            getOrPut.value_ptr.commands,
            getOrPut.value_ptr.commands.len + 1,
        );
        getOrPut.value_ptr.commands[idx] = .{
            .groupCountY = 1,
            .groupCountZ = 1,
        };
        getOrPut.value_ptr.mappings = try self.allocator.realloc(
            getOrPut.value_ptr.mappings,
            getOrPut.value_ptr.mappings.len + 1,
        );
        getOrPut.value_ptr.mappings[idx] = try .initCapacity(self.allocator, 2);
    }

    try getOrPut.value_ptr.mappings[idx].append(self.allocator, mapping);
    getOrPut.value_ptr.commands[idx].groupCountX += 1;

    for (getOrPut.value_ptr.commands[idx + 1 ..]) |*i| {
        i.workgroupOffset += 1;
    }
}

pub fn upload(self: *Self, vulkan: *VkStruct, commands: *Commands, passName: []const u8, indirectBuffer: VkStruct.Buffer_t, mappingBuffer: VkStruct.Buffer_t) !void {
    // if (self)

    const records = self.passCommandsMap.get(passName) orelse return;

    const commandLen = records.commands.len;

    const mappingLen = a: {
        var size: usize = 0;
        for (records.mappings) |mappings| {
            size += mappings.items.len;
        }

        break :a size;
    };

    const stagingBuffer1 = try vulkan.createBufferByUsage(
        commandLen * @sizeOf(Command),
        0,
        .staging,
        false,
    );

    const stagingBuffer2 = try vulkan.createBufferByUsage(
        mappingLen * @sizeOf(vertexStruct.GroupMapping),
        0,
        .staging,
        false,
    );

    vulkan.buffers.copyDataToMapped(stagingBuffer1, 0, Command, records.commands);

    var offset: usize = 0;
    for (records.mappings) |m| {
        vulkan.buffers.copyDataToMapped(stagingBuffer2, offset, vertexStruct.GroupMapping, m.items);
        offset += m.items.len;
    }

    var region = [_]vk.VkBufferCopy2{.{
        .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
        .pNext = null,
        .srcOffset = 0,
        .dstOffset = 0,
        .size = commandLen * @sizeOf(Command),
    }};

    try commands.cacheCommand(.{ .copyBuffer = .{
        .srcBuffer = stagingBuffer1,
        .dstBuffer = indirectBuffer,
        .regions = &region,
    } });

    region = [_]vk.VkBufferCopy2{.{
        .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
        .pNext = null,
        .srcOffset = 0,
        .dstOffset = 0,
        .size = mappingLen * @sizeOf(vertexStruct.GroupMapping),
    }};

    try commands.cacheCommand(.{ .copyBuffer = .{
        .srcBuffer = stagingBuffer2,
        .dstBuffer = mappingBuffer,
        .regions = &region,
    } });
}
