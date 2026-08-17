#version 460
#extension GL_EXT_scalar_block_layout : require

layout(set = 1, binding = 0) uniform UniformBufferObject {
    mat4 view;
    mat4 proj;
} ubo;
 
layout(location = 0) out vec2 outUV;
layout(location = 1) out flat uint texIndex;

layout(push_constant, scalar) uniform PushConstants {
    uint texIndex;
} pc;

const vec2 positions[6] = vec2[](
    vec2(-1.0, 1.0), // 左下角 (Triangle 1, Vertex 0)
    vec2( 1.0, 1.0), // 右下角 (Triangle 1, Vertex 1)
    vec2(1.0,  -1.0), // 右上角 (Triangle 1, Vertex 2)

    vec2( 1.0, -1.0), // 右下角 (Triangle 2, Vertex 3) - 重复
    vec2( -1.0,  -1.0), // 右上角 (Triangle 2, Vertex 4)
    vec2(-1.0,  1.0)  // 左上角 (Triangle 2, Vertex 5) - 重复
);

void main() {
    // 从数组中获取当前顶点的位置
    vec2 pos = positions[gl_VertexIndex];

    // gl_Position 是内置变量，必须设置，表示顶点的最终裁剪空间位置
    // 对于2D全屏，Z通常设为0或-1，W设为1
    gl_Position = vec4(pos, 0.0, 1.0);

    // 计算并传递纹理坐标 (将NDC坐标 -1..1 映射到 UV坐标 0..1)
    // uv.x = (pos.x + 1.0) * 0.5;
    // uv.y = (pos.y + 1.0) * 0.5;
    outUV = vec2(pos.x * 0.5 + 0.5, pos.y * 0.5 + 0.5);
    texIndex = pc.texIndex;
}
