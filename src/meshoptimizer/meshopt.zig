const std = @import("std");

pub const Max_Vertices = 64;
pub const Max_Triangles = 124;

pub const meshopt = @cImport(@cInclude("meshoptimizer.h"));

pub const meshopt_Meshlet = meshopt.meshopt_Meshlet;

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

pub const MeshletResult = struct {
    meshlets: []meshopt.meshopt_Meshlet,
    meshlet_vertices: []u32,
    meshlet_triangles: []u8,
};

pub fn clusterization(vertex_positions: [*c]f32, vertexCount: usize, vertexSize: usize, indices: []u32, allocator: std.mem.Allocator) !MeshletResult {
    const max_meshlets = meshopt.meshopt_buildMeshletsBound(indices.len, Max_Vertices, Max_Triangles);

    var meshlets = try allocator.alloc(meshopt.meshopt_Meshlet, max_meshlets);
    var meshlet_vertices = try allocator.alloc(u32, indices.len);
    var meshlet_triangles = try allocator.alloc(u8, indices.len);

    const meshlet_count = meshopt.meshopt_buildMeshlets(
        meshlets.ptr,
        meshlet_vertices.ptr,
        meshlet_triangles.ptr,
        indices.ptr,
        indices.len,
        vertex_positions,
        vertexCount,
        vertexSize,
        Max_Vertices,
        Max_Triangles,
        0.0,
    );

    const last_meshlet = &meshlets[meshlet_count - 1];
    meshlet_vertices = try allocator.realloc(meshlet_vertices, last_meshlet.vertex_offset + last_meshlet.vertex_count);
    meshlet_triangles = try allocator.realloc(meshlet_triangles, last_meshlet.triangle_offset + last_meshlet.triangle_count * 3);
    meshlets = try allocator.realloc(meshlets, meshlet_count);

    for (meshlets) |m| {
        meshopt.meshopt_optimizeMeshlet(
            &meshlet_vertices[m.vertex_offset],
            &meshlet_triangles[m.triangle_offset],
            m.triangle_count,
            m.vertex_count,
        );
    }

    return .{
        .meshlets = meshlets,
        .meshlet_vertices = meshlet_vertices,
        .meshlet_triangles = meshlet_triangles,
    };
}
