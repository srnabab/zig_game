#version 460

layout(set = 0, binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec2 inTexCoord;
layout(location = 3) in vec3 inNormal;

// instance buffer
layout(location = 4) in mat4 inModelMatrix;
layout(location = 8) in mat4 inverseTransposeModelMatrix;

layout(location = 0) out vec3 fragColor;
layout(location = 1) out vec2 fragTexCoord;
layout(location = 2) out vec3 outWorldPos;
layout(location = 3) out vec3 outWorldNormal;
// layout(location = 4) out int instanceIndex;

void main() 
{
    outWorldPos = (inModelMatrix * vec4(inPosition, 1.0)).xyz;

    outWorldNormal = normalize((inverseTransposeModelMatrix * vec4(inNormal, 0.0)).xyz);

    fragColor = inColor;
    fragTexCoord = inTexCoord;
    // instanceIndex = gl_InstanceIndex;

    gl_Position = ubo.proj * ubo.view * inModelMatrix * vec4(inPosition, 1.0);
}