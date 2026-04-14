const std = @import("std");

pub const meshopt = @cImport(@cInclude("meshoptimizer.h"));

pub const remapReturn = struct {
    indices: []u32,
    vertices: ?*anyopaque,
    newVertexCount: usize,
    totalVerticesSize: usize,
    vertexSize: usize,
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
        .newVertexCount = unique_vertex_count,
        .totalVerticesSize = unique_vertex_count * vertexSize,
        .vertexSize = vertexSize,
    };
}

pub fn vertexOptimization(indices: []u32, vertex_positions: [*c]f32, vertexCount: usize, vertexSize: usize, allocator: std.mem.Allocator) !remapReturn {
    const cache_indices = try allocator.alloc(u32, indices.len);
    defer allocator.free(cache_indices);

    meshopt.meshopt_optimizeVertexCache(
        cache_indices.ptr,
        indices.ptr,
        indices.len,
        vertexCount,
    );

    const overdraw_indices = try allocator.alloc(u32, indices.len);

    meshopt.meshopt_optimizeOverdraw(
        overdraw_indices.ptr,
        cache_indices.ptr,
        indices.len,
        vertex_positions,
        vertexCount,
        vertexSize,
        1.05,
    );

    const fetch_vertices = try allocator.alloc(u8, vertexCount * vertexSize);

    const unique_vertex_count = meshopt.meshopt_optimizeVertexFetch(
        fetch_vertices.ptr,
        overdraw_indices.ptr,
        indices.len,
        vertex_positions,
        vertexCount,
        vertexSize,
    );

    return .{
        .indices = overdraw_indices,
        .vertices = fetch_vertices.ptr,
        .newVertexCount = unique_vertex_count,
        .totalVerticesSize = vertexCount * vertexSize,
        .vertexSize = vertexSize,
    };
}

const analyzeStatics = struct {
    vertexCache: meshopt.meshopt_VertexCacheStatistics,
    overdraw: meshopt.meshopt_OverdrawStatistics,
    vertexFetch: meshopt.meshopt_VertexFetchStatistics,
};

pub fn analyzeVertex(indices: []u32, vertex_positions: [*c]f32, vertexCount: usize, vertexSize: usize) analyzeStatics {
    const cache = meshopt.meshopt_analyzeVertexCache(
        indices.ptr,
        indices.len,
        vertexCount,
        32,
        32,
        0,
    );

    const overdraw = meshopt.meshopt_analyzeOverdraw(
        indices.ptr,
        indices.len,
        vertex_positions,
        vertexCount,
        vertexSize,
    );

    const fetch = meshopt.meshopt_analyzeVertexFetch(
        indices.ptr,
        indices.len,
        vertexCount,
        vertexSize,
    );

    return .{
        .vertexCache = cache,
        .overdraw = overdraw,
        .vertexFetch = fetch,
    };
}
