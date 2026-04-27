const std = @import("std");
const tracy = @import("tracy");

const vertexStruct = @import("vertexStruct");

const vkStruct = @import("video");
const vk = vkStruct.vk;
const textureSet = @import("textureSet");
const global = @import("global");

const Commands = @import("processRender").commands;

pub const Vertex2D = vertexStruct.Vertex_f3pf2u;
const vec2 = vertexStruct.vec2;
const vec3 = vertexStruct.vec3;

const vertex2DinitCount = 40000;
const index2DinitCount = std.math.maxInt(u16) / 6;

pub var vertices2D: []Vertex2D = &.{};
var vertexCount2D: u32 = 0;
var update2dStartIndex: u32 = 0;
pub var vertexBuffer2D: vkStruct.Buffer_t = undefined;
pub var indexBuffer2D: vkStruct.Buffer_t = undefined;
var updated2D = false;

const indirectDrawCommand = vk.VkDrawIndirectCommand{
    .vertexCount = 6,
    .instanceCount = 6,
    .firstVertex = 0,
    .firstInstance = 0,
};
pub var indirectDrawCommandBuffer: vkStruct.Buffer_t = undefined;
pub var instances2D: std.array_list.Managed(vertexStruct.Instance) = undefined;
pub var instanceBuffer2D: vkStruct.Buffer_t = undefined;
pub var positions2D: std.array_list.Managed(*vertexStruct.vec3) = undefined;
var instanceUpdated = false;
var updateStart: u32 = 0;
var updateEnd: u32 = 0;

var vulkan: *vkStruct = undefined;
var pTextureSet: *textureSet = undefined;
var mutex: std.Io.Mutex = .init;

pub fn init(vulkan_t: *vkStruct, graphic: *Commands, pTextureSet_t: *textureSet, allocator: std.mem.Allocator) !void {
    const zone = tracy.initZone(@src(), .{ .name = "vertices initialization" });
    defer zone.deinit();

    vulkan = vulkan_t;
    pTextureSet = pTextureSet_t;

    vertexBuffer2D = try vulkan.createVertexBuffer(vertex2DinitCount * @sizeOf(Vertex2D), @sizeOf(Vertex2D));
    indexBuffer2D = try vulkan.createIndexBuffer(index2DinitCount * 6 * @sizeOf(u16));
    vertices2D = try allocator.alloc(Vertex2D, vertex2DinitCount);

    indirectDrawCommandBuffer = try vulkan.createStorageBuffer(@sizeOf(vk.VkDrawIndirectCommand), true);

    instanceBuffer2D = try vulkan.createVertexBuffer(1000 * @sizeOf(vertexStruct.Instance), @sizeOf(vertexStruct.Instance));

    instances2D = .init(allocator);
    positions2D = .init(allocator);

    {
        const indices = comptime is: {
            @setEvalBranchQuota(20000);
            const totalCount = index2DinitCount * 6;
            var s = [_]u16{0} ** totalCount;
            for (0..index2DinitCount) |i| {
                const index = i * 6;
                const serial = i * 4;
                s[index] = @intCast(serial);
                s[index + 1] = @intCast(serial + 1);
                s[index + 2] = @intCast(serial + 2);
                s[index + 3] = @intCast(serial + 2);
                s[index + 4] = @intCast(serial + 3);
                s[index + 5] = @intCast(serial);
            }

            break :is s;
        };

        const stagingBuffer = try vulkan.createStagingBuffer(indices.len * @sizeOf(u16));
        vulkan.buffers.copyDataToMapped(stagingBuffer, u16, &indices);
        // @memcpy(@as([*c]u16, @ptrCast(@alignCast(stagingBuffer.pMappedData.?))), &indices);

        // std.log.debug("s: {d}, i: {d}", .{ stagingBuffer.size, indexBuffer2D.size });

        var region = [_]vk.VkBufferCopy2{.{
            .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
            .pNext = null,
            .srcOffset = 0,
            .dstOffset = 0,
            .size = vulkan.buffers.getBufferSize(indexBuffer2D),
        }};

        try graphic.cacheCommand(.{ .copyBuffer = .{
            .srcBuffer = stagingBuffer,
            .dstBuffer = indexBuffer2D,
            .regions = &region,
        } });

        const stagingBuffer2 = try vulkan.createStagingBuffer(@sizeOf(vk.VkDrawIndirectCommand));
        var tempData = [_]vk.VkDrawIndirectCommand{indirectDrawCommand};
        vulkan.buffers.copyDataToMapped(stagingBuffer2, vk.VkDrawIndirectCommand, &tempData);

        region[0].size = vulkan.buffers.getBufferSize(indirectDrawCommandBuffer);
        try graphic.cacheCommand(.{ .copyBuffer = .{
            .srcBuffer = stagingBuffer2,
            .dstBuffer = indirectDrawCommandBuffer,
            .regions = &region,
        } });
    }
}

pub fn deinit(allocator: std.mem.Allocator) void {
    // vulkan.waitDevice() catch |err| {
    //     std.log.err("wait device error {s}\n", .{@errorName(err)});
    //     return;
    // };

    allocator.free(vertices2D);
    instances2D.deinit();
    positions2D.deinit();

    // vulkan.destroyBuffer(vertexBuffer2D);
    // vulkan.destroyBuffer(indexBuffer2D);
}

pub fn vertexInitialize2D(io: std.Io, width: u32, height: u32, x: u32, y: u32, depth: f32) !u32 {
    try mutex.lock(io);
    defer mutex.unlock(io);
    // std.log.debug("idx {d}", .{textureIndex});

    if (vertices2D.len <= vertexCount2D) {
        vertices2D = try vulkan.allocator.realloc(vertices2D, vertexCount2D * 2);
    }

    const xOffset = @as(f32, @floatFromInt(width));
    const yOffset = @as(f32, @floatFromInt(height));

    var leftUp: vec2 = undefined;
    leftUp[0] = @as(f32, @floatFromInt(x));
    leftUp[1] = @as(f32, @floatFromInt(y));
    // vec2 rightUp;
    // rightUp[0] = leftUp[0] + xOffset;
    // rightUp[1] = leftUp[1];
    // vec2 rightDown;
    // rightDown[0] = rightUp[0];
    // rightDown[1] = rightUp[1] + yOffset;
    // vec2 leftDown;
    // leftDown[0] = leftUp[0];
    // leftDown[1] = leftUp[1] + yOffset;

    if (update2dStartIndex < vertexCount2D) {
        update2dStartIndex = vertexCount2D;
    }

    //left-up
    vertices2D[vertexCount2D].position[0] = leftUp[0];
    vertices2D[vertexCount2D].position[1] = leftUp[1];
    vertices2D[vertexCount2D].position[2] = depth;
    vertices2D[vertexCount2D].uv[0] = 0.0;
    vertices2D[vertexCount2D].uv[1] = 1.0;
    // vertices2D[vertexCount2D].index = textureIndex;

    //right-up
    vertexCount2D += 1;
    vertices2D[vertexCount2D].position[0] = leftUp[0] + xOffset;
    vertices2D[vertexCount2D].position[1] = leftUp[1];
    vertices2D[vertexCount2D].position[2] = depth;
    vertices2D[vertexCount2D].uv[0] = 1.0;
    vertices2D[vertexCount2D].uv[1] = 1.0;
    // vertices2D[vertexCount2D].index = textureIndex;

    //right-dowm
    vertexCount2D += 1;
    vertices2D[vertexCount2D].position[0] = leftUp[0] + xOffset;
    vertices2D[vertexCount2D].position[1] = leftUp[1] + yOffset;
    vertices2D[vertexCount2D].position[2] = depth;
    vertices2D[vertexCount2D].uv[0] = 1.0;
    vertices2D[vertexCount2D].uv[1] = 0.0;
    // vertices2D[vertexCount2D].index = textureIndex;

    //left-down
    vertexCount2D += 1;
    vertices2D[vertexCount2D].position[0] = leftUp[0];
    vertices2D[vertexCount2D].position[1] = leftUp[1] + yOffset;
    vertices2D[vertexCount2D].position[2] = depth;
    vertices2D[vertexCount2D].uv[0] = 0.0;
    vertices2D[vertexCount2D].uv[1] = 0.0;
    // vertices2D[vertexCount2D].index = textureIndex;

    vertexCount2D += 1;

    for (0..4) |i| {
        std.log.debug("{}", .{vertices2D[vertexCount2D - 4 + i]});
    }

    updated2D = true;

    return vertexCount2D - 4;
}

pub fn upload(graphic: *Commands) !void {
    const zone = tracy.initZone(@src(), .{ .name = "vertices upload" });
    defer zone.deinit();

    if (updated2D) {
        const bufferSize = @sizeOf(Vertex2D) * (vertexCount2D - update2dStartIndex);
        const stagingBuffer = try vulkan.createStagingBuffer(@intCast(bufferSize));

        vulkan.buffers.copyDataToMapped(stagingBuffer, Vertex2D, vertices2D[update2dStartIndex..vertexCount2D]);

        var region = [_]vk.VkBufferCopy2{.{
            .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
            .pNext = null,
            .srcOffset = 0,
            .dstOffset = update2dStartIndex * @sizeOf(Vertex2D),
            .size = bufferSize,
        }};

        try graphic.cacheCommand(.{ .copyBuffer = .{
            .srcBuffer = stagingBuffer,
            .dstBuffer = vertexBuffer2D,
            .regions = &region,
        } });

        updated2D = false;
    }
}

pub fn addInstance(x: f32, y: f32, width: f32, height: f32, depth: f32, texture: textureSet.Texture_t) !u32 {
    const zone = tracy.initZone(@src(), .{ .name = "addInstance" });
    defer zone.deinit();

    // const textureContent = pTextureSet.getTextureCotent(texture);

    // const scale_x = width / @as(f32, @floatFromInt(textureContent.source_width));
    // const scale_y = height / @as(f32, @floatFromInt(textureContent.source_height));

    const ptr = try instances2D.addOne();
    ptr.* = .{
        .position = [3]f32{ x, y, depth },
        .scale = [2]f32{ width, height },
        .textureIndex = pTextureSet.getDescriptorSetIndex(texture),
    };
    instanceUpdated = true;

    updateEnd = @intCast(instances2D.items.len);

    return @intCast(instances2D.items.len - 1);
}

pub fn uploadInstance(graphic: *Commands) !void {
    const zone = tracy.initZone(@src(), .{ .name = "instances upload" });
    defer zone.deinit();

    if (instanceUpdated) {
        const bufferSize = @sizeOf(vertexStruct.Instance) * (updateEnd - updateStart);
        const stagingBuffer = try vulkan.createStagingBuffer(@intCast(bufferSize));

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
