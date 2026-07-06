pub const cglm = @import("cglm");

const std = @import("std");

pub const vec4 = cglm.vec4;
pub const vec3 = cglm.vec3;
pub const vec2 = cglm.vec2;
pub const mat3 = cglm.mat3;
pub const mat4 = cglm.mat4;
pub const ivec3 = cglm.ivec3;

const Self = @This();

pub const GroupMapping = extern struct {
    instanceID: u32,
    meshID: u32,
};

pub const Instance3D = extern struct {
    matrix: mat4,
    texIndex: u32,
    samplerIndex: u32,
};

pub const Mesh = struct {
    meshletCount: u32,
    meshletOffset: u32,
    verticesOffset: u32,
    meshletVerticesOffset: u32,
    meshletTrianglesOffset: u32,
    verticeStride: u32,
};

pub const CustomDrawMeshTasksIndirectCommand = extern struct {
    groupCountX: u32 = 0,
    groupCountY: u32 = 0,
    groupCountZ: u32 = 0,
    workgroupOffset: u32 = 0,
};

pub const MetaData = extern struct {
    meshletCount: u32,

    meshletOffset: u32,
    verticesOffset: u32,
    meshletVerticesOffset: u32,
    meshletTrianglesOffset: u32,
};

pub const Instance = extern struct {
    position: vec3,
    scale: vec2,
    textureIndex: u32,
    samplerIndex: u16,
    flags: u16,
};

pub const Meshlet = extern struct {
    vertexOffset: u32,
    primitiveOffset: u32,
    vertexCount: u32,
    primitiveCount: u32,
};

pub const Vertex_f3pf3nf2u = extern struct {
    position: vec3,
    normal: vec3,
    uv: vec2,
};

pub const Vertex_f3pf2u = extern struct {
    position: vec3,
    uv: vec2,
};

pub const Vertex_f3p = extern struct {
    position: vec3,
};

pub const Vertex_f3pf3n = extern struct {
    position: vec3,
    normal: vec3,
};

pub const Vertex_f3pf3nf3tf2u = extern struct {
    position: vec3,
    normal: vec3,
    tangent: vec3,
    uv: vec2,
};

pub const VertexType = enum {
    none,
    f3p,
    f3pf3n,
    f3pf2u,
    f3pf3nf2u,
    f3pf3nf3tf2u,
};

pub const Vertex = union(VertexType) {
    none: void,
    f3p: []Vertex_f3p,
    f3pf3n: []Vertex_f3pf3n,
    f3pf2u: []Vertex_f3pf2u,
    f3pf3nf2u: []Vertex_f3pf3nf2u,
    f3pf3nf3tf2u: []Vertex_f3pf3nf3tf2u,
};

pub fn enumToType(vType: VertexType) type {
    switch (vType) {
        .none => return void,
        inline else => {
            const name = std.fmt.comptimePrint("Vertex_{s}", .{@tagName(vType)});
            return @field(Self, name);
        },
    }
}
