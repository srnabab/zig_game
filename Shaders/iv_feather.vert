#version 460

#extension GL_EXT_shader_explicit_arithmetic_types_int64 : require
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout : require
#extension GL_EXT_shader_8bit_storage : require

struct TaskPayload {
    uint meshletID;
    uint instanceID;
    uint meshID;
};

layout(buffer_reference) readonly buffer TaskPayloads {
    TaskPayload payloads[];
};

struct Vertex {
    vec3 pos;
    vec3 normal;
    vec4 tangent;
    vec2 uv;
    // float padding;
};

struct Meshlet {
    uint vertexOffset;
    uint primitiveOffset;
    uint vertexCount;
    uint primitiveCount;
};

struct GroupMapping {
    uint instanceID;
    uint meshID;
};

struct Instance {
    mat4 matrix;
    uint texIndex;
    uint samplerIndex;
};

struct Mesh {
    uint meshletCount;
    uint meshletOffset;
    uint verticesOffset;
    uint meshletVerticesOffset;
    uint meshletTrianglesOffset;
    uint verticeStride;
};

layout(buffer_reference) readonly buffer MeshletBuffer {
    Meshlet meshlets[]; 
};

layout(buffer_reference, scalar) readonly buffer VertexBuffer {
    Vertex vertices[]; 
};

layout(buffer_reference) readonly buffer MeshletVertices {
    uint meshletVertices[]; 
};

layout(buffer_reference) readonly buffer MeshletIndices {
    uint8_t meshletIndices[]; 
};

layout(buffer_reference) readonly buffer MappingBuffer {
    GroupMapping mappings[];
};

layout(buffer_reference, scalar) readonly buffer InstanceBuffer {
    Instance instances[];
};

layout(buffer_reference) readonly buffer MeshBuffer {
    Mesh meshes[];
};

layout(set = 1, binding = 0) uniform UniformBufferObject {
    mat4 view;
    mat4 proj;
    vec3 cameraPos;

    vec3 lightDirection;
} ubo;

layout(push_constant) uniform PushConstants {
    MeshletBuffer meshletBuffer;
    VertexBuffer vertexBuffer;
    MeshletVertices meshletVertices;
    MeshletIndices meshletIndices;
    InstanceBuffer instances;
    MeshBuffer meshes;
    TaskPayloads payloads;
    uint64_t params;

    uint paramTextureIndex;
} pc;

layout(location = 0) out vec2 uv;
layout(location = 1) flat out uint texIndex;
layout(location = 2) flat out uint samplerIndex;
layout(location = 3) out vec3 view;
layout(location = 4) out vec3 normal;
layout(location = 5) out vec4 tangent;

void main() {
    uint visible_meshlet_idx = gl_VertexIndex / (124 * 3);  
    uint local_tri_idx = (gl_VertexIndex % 372) / 3;
    uint corner_id = gl_VertexIndex % 3;

    TaskPayload payload = pc.payloads.payloads[visible_meshlet_idx];
    
    uint meshlet_id = payload.meshletID;
    uint instanceID = payload.instanceID;
    uint meshID = payload.meshID;
    
    Meshlet m = pc.meshletBuffer.meshlets[meshlet_id];
    
    if (local_tri_idx >= m.primitiveCount) {
        gl_Position = vec4(0.0 / 0.0);
        return;
    }

    uint globalVerticesOffset = pc.meshes.meshes[meshID].verticesOffset;
    uint globalMeshletVerticesOffset = pc.meshes.meshes[meshID].meshletVerticesOffset;
    uint globalMeshletTrianglesOffset = pc.meshes.meshes[meshID].meshletTrianglesOffset;

    uint byte_offset = m.primitiveOffset + (local_tri_idx * 3) + corner_id + globalMeshletTrianglesOffset;
    uint triangleOffset = pc.meshletIndices.meshletIndices[byte_offset];

    uint vertexIdx = pc.meshletVertices.meshletVertices[m.vertexOffset + triangleOffset + globalMeshletVerticesOffset] + globalVerticesOffset;

    mat4 model = pc.instances.instances[instanceID].matrix;
    vec4 pos = vec4(pc.vertexBuffer.vertices[vertexIdx].pos, 1.0);
    // model *

    vec4 f_pos = ubo.proj * ubo.view * pos;
    // vec4 f_pos = vec4(pos, 1.0);

    vec4 tangent = pc.vertexBuffer.vertices[vertexIdx].tangent;

    vec3 v = normalize(ubo.cameraPos - pos.xyz);
    vec3 n = normalize(pc.vertexBuffer.vertices[vertexIdx].normal);
    vec3 t = normalize(tangent.xyz) * tangent.w;
    vec3 b = normalize(cross(t, n));

    view = normalize(mat3(t, b, n) * v);

    gl_Position = f_pos;

    uv = pc.vertexBuffer.vertices[vertexIdx].uv;
    texIndex = pc.instances.instances[instanceID].texIndex;
    samplerIndex = pc.instances.instances[instanceID].samplerIndex;
    normal = pc.vertexBuffer.vertices[vertexIdx].normal;
    tangent = pc.vertexBuffer.vertices[vertexIdx].tangent;
}
