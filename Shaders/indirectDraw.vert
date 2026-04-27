#version 460

#extension GL_EXT_scalar_block_layout : require
#extension GL_EXT_buffer_reference : require

struct Instance {
    vec3 pos;
    vec2 scale;
    uint textureIndex;
};

layout(buffer_reference, scalar) readonly buffer InstanceBuffer {
    Instance instances[]; 
};

layout(push_constant) uniform PushConstants {
    InstanceBuffer instanceBuffer;
} pc;

layout(set = 0, binding = 0) uniform UniformBufferObject {
    mat4 view;
    mat4 proj;
} ubo;

layout(location = 0) out vec2 outUV;
layout(location = 1) flat out uint outTexIndex;

void main() {
    Instance sprite = pc.instanceBuffer.instances[gl_InstanceIndex];

    vec2 positions[4] = vec2[](vec2(0,0), vec2(1,0), vec2(1,1), vec2(0,1));
    vec2 uvs[4]       = vec2[](vec2(0,0), vec2(1,0), vec2(1,1), vec2(0,1));
    int indices[6]    = int[](0, 1, 2, 2, 3, 0);

    int vIdx = indices[gl_VertexIndex];
    vec2 localPos = positions[vIdx];
    
    // 4. 计算最终位置
    vec2 worldPos = localPos * sprite.scale + sprite.pos.xy;
    gl_Position = ubo.proj * ubo.view * vec4(worldPos, sprite.pos.z, 1.0);
    
    outUV = uvs[vIdx];
    outTexIndex = sprite.textureIndex;
}
