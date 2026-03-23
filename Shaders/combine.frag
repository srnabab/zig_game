#version 460

layout(location = 0) in vec2 uv; // Texture coordinates from full-screen quad

layout(set = 0, binding = 0) uniform sampler2D sceneColorSampler;
layout(set = 0, binding = 1) uniform sampler2D ssgiResultSampler;
layout(set = 0, binding = 2) uniform sampler2D scene2dColorSampler;
layout(set = 0, binding = 3) uniform sampler2D sceneShadowSampler;
// layout(set = 0, binding = 4) uniform sampler2D scene2dDepthSampler;

layout(location = 0) out vec4 finalColor;

void main() {
    vec4 directLightAndEmissive = texture(sceneColorSampler, uv);
    vec3 indirectLight = texture(ssgiResultSampler, uv).rgb;

    float sceneDepth = texture(sceneShadowSampler, uv).r;
    // float scene2dDepth = texture(scene2dDepthSampler, uv).r;

    directLightAndEmissive *=  sceneDepth;

    vec4 scene2dColor = texture(scene2dColorSampler, uv);
    // vec4 scene2dColor = vec4(0.0);

    // Additive blending: Combine direct and indirect lighting
    vec3 combinedLight = directLightAndEmissive.rgb + indirectLight;

    // Optional: Apply tonemapping, gamma correction etc. here or in a later pass
    // combinedLight = Tonemap(combinedLight);
    // combinedLight = pow(combinedLight, vec3(1.0/2.2)); // Gamma Correction Example

    // finalColor = vec4(combinedLight, 1.0);
    // finalColor = vec4(uv, 0.0, 1.0); // For testing: just output the UV coordinates
    // if (sceneDepth < scene2dDepth) 
    // {
    //     // finalColor = vec4(combinedLight, directLightAndEmissive.a);
    //     finalColor = directLightAndEmissive;
    // }
    // else
    // {
    //     finalColor = scene2dColor;
    // }
    finalColor = directLightAndEmissive * step(abs(scene2dColor.a), 0.0) + scene2dColor * sign(abs(scene2dColor.a)); // For testing: just output the scene color
    // finalColor = directLightAndEmissive + scene2dColor;
    // finalColor = vec4(combinedLight, directLightAndEmissive.a) * step(abs(scene2dColor.a), 0.0) + scene2dColor;
    // finalColor = scene2dColor;
}
