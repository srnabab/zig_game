struct PSInput {
    float2 fragTexCoord : TEXCOORD0;
    // 使用 nointerpolation 对应 GLSL 的 flat 关键字
    nointerpolation uint fragTexIndex : TEXINDEX;
};

// 在 HLSL 中，纹理和采样器通常是分开定义的
// 如果是针对 Vulkan (使用 DXC 编译)，可以使用 [[vk::binding(binding, set)]]
[[vk::binding(0, 1)]] 
Texture2D textures[]; 

[[vk::binding(1, 1)]] 
SamplerState texSampler; 

// 入口函数
float4 main(PSInput input) : SV_Target {
    // 使用 NonUniformResourceIndex 对应 GLSL 的 nonuniformEXT
    // 这是为了告诉硬件索引在不同 Pixel 之间可能不同（用于绕过一致性检查）
    uint index = NonUniformResourceIndex(input.fragTexIndex);
    
    // 执行采样操作
    float4 texColor = textures[index].Sample(texSampler, input.fragTexCoord);

    return texColor;
}
