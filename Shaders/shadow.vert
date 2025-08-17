#version 460

layout(set = 0, binding = 0) uniform LightSpaceMatrix{
    mat4 lightSpaceMatrix;
} ubo;

layout(location = 0) in vec3 inPosition;

// instance buffer
layout(location = 1) in mat4 inModelMatrix;

void main() 
{
    gl_Position = ubo.lightSpaceMatrix * inModelMatrix * vec4(inPosition, 1.0);
}