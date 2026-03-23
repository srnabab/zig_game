#version 460

layout(location = 0) in vec2 uv; // Texture coordinates from full-screen quad

layout(location = 0) out vec4 finalColor;

layout(set = 0, binding = 0) uniform sampler2D sceneColorSampler;

void main(){
    finalColor = texture(sceneColorSampler, uv);
}
