const std = @import("std");
const VkStruct = @import("video");
const vertexStruct = @import("vertexStruct");
const Commands = @import("processRender").externalCommands;
const vk = VkStruct.vk;

const Self = @This();

instanceIDsBuffer: VkStruct.Buffer_t = undefined,
indirectDrawCommandBuffer: VkStruct.Buffer_t = undefined,
instances2D: std.array_list.Managed(vertexStruct.Instance) = undefined,
instanceBuffer2D: VkStruct.Buffer_t = undefined,
commands: *Commands,

instanceUpdated: bool = false,
updateStart: u32 = 0,
updateEnd: u32 = 0,

pub fn init(
    instanceIDsBuffer_t: VkStruct.Buffer_t,
    indirectDrawCommandBuffer_t: VkStruct.Buffer_t,
    instanceBuffer_t: VkStruct.Buffer_t,
    allocator: std.mem.Allocator,
    commands: *Commands,
) !Self {
    try commands.externalCommand(.{ .fillBuffer = .{
        .buffer = indirectDrawCommandBuffer_t,
        .offset = 0,
        .size = 4,
        .value = 6,
    } });

    return .{
        .instanceIDsBuffer = instanceIDsBuffer_t,
        .indirectDrawCommandBuffer = indirectDrawCommandBuffer_t,
        .instanceBuffer2D = instanceBuffer_t,
        .instances2D = .init(allocator),
        .commands = commands,
    };
}

pub fn deinit(self: *Self) void {
    self.instances2D.deinit();
}

pub fn addInstance(
    self: *Self,
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    depth: f32,
    textureIndex: u32,
) !u32 {

    // const textureContent = pTextureSet.getTextureCotent(texture);

    // const scale_x = width / @as(f32, @floatFromInt(textureContent.source_width));
    // const scale_y = height / @as(f32, @floatFromInt(textureContent.source_height));

    const ptr = try self.instances2D.addOne();
    ptr.* = .{
        .position = [3]f32{ x, y, depth },
        .scale = [2]f32{ width, height },
        .textureIndex = textureIndex,
    };
    self.instanceUpdated = true;

    self.updateEnd = @intCast(self.instances2D.items.len);

    return @intCast(self.instances2D.items.len - 1);
}

pub fn uploadInstance(self: *Self, vulkan: *VkStruct) !void {
    if (!self.instanceUpdated) return;

    const bufferSize = @sizeOf(vertexStruct.Instance) * (self.updateEnd - self.updateStart);
    const stagingBuffer = try vulkan.createBufferByUsage(
        @intCast(bufferSize),
        0,
        .staging,
        false,
        null,
    );

    vulkan.buffers.copyDataToMapped(stagingBuffer, 0, vertexStruct.Instance, self.instances2D.items[self.updateStart..self.updateEnd]);

    var region = [_]vk.VkBufferCopy2{.{
        .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
        .pNext = null,
        .srcOffset = 0,
        .dstOffset = self.updateStart * @sizeOf(vertexStruct.Instance),
        .size = bufferSize,
    }};

    try self.commands.externalCommand(.{ .copyBuffer = .{
        .srcBuffer = stagingBuffer,
        .dstBuffer = self.instanceBuffer2D,
        .regions = &region,
    } });

    self.instanceUpdated = false;
}

pub fn getTotalCount(self: *Self) u32 {
    return @intCast(self.instances2D.items.len);
}
