const std = @import("std");

pub const meshopt = @cImport(@cInclude("meshoptimizer.h"));

pub const remapReturn = struct {
    indices: []u32,
    vertices: ?*anyopaque,
    vertexCount: usize,
};

pub fn generateVertexRemap(
    indices: []u32,
    vertices: ?*anyopaque,
    vertexCount: usize,
    vertexSize: usize,
    allocator: std.mem.Allocator,
) !remapReturn {
    const remap = try allocator.alloc(u32, vertexCount);
    defer allocator.free(remap);

    const unique_vertex_count = meshopt.meshopt_generateVertexRemap(
        remap.ptr,
        indices.ptr,
        indices.len,
        vertices,
        vertexCount,
        vertexSize,
    );

    const new_vertices = try allocator.alloc(u8, unique_vertex_count * vertexSize);
    const new_indices = try allocator.alloc(u32, indices.len);

    meshopt.meshopt_remapVertexBuffer(
        new_vertices.ptr,
        vertices,
        vertexCount,
        vertexSize,
        remap.ptr,
    );
    meshopt.meshopt_remapIndexBuffer(
        new_indices.ptr,
        indices.ptr,
        indices.len,
        remap.ptr,
    );

    return .{
        .indices = new_indices,
        .vertices = new_vertices.ptr,
        .vertexCount = unique_vertex_count,
    };
}
