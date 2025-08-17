#version 460

layout(set = 0, binding = 1) uniform sampler2D texSampler;
layout(set = 0, binding = 2) uniform sampler2DShadow shadowSampler;

layout(set = 0, binding = 3) uniform directionLight
{
    mat4 lightSapceMatrix;
    vec3 lightDirection;
    vec3 lightColor;
    float lightIntensity;
} sun;

layout(location = 0) in vec3 fragColor;
layout(location = 1) in vec2 fragTexCoord;
layout(location = 2) in vec3 inWorldPos;
layout(location = 3) in vec3 inWorldNormal;
// layout(location = 4) flat in int instanceIndex;

layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormalBuffer;
layout(location = 2) out float outShadowFactor;

float shadowFactor(vec3 N, float NdotL)
{
    float shadowBias = 0.005;
    int pcfSamples = 9;
    float pcfRadius = 1.5;

    vec3 offsetWorldPos = inWorldPos + N * 0.0035;

    vec4 fragPosLightSpace = sun.lightSapceMatrix * vec4(offsetWorldPos, 1.0);
    vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    vec2 shadowCoord = projCoords.xy * 0.5 + 0.5;
    // shadowCoord.y = 1.0 - shadowCoord.y;
    float currentDepth = projCoords.z;

    float bias = max(0.05 * (1.0 - NdotL), shadowBias);

    vec2 texelSize = 1.0 / textureSize(shadowSampler, 0);
    // 2. 获取纹理像素大小，用于计算偏移

    // 3. 循环采样周围区域
    float shadow = 0.0;
    for (int x = -1; x <= 1; ++x) 
    {
        for (int y = -1; y <= 1; ++y) 
        {
            // 计算采样点的 UV 坐标
            vec2 offset = vec2(x, y) * texelSize * pcfRadius;
            vec2 sampleUV = shadowCoord + offset;

            // 检查UV是否越界 (可选但推荐)
            if (sampleUV.x >= 0.0 && sampleUV.x <= 1.0 && sampleUV.y >= 0.0 && sampleUV.y <= 1.0) 
            {
                // 4. 读取阴影图深度
                float shadowMapDepth = texture(shadowSampler, vec3(sampleUV, currentDepth));

                // 5. 进行深度比较
                if (currentDepth <= shadowMapDepth + bias) 
                {
                    shadow += 1.0;
                }
            } 
            else 
            {
                // 处理边界外情况，可以认为不在阴影内
                shadow += 1.0;
            }
        }
    }

    // 6. 计算百分比
    shadow /= float(pcfSamples);

    float minShadowIntensity = 0.1;
    shadow = mix(minShadowIntensity, 1.0, shadow);

    return shadow;
}
void main() 
{
    vec3 L = normalize(-sun.lightDirection);

    vec3 N = normalize(inWorldNormal.rgb);
    float NdotL = max(dot(N, L), 0.0);

    float shadow = shadowFactor(N, NdotL);

    // vec3 albedoColor = fragColor;
    vec4 textureColor;
    textureColor = texture(texSampler, fragTexCoord);


    vec3 diffuse = textureColor.rgb * sun.lightColor;// * sun.lightIntensity * NdotL;

    // vec3 V = normalize(viewDir);
    // vec3 H = normalize(L + V); // 半程向量
    // float NdotH = max(dot(N, H), 0.0);
    // float specFactor = pow(NdotH, shininess); // shininess 是材质光泽度
    // vec3 specular = specularColor * sun.lightColor * sun.lightIntensity * specFactor;

    // vec3 finalColor = shadow * (diffuse); // + specular;
    vec3 finalColor = (diffuse); // + specular;
    
    outNormalBuffer = vec4(inWorldNormal, 1.0);

    outShadowFactor = shadow * NdotL * sun.lightIntensity;

    outColor = vec4(finalColor * abs(step(1.0, textureColor.rgb) - 1.0), textureColor.a);
    // outColor = textureColor;
    // outColor = vec4(fragPosLightSpace);
    // outColor = vec4(projCoords, 1.0);
    // outColor = vec4(shadowMapMinDepth);
    // outColor = vec4(vec3(bias), 1.0);
    // outColor = vec4(vec3(inWorldPos), 1.0);
    // outColor = vec4(vec3(currentDepth), 1.0);
    // outColor = vec4(textureColor.rgb * sun.lightIntensity, 1.0);
    // outColor = vec4(vec3(NdotL), 1.0);// debug
    // outColor = vec4(L * 0.5 + 0.5, 1.0);// debug
}