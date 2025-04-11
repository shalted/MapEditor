#ifndef TOONFUR_INPUT_INCLUDE
#define TOONFUR_INPUT_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
TEXTURE2D(_MaskMap);            SAMPLER(sampler_MaskMap);

TEXTURE2D(_FurFlowMap);            SAMPLER(sampler_FurFlowMap);
TEXTURE2D(_FurNoiseMap);            SAMPLER(sampler_FurNoiseMap);
TEXTURE2D(_FurMaskMap);            SAMPLER(sampler_FurMaskMap);

// TEXTURE2D(_Distortion);            SAMPLER(sampler_Distortion);
TEXTURE2D(_EffectsMaskTex); SAMPLER(sampler_EffectsMaskTex);


CBUFFER_START(UnityPerFrame)
float _FUR_OFFSET;
float _FUR_NUM;
CBUFFER_END


// Uniforms
CBUFFER_START(UnityPerMaterial)

// Base Shetting
float4 _FurNoiseMap_ST;
float4 _BaseMap_ST;
float4 _FurFlowMap_ST;
half4 _BaseColor;
half4 _FurColor;
half4 _FurTipsColor;
half4 _FurAOColor;

half _BumpScale;
half _Cutoff;

// half _FurRadius;
// half _Tining;

//毛发形状
half _UseFurTipsColor;
half _FurTipsColorRange;
half _FurTipsColorRangeSoftness;
float _FurLength;
half _FurDensity;
half _FurContrast;
half _FurAlpha;

half _RootFurRange;
half _FurFlowMapIntensity;
half _CurlyFurRange;

float4 _Gravity;
half _GravityStrength;


// wind
float _Tiling;
float _TilingN3;
float _WindMovement, _WindForce, _LengthByWind;


// 光照设置
half _FurShadowPow;
half4 _FurShadowColor;
half _FurAmbientIntensity;

// // 高光设置
// half4 _FurSpecColor;
// half _FurSpecOffset;
// half _FurSpecShininess;
// half _FurSepcIntensity;
half4 _FurSpecularColor;
half _FurSpecularColorBlender, _FurSmoothness, _FurSpecularBrightness, _FurSpecularBlendLength, _FurSpecularRootAOIntensity, _FurAnisotropySmoothness, _FurAnisotropyBrightness;

// 边缘光设置
half4 _SideLightColor;
half _SideLightScale;
half _SideLightPow;
half _SideLightBlendAlbedo;

//环境光设置
half _SHExposure;

// Mask
half _FURMASK;

//diffuse
half4 _SColor;
half4 _HColor;
half _RampThreshold;
half _RampSmoothing;
half _DiffuseBlendAlbedo;
half _DiffuseBlendAO;

half _AnisotropyDiffuse;

//AO
half _FurAORange;
half _FurAOBlendAlbedo;
half _FurAOIntensity;


//投影设置
half _ShadowIntensity;
float _CustomShadowNormalBias,_CustomShadowDepthBias;


//特效功能
half _FresnelF0;
half4 _FresnelColor;

half4 _DissloveEdgeColor;
half _DissloveEdgeLength;
half _DissloveThreshold;

//Timeline光
half4 _StoryLightDir;

CBUFFER_END



half4 SampleMainTex(float2 uv,TEXTURE2D_PARAM(mainMap, sampler_mainMap))
{
	half4 mainTexCol=0;
	mainTexCol= SAMPLE_TEXTURE2D(mainMap,sampler_mainMap, uv);
	return mainTexCol;
}

struct FurLitBaseData
{
    half3 albedo;
    half4 maskMap;
    half alpha;
	half4 normalTS;
};

half4 SampleTexture(float2 uv,TEXTURE2D_PARAM(map, sampler_map))
{
	half4 mainTexCol=0;
	mainTexCol= SAMPLE_TEXTURE2D(map,sampler_map, uv);
	return mainTexCol;
}

inline half GetChannel(FurLitBaseData outToonLitBaseData, int ChannelId, float defualtvalue = 0)
{
    const half3 CHANNEL[3] =
    {
        {1, 0, 0},
        {0, 1, 0},
        {0, 0, 1}
    };
    int ChannelIndex = round(fmod(ChannelId - 1, 3));
    half3 maskvalue = half3(outToonLitBaseData.alpha,  outToonLitBaseData.normalTS.b,
    					outToonLitBaseData.maskMap.r);
    //half value =step(4,ChannelIndex)>0? dot(outPBRBaseData.maskMap.gba,CHANNEL[round(fmod(ChannelId1,3))+1].xyz): dot(maskvalue,CHANNEL[ChannelIndex].xyz);
    half value = ChannelId >= 1 ? dot(maskvalue, CHANNEL[ChannelIndex].xyz) : defualtvalue;
    value = ChannelId >= 4 ? dot(outToonLitBaseData.maskMap.gba, CHANNEL[ChannelIndex].xyz) : value;
    return value;
}

float3 GetDeformedData_Position(ByteAddressBuffer vBuffer, uint vid)
{
	int vidx = vid * 40;
	float3 data = asfloat(vBuffer.Load3(vidx));
	return data;
}

float3 GetDeformedData_Normal(ByteAddressBuffer vBuffer, uint vid)
{
	int vidx = vid * 40;
	float3 data = asfloat(vBuffer.Load3(vidx + 12)); //offset by float3 (position) in front, so 3*4bytes = 12
	return data;
}

float4 GetDeformedData_Tangent(ByteAddressBuffer vBuffer, uint vid)
{
	int vidx = vid * 40;
	float4 data = asfloat(vBuffer.Load4(vidx + 24)); //offset by float3 (position) + float3 (normal) in front, so 12 + 3*4bytes = 24
	return data;
}

float2 GetStaticData_TexCoord0(ByteAddressBuffer vBuffer, uint vid)
{
	int vidx = vid * 12;
	float2 data = asfloat(vBuffer.Load2(vidx + 4));
	return data;
}

float2 GetStaticData_TexCoord1(ByteAddressBuffer vBuffer, uint vid)
{
	int vidx = vid * 20;
	float2 data = asfloat(vBuffer.Load2(vidx + 12));
	return data;
}

float2 GetStaticData_TexCoord2(ByteAddressBuffer vBuffer, uint vid)
{
	int vidx = vid * 28;
	float2 data = asfloat(vBuffer.Load2(vidx + 20));
	return data;
}

inline void InitializeFragmentData(float2 uv, half furLengthMask, half FUROFFEST, out FurLitBaseData baseData)
{
	
	half4 albedoAlpha   = SampleTexture(uv,TEXTURE2D_ARGS(_BaseMap,sampler_BaseMap));
	// half4 maskMap      = SampleTexture(uv,TEXTURE2D_ARGS(_FurMaskMap,sampler_FurMaskMap));

	#if _NORMALMAP
	half4 tangentNormal = SampleTexture(uv,TEXTURE2D_ARGS(_BumpMap,sampler_BumpMap));
	tangentNormal.xyz = UnpackNormalScale(tangentNormal, _BumpStrength);
	// 如果只是用法线的RG通道计算法线的话，可以使用该方法
	//tangentNormal.xyz = UnpackNormalRG(tangentNormal,_BumpStrength);
	#else
	half4 tangentNormal = half4(0.0h, 0.0h, 1.0h, 1.0h);
	#endif

	baseData.albedo = lerp(albedoAlpha.rgb * lerp(_FurTipsColor.rgb, _FurColor.rgb, furLengthMask), albedoAlpha.rgb * _FurTipsColor.rgb, smoothstep(_FurTipsColorRange, _FurTipsColorRange + _FurTipsColorRangeSoftness, FUROFFEST) * _UseFurTipsColor);
	baseData.alpha = albedoAlpha.a * _FurColor.a;
	baseData.maskMap = 1.0h;//maskMap;
	baseData.normalTS = tangentNormal;
}

#endif
