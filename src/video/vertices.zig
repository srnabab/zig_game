const std = @import("std");
const tracy = @import("tracy");
const cglm = @import("cglm").cglm;

const vkStruct = @import("video");
const vk = @import("vulkan").vulkan;
const global = @import("global");

pub const vec3 = cglm.vec3;
pub const vec2 = cglm.vec3;

pub const Vertex2D = extern struct {
    position: vec3,
    texCoord: vec2,
    index: u32,
};

const vertex2DinitCount = 40000;
const index2DinitCount = std.math.maxInt(u16) / 6;

pub var vertices2D: []Vertex2D = &.{};
pub var vertexBuffer2D: vkStruct.Buffer = undefined;
pub var indexBuffer2D: vkStruct.Buffer = undefined;

pub fn init() !void {
    const zone = tracy.initZone(@src(), .{ .name = "vertices initialization" });
    defer zone.deinit();

    vertexBuffer2D = try global.vulkan.createVertexBuffer(vertex2DinitCount * @sizeOf(Vertex2D));
    indexBuffer2D = try global.vulkan.createIndexBuffer(index2DinitCount * @sizeOf(u16));

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

        const stagingBuffer = try global.vulkan.createStagingBuffer(indices.len * @sizeOf(u16));
        @memcpy(@as([*c]u16, @ptrCast(@alignCast(stagingBuffer.info.pMappedData.?))), &indices);

        var region = [_]vk.VkBufferCopy{.{
            .srcOffset = 0,
            .dstOffset = 0,
            .size = indexBuffer2D.info.size,
        }};

        try global.graphic.addCommand(.copyBuffer, .{ .copyBuffer = .{
            .srcBuffer = stagingBuffer,
            .dstBuffer = indexBuffer2D,
            .regions = &region,
        } });
    }
}

pub fn deinit() void {
    global.vulkan.waitDevice() catch |err| {
        std.log.err("wait device error {s}\n", .{@errorName(err)});
        return;
    };

    global.vulkan.destroyBuffer(vertexBuffer2D);
    global.vulkan.destroyBuffer(indexBuffer2D);
}
