#version 460

layout(set = 0, binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

layout(location = 0) in vec2 inPosition;
layout(location = 1) in vec3 inColor;
// layout(location = 2) in vec2 inFlag;

layout(push_constant) uniform PushConstans {
    vec2 offset;
    vec2 scale;
} pc;

layout(location = 0) out vec3 fragColor;

void main()
{
    vec2 finalPosition = inPosition * pc.scale + pc.offset;

    fragColor = inColor;
    gl_Position = ubo.proj * ubo.view * ubo.model * vec4(finalPosition, 0.0, 1.0);
}
