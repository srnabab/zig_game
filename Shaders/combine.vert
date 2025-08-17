#version 460
 
layout(location = 0) out vec2 outUV;

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
    outUV = vec2(pos.x * 0.5 + 0.5, pos.y * 0.5 + 0.5);;

    // 如果你想传递NDC坐标本身给片段着色器，可以这样做：
    // out vec2 v_NdcPos; // 需要在上面声明
    // v_NdcPos = pos;
}