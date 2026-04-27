#version 460
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_ARB_separate_shader_objects : enable

layout(location = 0) in vec2 fragTexCoord;
layout(location = 1) flat in uint fragTexIndex;

layout(set = 1, binding = 0) uniform sampler2D textures[];

layout(location = 0) out vec4 outColor;

float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}
void main() {
    vec4 texColor = texture(textures[nonuniformEXT(fragTexIndex)], fragTexCoord);

    outColor = texColor;
    // outColor = vec4(1.0);
    // outColor = vec4(random(fragTexCoord), random(fragTexCoord + vec2(1.0)), random(fragTexCoord + vec2(2.0)), random(fragTexCoord + vec2(3.0)));
}
