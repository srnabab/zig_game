#version 460

#extension GL_ARB_separate_shader_objects : enable
#extension GL_EXT_buffer_reference : require
#extension GL_EXT_scalar_block_layout : require

struct Vertex {
    vec3 position;
    vec2 uv;
};

layout(buffer_reference, scalar) readonly buffer VertexBuffer {
    Vertex vertices[]; 
};

layout(push_constant) uniform PushConstants {
    VertexBuffer vertexBuffer;
} pc;

layout(set = 0, binding = 0) uniform UniformBufferObject {
    mat4 view;
    mat4 proj;
} ubo;

layout(location = 0) out vec2 fragTexCoord;

void main() 
{
    Vertex v = pc.vertexBuffer.vertices[gl_VertexIndex];
    gl_Position = ubo.proj * ubo.view * vec4(v.position ,1.0);
    fragTexCoord = v.uv;
}
