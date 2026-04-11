pub const cglm = @import("cglm").cglm;

pub const vec3 = cglm.vec3;
pub const vec2 = cglm.vec2;

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

pub const VertexType = enum {
    none,
    f3p,
    f3pf3n,
    f3pf2u,
    f3pf3nf2u,
};

pub const Vertex = union(VertexType) {
    none: void,
    f3p: []Vertex_f3p,
    f3pf3n: []Vertex_f3pf3n,
    f3pf2u: []Vertex_f3pf2u,
    f3pf3nf2u: []Vertex_f3pf3nf2u,
};
