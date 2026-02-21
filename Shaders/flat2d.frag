#version 450
#extension GL_EXT_nonuniform_qualifier : enable
#extension GL_ARB_separate_shader_objects : enable

// 从顶点着色器接收的输入
layout(location = 0) in vec2 fragTexCoord;
layout(location = 1) flat in uint fragTexIndex;

// 全局绑定的纹理数组
// 假设绑定在 set = 0, binding = 0
layout(set = 1, binding = 0) uniform sampler2D textures[];

// 输出颜色
layout(location = 0) out vec4 outColor;

void main() {
    // 使用 nonuniformEXT 来访问纹理数组
    vec4 texColor = texture(textures[nonuniformEXT(fragTexIndex)], fragTexCoord);

    outColor = texColor;
}
