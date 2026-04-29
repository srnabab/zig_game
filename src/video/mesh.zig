const std = @import("std");

const vk = @import("vulkan");
const VkStruct = @import("video");
const processRender = @import("processRender");
const Commands = processRender.commands;

const file = @import("fileSystem");
const vertexStruct = @import("vertexStruct");

const Self = @This();

meshletBuffer: ?VkStruct.Buffer_t = null,
vertexBuffer: VkStruct.Buffer_t,
meshletVertexBuffer: ?VkStruct.Buffer_t = null,
meshletTriangleBuffer: ?VkStruct.Buffer_t = null,

indexBuffer: ?VkStruct.Buffer_t = null,

io: std.Io,

meshletCount: u32 = 0,
isMeshlet: bool = false,

pub fn init(
    meshletBuffer: ?VkStruct.Buffer_t,
    vertexBuffer: VkStruct.Buffer_t,
    meshletVertexBuffer: ?VkStruct.Buffer_t,
    meshletTriangleBuffer: ?VkStruct.Buffer_t,
    indexBuffer: ?VkStruct.Buffer_t,
    io: std.Io,
) Self {
    std.debug.assert(
        (meshletBuffer == null and meshletVertexBuffer == null and meshletTriangleBuffer == null) ^ (indexBuffer == null),
    );
    std.log.debug("size {d}", .{@sizeOf(vertexStruct.Vertex_f3pf3nf2u)});

    return Self{
        .meshletBuffer = meshletBuffer,
        .vertexBuffer = vertexBuffer,
        .meshletVertexBuffer = meshletVertexBuffer,
        .meshletTriangleBuffer = meshletTriangleBuffer,
        .indexBuffer = indexBuffer,
        .isMeshlet = (indexBuffer == null),
        .io = io,
    };
}

pub fn loadMeshlet(self: *Self, ID: i32, allocator: std.mem.Allocator, vulkan: *VkStruct, commands: *Commands) !void {
    const res = try file.getMeshLoadParam(self.io, ID);
    defer res.file.close(self.io);

    const stat = try res.file.stat(self.io);

    var buffer = [_]u8{0} ** 256;
    var fileReader = res.file.reader(self.io, &buffer);
    var content = try fileReader.interface.readAlloc(allocator, stat.size);
    defer allocator.free(content);

    // const stride = l: {
    //     var size: usize = 0;
    //     switch (res.mesh.vertexType) {
    //         inline else => |t| {
    //             size = @sizeOf(vertexStruct.enumToType(t));
    //         },
    //     }
    //     break :l size;
    // };

    // const vertexCount = res.mesh.verticesSize / stride;
    // std.log.debug("vertex count {d}", .{vertexCount});

    const meshletsStart = res.mesh.verticesSize;
    const meshletVerticesStart = res.mesh.meshletsSize + meshletsStart;
    const meshletTrianglesStart = res.mesh.meshletVerticesSize + meshletVerticesStart;
    const indicesStart = res.mesh.meshletTrianglesSize + meshletTrianglesStart;

    const vertices = content[0..meshletsStart];
    const meshlets = content[meshletsStart..meshletVerticesStart];
    const meshletVertices = content[meshletVerticesStart..meshletTrianglesStart];
    const meshletTriangles = content[meshletTrianglesStart..indicesStart];
    const indices = content[indicesStart..];

    // std.log.debug("pos 1311 {d}, {d}, {d}, {d}, {d}, {d}, {d}, {d}", .{
    //     vertices[stride * 1311 + 0],
    //     vertices[stride * 1311 + 1],
    //     vertices[stride * 1311 + 2],
    //     vertices[stride * 1311 + 3],
    //     vertices[stride * 1311 + 4],
    //     vertices[stride * 1311 + 5],
    //     vertices[stride * 1311 + 6],
    //     vertices[stride * 1311 + 7],
    // });

    // std.log.debug("len {d}", .{vertices.len});

    const meshletCount = meshlets.len / @sizeOf(vertexStruct.Meshlet);
    self.meshletCount += @intCast(meshletCount);

    if (self.isMeshlet) {
        const stagingBuffer1 = try vulkan.createStagingBuffer(@intCast(vertices.len));
        vulkan.buffers.copyDataToMapped(stagingBuffer1, u8, vertices);
        const stagingBuffer2 = try vulkan.createStagingBuffer(@intCast(meshlets.len));
        vulkan.buffers.copyDataToMapped(stagingBuffer2, u8, meshlets);
        const stagingBuffer3 = try vulkan.createStagingBuffer(@intCast(meshletVertices.len));
        vulkan.buffers.copyDataToMapped(stagingBuffer3, u8, meshletVertices);
        const stagingBuffer4 = try vulkan.createStagingBuffer(@intCast(meshletTriangles.len));
        vulkan.buffers.copyDataToMapped(stagingBuffer4, u8, meshletTriangles);

        var bufferContent = vulkan.buffers.getBufferContent(stagingBuffer1);
        // std.log.debug("buffer size {d}", .{bufferContent.size});

        const allocBuffer1 = try vulkan.createVirtualBuffer(
            self.vertexBuffer,
            0,
            @intCast(vertices.len),
            16,
        );

        var region = vk.VkBufferCopy2{
            .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
            .pNext = null,
            .srcOffset = 0,
            .size = @intCast(vertices.len),
            .dstOffset = allocBuffer1.offset,
        };
        // std.log.debug("offset {d}", .{allocBuffer1.offset});

        var regions = [_]vk.VkBufferCopy2{region};

        try commands.cacheCommand(.{ .copyBuffer = .{
            .srcBuffer = stagingBuffer1,
            .dstBuffer = allocBuffer1.buffer,
            .regions = &regions,
        } });

        bufferContent = vulkan.buffers.getBufferContent(stagingBuffer2);

        const allocBuffer2 = try vulkan.createVirtualBuffer(
            self.meshletBuffer.?,
            0,
            @intCast(meshlets.len),
            16,
        );

        region = vk.VkBufferCopy2{
            .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
            .pNext = null,
            .srcOffset = 0,
            .size = @intCast(meshlets.len),
            .dstOffset = allocBuffer2.offset,
        };
        // std.log.debug("offset {d}", .{allocBuffer2.offset});

        regions[0] = region;

        try commands.cacheCommand(.{ .copyBuffer = .{
            .srcBuffer = stagingBuffer2,
            .dstBuffer = allocBuffer2.buffer,
            .regions = &regions,
        } });

        bufferContent = vulkan.buffers.getBufferContent(stagingBuffer3);

        const allocBuffer3 = try vulkan.createVirtualBuffer(
            self.meshletVertexBuffer.?,
            0,
            @intCast(meshletVertices.len),
            16,
        );

        region = vk.VkBufferCopy2{
            .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
            .pNext = null,
            .srcOffset = 0,
            .size = @intCast(meshletVertices.len),
            .dstOffset = allocBuffer3.offset,
        };
        // std.log.debug("offset {d}", .{allocBuffer3.offset});

        regions[0] = region;

        try commands.cacheCommand(.{ .copyBuffer = .{
            .srcBuffer = stagingBuffer3,
            .dstBuffer = allocBuffer3.buffer,
            .regions = &regions,
        } });

        bufferContent = vulkan.buffers.getBufferContent(stagingBuffer4);

        const allocBuffer4 = try vulkan.createVirtualBuffer(
            self.meshletTriangleBuffer.?,
            0,
            @intCast(meshletTriangles.len),
            16,
        );

        region = vk.VkBufferCopy2{
            .sType = vk.VK_STRUCTURE_TYPE_BUFFER_COPY_2,
            .pNext = null,
            .srcOffset = 0,
            .size = @intCast(meshletTriangles.len),
            .dstOffset = allocBuffer4.offset,
        };
        // std.log.debug("offset {d}", .{allocBuffer4.offset});

        regions[0] = region;

        try commands.cacheCommand(.{ .copyBuffer = .{
            .srcBuffer = stagingBuffer4,
            .dstBuffer = allocBuffer4.buffer,
            .regions = &regions,
        } });
    } else {
        const stagingBuffer1 = try vulkan.createStagingBuffer(@intCast(vertices.len));
        const stagingBuffer2 = try vulkan.createStagingBuffer(@intCast(indices.len));
        _ = stagingBuffer1;
        _ = stagingBuffer2;
        // _ = indices;
    }

    // try commands.cacheCommand(.{.copyBuffer = .{ .dstBuffer =  }})
}
