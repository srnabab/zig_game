#version 460
#extension GL_ARB_separate_shader_objects : enable

// layout(push_constant) uniform _PushConstans{
//     float rotation;
// } PushConstants;

layout(set = 0, binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec2 inTexCoord;
layout(location = 2) in uint intTexIndex;

layout(location = 0) out vec2 fragTexCoord;
layout(location = 1) flat out uint fragTexIndex;

void main() 
{
    gl_Position = ubo.proj * ubo.view * vec4(inPosition ,1.0);
    fragTexCoord = inTexCoord;
    fragTexIndex = intTexIndex;
}
