#version 460

layout(push_constant) uniform _PushConstans{
    float rotation;
} PushConstants;

layout(set = 0, binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

layout(location = 0) in vec3 inPosition;
layout(location = 1) in vec3 inColor;
layout(location = 2) in vec2 inTexCoord;

layout(location = 0) out vec3 fragColor;
layout(location = 1) out vec2 fragTexCoord;
layout(location = 2) out float fragDepth;

void main() 
{
    fragColor = inColor;
    // fragColor = vec3(inTexCoord, 0.0);
    fragTexCoord = inTexCoord;
    fragDepth = inPosition.z;

    mat2 rotationMatrix = mat2(
        cos(PushConstants.rotation), -sin(PushConstants.rotation),
        sin(PushConstants.rotation), cos(PushConstants.rotation)
    );
    vec3 rotatedPosition = vec3(rotationMatrix * inPosition.xy, inPosition.z);

    vec3 position = rotatedPosition * step(abs(inPosition.z - 0.2), 0.0) + inPosition * sign(abs(inPosition.z - 0.2));

    gl_Position = ubo.proj * ubo.view  * vec4(position, 1.0);
}