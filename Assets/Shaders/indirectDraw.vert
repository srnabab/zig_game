#version 460

#extension GL_EXT_scalar_block_layout : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_shader_explicit_arithmetic_types_int16 : require

struct Instance {
    vec3 pos;
    vec2 scale;
    uint textureIndex;
    uint16_t samplerIndex;
    uint16_t flag;
};

layout(buffer_reference, scalar) readonly buffer InstanceBuffer {
    Instance instances[]; 
};
layout(buffer_reference) buffer InstanceIDBuffer {
    uint instanceIDs[];
};

layout(push_constant) uniform PushConstants {
    InstanceBuffer instanceBuffer;
    InstanceIDBuffer instanceIDs;
} pc;

layout(set = 1, binding = 0) uniform UniformBufferObject {
    mat4 view;
    mat4 proj;
} ubo;

layout(location = 0) out vec2 outUV;
layout(location = 1) flat out uint outTexIndex;
layout(location = 2) flat out uint outSamplerIndex;

void main() {
    uint idx = pc.instanceIDs.instanceIDs[gl_InstanceIndex];
    Instance sprite = pc.instanceBuffer.instances[idx];

    vec2 positions[4] = vec2[](vec2(0,0), vec2(1,0), vec2(1,1), vec2(0,1));
    vec2 uvs[4]       = vec2[](vec2(0,0), vec2(1,0), vec2(1,1), vec2(0,1));
    int indices[6]    = int[](0, 1, 2, 2, 3, 0);

    int vIdx = indices[gl_VertexIndex];
    vec2 localPos = positions[vIdx];

    float depthZ = float(idx) / 1000000.0 + sprite.pos.z; 

    vec2 worldPos = localPos * sprite.scale + sprite.pos.xy;
    gl_Position = ubo.proj * ubo.view * vec4(worldPos, depthZ, 1.0);
    
    outUV = uvs[vIdx];
    outTexIndex = sprite.textureIndex;
    outSamplerIndex = 0;
}
