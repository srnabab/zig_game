const std = @import("std");

const VkStruct = @import("video");
const processRender = @import("processRender");
const Commands = processRender.commands;

const file = @import("fileSystem");
const vertexStruct = @import("vertexStruct");

fn loadMeshlet(ID: i32, allocator: std.mem.Allocator, vulkan: *VkStruct, commands: *Commands) !void {
    const res = try file.getMeshLoadParam(ID);
    defer res.file.close();

    const stat = try res.file.stat();

    var buffer = [_]u8{0} ** 256;
    var fileReader = res.file.reader(&buffer);
    var content = try fileReader.interface.readAlloc(allocator, stat.size);

    const stride = l: {
        var size: usize = 0;
        switch (res.mesh.vertexType) {
            inline else => |t| {
                size = @sizeOf(vertexStruct.enumToType(t));
            },
        }
        break :l size;
    };

    const vertexCount = res.mesh.verticesSize / stride;

    const meshletsStart = res.mesh.verticesSize;
    const meshletVerticesStart = res.mesh.meshletsSize + meshletsStart;
    const meshletTrianglesStart = res.mesh.meshletVerticesSize + meshletVerticesStart;
    const indicesStart = res.mesh.meshletTrianglesSize + meshletTrianglesStart;

    const vertices = content[0..meshletsStart];
    const meshlets = content[meshletsStart..meshletVerticesStart];
    const meshletVertices = content[meshletVerticesStart..meshletTrianglesStart];
    const meshletTriangles = content[meshletTrianglesStart..indicesStart];
    const indices = content[indicesStart..];
}
