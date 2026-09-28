const std = @import("std");

const u8pack = @import("u8pack");
const renderFlow = @import("renderFlow");

const VkStruct = @import("video");
const math = @import("ms_std").Math;

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

pub fn initUbo(vulkan: *VkStruct) void {
    var pUIUbo: UniformBufferObject align(16) = undefined;

    var pUIUbo2: UniformBufferObjectCamera align(16) = undefined;

    const aspect2: f32 = 1.0 * (@as(f32, @floatFromInt(vulkan.windowHeight))) / 2;
    const aspect: f32 = (@as(f32, @floatFromInt(vulkan.windowWidth)) / @as(f32, @floatFromInt(vulkan.windowHeight))) * aspect2;
    const VIEW_SCALE = 1.0;

    var eye = cglm.vec3{ 0.0, 0.0, 100.0 };
    var center = cglm.vec3{ 0.0, 0.0, 0.0 };
    var up = cglm.vec3{ 0.0, 1.0, 0.0 };
    cglm.glmc_lookat(
        &eye,
        &center,
        &up,
        &pUIUbo.view,
    );
    math.glm_ortho_vulkan(
        -aspect * VIEW_SCALE,
        aspect * VIEW_SCALE,
        -aspect2 * VIEW_SCALE,
        aspect2 * VIEW_SCALE,
        -0.001,
        -100.0,
        &pUIUbo.proj,
    );

    vulkan.copyToUbo(&pUIUbo, u8pack.toStr("fixed2d"), .ui);

    var eye2 = cglm.vec3{ 1.0, 1.0, 1.0 };
    var center2 = cglm.vec3{ 0.0, 0.0, 0.0 };
    var up2 = cglm.vec3{ 0.0, 0.0, 1.0 };
    cglm.glmc_lookat(
        &eye2,
        &center2,
        &up2,
        &pUIUbo2.view,
    );
    cglm.glmc_perspective(std.math.rad_per_deg * 60.0, (aspect / 300) * VIEW_SCALE, 0.1, 100.0, &pUIUbo2.proj);
    // pUIUbo2.proj[1][1] *= -1;
    pUIUbo2.cameraPos = eye2;
    pUIUbo2.lightDirection = cglm.vec3{ 0.0, 0.5, 1.5 };

    vulkan.copyToUbo(&pUIUbo2, u8pack.toStr("camera3d"), ._3d);
}
