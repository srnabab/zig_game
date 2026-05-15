#version 460
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in vec2 uv; // Texture coordinates from full-screen quad
layout(location = 1) in flat uint texIndex;

layout(location = 0) out vec4 finalColor;

layout(set = 0, binding = 0) uniform texture2D textures[];
layout(set = 0, binding = 1) uniform writeonly image2D images[];
layout(set = 0, binding = 2) uniform sampler samplers[1];

void main() {
    finalColor = texture(sampler2D(textures[nonuniformEXT(texIndex)], samplers[0]), uv);
}
