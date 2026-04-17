const vk = @import("vulkan");

const cglm = @import("cglm");

const mat4 = cglm.mat4;

pub const UniformBufferObject = extern struct {
    view: mat4,
    proj: mat4,
};
