#version 460 

layout(set = 0, binding = 1) uniform sampler2D texSampler;

layout(location = 0) in vec3 fragColor;
layout(location = 1) in vec2 fragTexCoord;
layout(location = 2) in float fragDepth;

layout(location = 0) out vec4 outColor;

void main() 
{
    vec4 color = texture(texSampler, fragTexCoord);

    outColor = vec4(vec3(1.0), sign(color.r)) * step(abs(fragDepth - 0.1), 0.0) +
        color * sign(abs(fragDepth - 0.1));
}