#version 460
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_ARB_separate_shader_objects : enable

layout(push_constant) uniform _PushConstants  {
    uint index;
} PushConstants;

layout(location = 0) in vec2 fragTexCoord;

// 全局绑定的纹理数组
// 假设绑定在 set = 0, binding = 0
layout(set = 1, binding = 0) uniform sampler2D textures[];

// 输出颜色
layout(location = 0) out vec4 outColor;

float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}
void main() {
    // 使用 nonuniformEXT 来访问纹理数组
    vec4 texColor = texture(textures[nonuniformEXT(PushConstants.index)], fragTexCoord);

    outColor = texColor;
    // outColor = vec4(1.0);
    // outColor = vec4(random(fragTexCoord), random(fragTexCoord + vec2(1.0)), random(fragTexCoord + vec2(2.0)), random(fragTexCoord + vec2(3.0)));
}
