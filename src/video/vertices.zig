const std = @import("std");
const tracy = @import("tracy");
const cglm = @import("cglm").cglm;

const vkStruct = @import("video");
const vk = @import("vulkan").vulkan;
const global = @import("global");

const OneTimeCommand = @import("processRender").oneTimeCommand;

pub const vec3 = cglm.vec3;
pub const vec2 = cglm.vec2;

pub const Vertex2D = extern struct {
    position: vec3,
    texCoord: vec2,
    index: u32,
};

const vertex2DinitCount = 40000;
const index2DinitCount = std.math.maxInt(u16) / 6;

pub var vertices2D: []Vertex2D = &.{};
var vertexCount2D: u32 = 0;
var update2dStartIndex: u32 = 0;
pub var vertexBuffer2D: vkStruct.Buffer_t = undefined;
pub var indexBuffer2D: vkStruct.Buffer_t = undefined;
var updated2D = false;

var vulkan: *vkStruct = undefined;
var mutex = std.Thread.Mutex{};

pub fn init(vulkan_t: *vkStruct, graphic: *OneTimeCommand) !void {
    const zone = tracy.initZone(@src(), .{ .name = "vertices initialization" });
    defer zone.deinit();

    vulkan = vulkan_t;

    vertexBuffer2D = try vulkan.createVertexBuffer(vertex2DinitCount * @sizeOf(Vertex2D));
    indexBuffer2D = try vulkan.createIndexBuffer(index2DinitCount * 6 * @sizeOf(u16));
    vertices2D = try vulkan.allocator.alloc(Vertex2D, vertex2DinitCount);

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

        try graphic.addCommand(.copyBuffer, .{ .copyBuffer = .{
            .srcBuffer = stagingBuffer,
            .dstBuffer = indexBuffer2D,
            .regions = &region,
        } });
    }
}

pub fn deinit() void {
    vulkan.waitDevice() catch |err| {
        std.log.err("wait device error {s}\n", .{@errorName(err)});
        return;
    };

    vulkan.allocator.free(vertices2D);
    vulkan.destroyBuffer(vertexBuffer2D);
    vulkan.destroyBuffer(indexBuffer2D);
}

pub fn vertexInitialize2D(width: u32, height: u32, x: u32, y: u32, depth: f32, textureIndex: u32) !u32 {
    mutex.lock();
    defer mutex.unlock();

    if (vertices2D.len <= vertexCount2D) {
        vertices2D = try vulkan.allocator.realloc(vertices2D, vertexCount2D * 2);
    }

    const xOffset = @as(f32, @floatFromInt(width)) / (global.LOGICAL_HEIGHT / 2);
    const yOffset = @as(f32, @floatFromInt(height)) / (global.LOGICAL_HEIGHT / 2);

    var leftUp: vec2 = undefined;
    leftUp[0] = @as(f32, @floatFromInt(x)) / (global.LOGICAL_HEIGHT / 2);
    leftUp[1] = @as(f32, @floatFromInt(y)) / (global.LOGICAL_HEIGHT / 2);
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
    vertices2D[vertexCount2D].texCoord[0] = 0.0;
    vertices2D[vertexCount2D].texCoord[1] = 1.0;
    vertices2D[vertexCount2D].index = textureIndex;

    //right-up
    vertexCount2D += 1;
    vertices2D[vertexCount2D].position[0] = leftUp[0] + xOffset;
    vertices2D[vertexCount2D].position[1] = leftUp[1];
    vertices2D[vertexCount2D].position[2] = depth;
    vertices2D[vertexCount2D].texCoord[0] = 1.0;
    vertices2D[vertexCount2D].texCoord[1] = 1.0;
    vertices2D[vertexCount2D].index = textureIndex;

    //right-dowm
    vertexCount2D += 1;
    vertices2D[vertexCount2D].position[0] = leftUp[0] + xOffset;
    vertices2D[vertexCount2D].position[1] = leftUp[1] + yOffset;
    vertices2D[vertexCount2D].position[2] = depth;
    vertices2D[vertexCount2D].texCoord[0] = 1.0;
    vertices2D[vertexCount2D].texCoord[1] = 0.0;
    vertices2D[vertexCount2D].index = textureIndex;

    //left-down
    vertexCount2D += 1;
    vertices2D[vertexCount2D].position[0] = leftUp[0];
    vertices2D[vertexCount2D].position[1] = leftUp[1] + yOffset;
    vertices2D[vertexCount2D].position[2] = depth;
    vertices2D[vertexCount2D].texCoord[0] = 0.0;
    vertices2D[vertexCount2D].texCoord[1] = 0.0;
    vertices2D[vertexCount2D].index = textureIndex;

    vertexCount2D += 1;

    for (0..4) |i| {
        std.log.debug("{}", .{vertices2D[vertexCount2D - 4 + i]});
    }

    updated2D = true;

    return vertexCount2D - 4;
}

pub fn upload(graphic: *OneTimeCommand) !void {
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

        try graphic.addCommand(.copyBuffer, .{ .copyBuffer = .{
            .srcBuffer = stagingBuffer,
            .dstBuffer = vertexBuffer2D,
            .regions = &region,
        } });

        updated2D = false;
    }
}
