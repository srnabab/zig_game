#version 460
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_ARB_separate_shader_objects : enable

layout(location = 0) in vec2 fragTexCoord;
layout(location = 1) flat in uint fragTexIndex;
layout(location = 2) flat in uint samplerIndex;

layout(set = 0, binding = 0) uniform texture2D textures[];
layout(set = 0, binding = 1) uniform writeonly image2D images[];
layout(set = 0, binding = 2) uniform sampler samplers[1];
layout(set = 0, binding = 2) uniform samplerShadow shadowSamplers[1];

layout(location = 0) out vec4 outColor;

void main() {
    vec4 texColor = texture(sampler2D(textures[nonuniformEXT(fragTexIndex)], samplers[samplerIndex]), fragTexCoord);

    outColor = texColor;
}
