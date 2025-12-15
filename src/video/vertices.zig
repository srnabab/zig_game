const std = @import("std");
const tracy = @import("tracy");
const cglm = @import("cglm").cglm;

const vkStruct = @import("video");
const vk = @import("vulkan").vulkan;
const global = @import("global");

const OneTimeCommand = @import("processRender").oneTimeCommand;

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
pub var vertexBuffer2D: vkStruct.Buffer_t = undefined;
pub var indexBuffer2D: vkStruct.Buffer_t = undefined;
var vulkan: *vkStruct = undefined;

pub fn init(vulkan_t: *vkStruct, graphic: *OneTimeCommand) !void {
    const zone = tracy.initZone(@src(), .{ .name = "vertices initialization" });
    defer zone.deinit();

    vulkan = vulkan_t;

    vertexBuffer2D = try vulkan.createVertexBuffer(vertex2DinitCount * @sizeOf(Vertex2D));
    indexBuffer2D = try vulkan.createIndexBuffer(index2DinitCount * 6 * @sizeOf(u16));

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

    vulkan.destroyBuffer(vertexBuffer2D);
    vulkan.destroyBuffer(indexBuffer2D);
}
