#ifndef INSERTINGPATCHESFUR_INPUT_INCLUDE
#define INSERTINGPATCHESFUR_INPUT_INCLUDE

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#define unity_LinearColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)

TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
TEXTURE2D(_MaskMap);            SAMPLER(sampler_MaskMap);
TEXTURE2D(_NPRLightMap);        SAMPLER(sampler_NPRLightMap);
TEXTURE2D(_MatCapMap);			SAMPLER(sampler_MatCapMap);
TEXTURE2D(_RampMap);        SAMPLER(sampler_RampMap);
TEXTURECUBE(_EvnCubemap);  SAMPLER(sampler_EvnCubemap);

// Uniforms
CBUFFER_START(UnityPerMaterial)
half _DitherTimer;
//========float4类型========
//基础设置
float4 _BaseMap_ST;
float4 _MaskMap_TexelSize;


//========half4类型========
//基础设置
half4 _BaseColor;
half4 _StoryLightDir, _ProceduralColor;

//阴影设置
half4 _HColor;
half4 _SColor;

//高光设置
half4 _SpecularColor;
half4 _SpecularAnisotropyColor;

//环境光设置
half4 _CubemapColor;
float4 _Custom_SpecCube_HDR;

//边缘光设置
float4 _RimDir;
float4 _RimColor;

//自发光设置
float4 _EmissionMap_ST;
half4 _EmissionColor;

//Matcap设置
half4 _MatCapColor;
half4 _MatCapMap_ST;

// Outline
half4 _OutlineColor;

//ShadowCaster
float3 _LightDirection;

//========float类型========
//投影设置
float _CustomShadowDepthBias;
float _CustomShadowNormalBias;
float _CustomShadowBias;


//========half类型========
//基础设置
half _Cutoff;

//PBR参数设置
half _BumpStrength;
half _MetallicScale;
half _MetallicBias;
half _SmoothnessBias;
half _SmoothnessScales;
half _AOIntensity;

//阴影设置
half _UseHalfLambert;
half _RampYOffset;
half _RampThreshold;
half _RampSmoothing;

//高光设置
half _SpecularColorBlender;
half _SpecularIntensity;
half _MetaIntensity;
half _SpecularAnisotropyIntensity;
half _Anisotropy;
half _SpecularAnisotropyClamp;

//环境光设置
half _SHExposure;
half _EnvRotate;
half _IndirectIntensity;

float _Use_Custom_SpecCube_HDR;

//边缘光设置
float _RimDirContribution;
half _RimColorBlendMode;
half _RimMaskUseShadow;
float _RimThreshold;
float _RimSmooth;
float _LightDirOffset;
half _RimCustom;
half _RimWidth;

//Matcap设置
half _MatcapIntensity;

//自发光设置
half _Emission_Instensity;

//投影设置
half _ShadowIntensity;
CBUFFER_END

// Outline
half _Outline_Width;
half _Offset_Z;

struct InputLitData
{
    float3  positionWS;
    float4  positionCS;
    float3  normalWS;
    half3   viewDirectionWS;
    float4  shadowCoord;
    half    fogCoord;
    half3   vertexLighting;
    half3   bakedGI;
    float2  normalizedScreenSpaceUV;
    half4   shadowMask;
    half3x3 tangentToWorld;
};

struct InputDotData
{
    half NdotL;
    half NdotLClamp;
    half HalfLambert;
    half NdotV;
    half NdotH;
    half LdotH;
    half atten;
    half3 HalfDir;
};

struct SurfaceLitData
{
    half4 albedoAlpha;
    half4 maskMap;
    half4 nprLightMap;

    //albedoAlpha
    half3 albedo;
    half alpha;

    //maskMap
    half3 normalTS;
    half3 emission;
    half AO;

    //nprLightMap
    half metallic;
    half smoothness;
    half rampID;
    half MaskAlpha;
};

struct LightingLitData
{
    half3 giColor;
    half3 mainLightColor;
    half3 additionalLightsColor;
    half3 vertexLightingColor;
    half3 emissionColor;
};

struct BRDFBaseData
{
    half3 diffuse;
    half3 specColor;
    half  grazingTerm;
    half  perceptualRoughness;
    half  roughness;
    half  roughness2;

    // We save some light invariant BRDF terms so we don't have to recompute
    // them in the light loop. Take a look at DirectBRDF function for detailed explaination.
    half normalizationTerm;     // roughness * 4.0 + 2.0
    half roughness2MinusOne;    // roughness^2 - 1.0
};

half4 SampleMainTex(float2 uv,TEXTURE2D_PARAM(mainMap, sampler_mainMap))
{
    half4 mainTexCol=0;
    mainTexCol= SAMPLE_TEXTURE2D(mainMap,sampler_mainMap, uv);
    return mainTexCol;
}

half LinearStep(half minValue, half maxValue, half In)
{
    return saturate((In-minValue) / (maxValue - minValue));
}

inline half LinearOneMinusReflectivityFromMetallic(half metallic)
{
    half oneMinusDielectricSpec = unity_LinearColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

half3 MergeTexUnpackNormalRG(half4 packedNormal, half scale = 1.0)
{
    // real3 normal;
    // normal.xy = packedNormal.rg * 2.0 - 1.0;
    // normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
    // normal.xy *= scale;
    // return normal;
    real3 normal;
    normal.xy = packedNormal.rg * 2.0 - 1.0;
    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
    normal.xy *= scale;
    return normal;
}

float GetOutLineScale(float z, float nPower = 1.05, float fPower = 0.2)
{
    return pow(z, z < 1 ?nPower: fPower) * lerp(1, UNITY_MATRIX_P._m00, IsPerspectiveProjection() ? 0.60: 1.0);
}


float3 TransformObjectToView(float3 positionOS)
{
    return  mul(GetWorldToViewMatrix(),float4(mul(GetObjectToWorldMatrix(), float4(positionOS, 1.0)).xyz,1.0)).xyz;
}

void DitherThresholdScreenCoord(float2 screenCoord, half ditherTimer)
{
    float DITHER_THRESHOLDS[16] =
     {
        1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
        13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
        4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
        16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
    };
	
    uint index = (uint(screenCoord.x) % 4) * 4 + uint(screenCoord.y) % 4;
    float ditherValue = DITHER_THRESHOLDS[index];
    clip(1 - ditherTimer - ditherValue);
}

void DitherThreshold(float4 scrPos,float2 positionCS,half ditherTimer)
{
    float2 screenUV = (scrPos.xy) / scrPos.ww;
    screenUV *= _ScreenSize.xy;// _ScreenParams.xy;
    
    DitherThresholdScreenCoord(screenUV, ditherTimer);
}


#endif
