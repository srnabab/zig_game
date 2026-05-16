const std = @import("std");
const VkStruct = @import("video");
const vertexStruct = @import("vertexStruct");
const Commands = @import("processRender").commands;
const textureSet = @import("textureSet");
const vk = VkStruct.vk;

var instanceIDsBuffer: VkStruct.Buffer_t = undefined;
var indirectDrawCommandBuffer: VkStruct.Buffer_t = undefined;
var instances2D: std.array_list.Managed(vertexStruct.Instance) = undefined;
var instanceBuffer2D: VkStruct.Buffer_t = undefined;

var instanceUpdated = false;
var updateStart: u32 = 0;
var updateEnd: u32 = 0;

pub fn init(
    instanceIDsBuffer_t: VkStruct.Buffer_t,
    indirectDrawCommandBuffer_t: VkStruct.Buffer_t,
    instanceBuffer_t: VkStruct.Buffer_t,
    allocator: std.mem.Allocator,
    commands: *Commands,
) !void {
    instanceIDsBuffer = instanceIDsBuffer_t;
    indirectDrawCommandBuffer = indirectDrawCommandBuffer_t;
    instanceBuffer2D = instanceBuffer_t;
    instances2D = .init(allocator);

    try commands.cacheCommand(.{ .fillBuffer = .{
        .buffer = indirectDrawCommandBuffer,
        .offset = 0,
        .size = 4,
        .value = 6,
    } });
}

pub fn deinit() void {
    instances2D.deinit();
}

pub fn addInstance(
    x: f32,
    y: f32,
    width: f32,
    height: f32,
    depth: f32,
    texture: textureSet.Texture_t,
    pTextureSet: *textureSet,
) !u32 {

    // const textureContent = pTextureSet.getTextureCotent(texture);

    // const scale_x = width / @as(f32, @floatFromInt(textureContent.source_width));
    // const scale_y = height / @as(f32, @floatFromInt(textureContent.source_height));

    const ptr = try instances2D.addOne();
    ptr.* = .{
        .position = [3]f32{ x, y, depth },
        .scale = [2]f32{ width, height },
        .textureIndex = pTextureSet.getDescriptorSetIndex(texture),
        .samplerIndex = 0,
        .flags = 0,
    };
    instanceUpdated = true;

    updateEnd = @intCast(instances2D.items.len);

    return @intCast(instances2D.items.len - 1);
}

pub fn uploadInstance(graphic: *Commands, vulkan: *VkStruct) !void {
    if (instanceUpdated) {
        const bufferSize = @sizeOf(vertexStruct.Instance) * (updateEnd - updateStart);
        const stagingBuffer = try vulkan.createBufferByUsage(
            @intCast(bufferSize),
            0,
            .staging,
            false,
        );

        vulkan.buffers.copyDataToMapped(stagingBuffer, vertexStruct.Instance, instances2D.items[updateStart..updateEnd]);

        var region = [_]vk.VkBufferCopy2{.{
            .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
            .pNext = null,
            .srcOffset = 0,
            .dstOffset = updateStart * @sizeOf(vertexStruct.Instance),
            .size = bufferSize,
        }};

        try graphic.cacheCommand(.{ .copyBuffer = .{
            .srcBuffer = stagingBuffer,
            .dstBuffer = instanceBuffer2D,
            .regions = &region,
        } });

        instanceUpdated = false;
    }
}

pub fn getTotalCount() u32 {
    return @intCast(instances2D.items.len);
}
