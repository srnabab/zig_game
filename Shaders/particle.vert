#version 460

layout(set = 0, binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

layout(location = 0) in vec2 inPosition;
layout(location = 1) in vec4 inColor;

layout(location = 0) out vec3 fragColor;

void main() {
    gl_PointSize = 4.0;
    gl_Position = ubo.proj * ubo.view * vec4(inPosition.xy, 0.9, 1.0);
    fragColor = inColor.rgb;
}