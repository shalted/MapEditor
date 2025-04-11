#ifndef _CHARACTERS_ADDITIONALLIGHTINGDATA_HLSL_
#define _CHARACTERS_ADDITIONALLIGHTINGDATA_HLSL_

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

CBUFFER_START(CHARACTER_LIGHTING_DATA)
half4 _CharacterLightDir;
half4 _CharacterLightColor;
half4 _CharacterLightData;
half4 _CharacterAmbientColor;
half4 _CharacterBakeAmbientColor;
half4 _CharacterEnvColor;
half4 _CharacterSpecularColor;
half4 _CharacterMultipleLight; //角色灯光脚本
CBUFFER_END


inline  void GetCharacterLightingData(Light light)
{
    if (_CharacterLightData.x > 0.0h)
    {
        light.direction = _CharacterLightDir;
        light.color = _CharacterLightColor;
    }
    // light.distanceAttenuation = _CharacterLightData.x;
    // light.shadowAttenuation = _CharacterLightData.y;
    // light.shadowAttenuation = _CharacterLightData.z;
    // light.shadowAttenuation = _CharacterLightData.w;
}

inline void CharacterLightControllerData(inout Light mainLight, inout InputLitData inputData, inout BRDFBaseData brdfBaseData)
{
    //场景灯光脚本
    if (_CharacterLightData.x > 0.0h)
    {
        // lighColorData.lightColor = _MainLightColor.rgb;
        mainLight.direction = _CharacterLightDir.xyz;
        mainLight.color = _CharacterLightColor.rgb * _CharacterLightData.w;
        mainLight.shadowAttenuation = LerpWhiteTo( mainLight.shadowAttenuation, _CharacterLightData.y);

        brdfBaseData.specColor *= _CharacterSpecularColor.rgb * _CharacterSpecularColor.a * 10;

        inputData.bakedGI = lerp(inputData.bakedGI, _CharacterBakeAmbientColor.rgb,
                                     _CharacterBakeAmbientColor.a);
        inputData.bakedGI *= _CharacterLightData.z;
        inputData.bakedGI += _CharacterAmbientColor.rgb * _CharacterAmbientColor.a;

        // lighColorData.multipleLightBrightness = _CharacterMultipleLight.x;
        // lighColorData.multipleLightRange = _CharacterMultipleLight.y;
        // lighColorData.multipleLightSoftness = _CharacterMultipleLight.z;
    }
}

Light GetCharacterMainLight()
{
    Light mainLight = GetMainLight();
    GetCharacterLightingData(mainLight);
    return mainLight;
}

Light GetCharacterMainLight(float4 shadowCoord, float3 positionWS, float shadowMask, AmbientOcclusionFactor aoFactor)
{
    Light mainLight = GetMainLight(shadowCoord, positionWS, shadowMask);
    GetCharacterLightingData(mainLight);
    
    #if defined(_SCREEN_SPACE_OCCLUSION) && !defined(_SURFACE_TYPE_TRANSPARENT)
    if (IsLightingFeatureEnabled(DEBUGLIGHTINGFEATUREFLAGS_AMBIENT_OCCLUSION))
    {
        mainLight.color *= aoFactor.directAmbientOcclusion;
    }
    #endif
    return mainLight;
}

// inline void GetHitRimColor_Scene(TextureData textureData,CharactersHitRimLightData hitRimLightData, LightVectorData lightVectorData, LightColorData lighColorData,
//                                  inout half3 finalColor)
// {
//     //特效边缘光计算
//     half hitrim = pow(1 - lightVectorData.NdotV, hitRimLightData.hitRimPower);
//     half hitrimvalue = LinearStep(hitRimLightData.hitRimThreshold, hitRimLightData.hitRimThreshold + hitRimLightData.hitRimSmooth, hitrim);
//     half3 hitrimcolor = hitRimLightData.hitRimColor.rgb * hitrimvalue * hitRimLightData.hitRimFactor;
//
//     finalColor += hitrimcolor;
// }

#endif