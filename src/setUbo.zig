const u8pack = @import("u8pack");
const renderFlow = @import("renderFlow");

const cglm = @import("cglm");

const mat4 = cglm.mat4;

pub const UniformBufferObject = extern struct {
    view: mat4,
    proj: mat4,
};

pub const UniformBufferObjectCamera = extern struct {
    view: mat4,
    proj: mat4,
    cameraPos: cglm.vec3,
    _1: f32,
    lightDirection: cglm.vec3,
    _2: f32,
};

pub fn setUbo(comptime ctx: ?*u8pack.CTX) !void {
    try renderFlow.addUbo(ctx, "fixed2d", @sizeOf(UniformBufferObject), .ui);
    try renderFlow.addUbo(ctx, "camera3d", @sizeOf(UniformBufferObjectCamera), .@"3d");
}
