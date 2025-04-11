// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef UNITY_STANDARD_INPUT_INCLUDED
#define UNITY_STANDARD_INPUT_INCLUDED

#include "UnityCG.cginc"
#include "UnityStandardConfig.cginc"
#include "UnityPBSLighting.cginc" // TBD: remove
#include "UnityStandardUtils.cginc"

//---------------------------------------
// Directional lightmaps & Parallax require tangent space too
#if (_NORMALMAP || USE_DETAIL_LERP)
    #define _TANGENT_TO_WORLD 1
#endif

#if (_DETAIL_MULX2 || _DETAIL_MUL || _DETAIL_ADD || _DETAIL_LERP)
    #define _DETAIL 1
#endif

//---------------------------------------
UNITY_DECLARE_TEX2D_NOSAMPLER(_MaskTex);
UNITY_DECLARE_TEX2D_NOSAMPLER(_NormalMap);
// UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionTex);
DEFINE_COMBINE_DC_PROP(half, _SmoothnessScale);
DEFINE_COMBINE_DC_PROP(half, _MetallicScale);
DEFINE_COMBINE_DC_PROP(half, _AmbientOcclusionStrength);
DEFINE_COMBINE_DC_PROP(half, _NormalScale);
// DEFINE_COMBINE_DC_PROP(half, _EmissionStrength);
UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissionTex);
DEFINE_COMBINE_DC_PROP(half, _EmissionStrength);
DEFINE_COMBINE_DC_PROP(half4, _EmissionColor);
DEFINE_COMBINE_DC_PROP(half4, _RIMColor);
DEFINE_COMBINE_DC_PROP(half, _RimPow);
DEFINE_COMBINE_DC_PROP(half, _RimDistance);



#ifdef USE_DETAIL_LERP
    sampler2D _DetailTex;
    sampler2D _DetailNormalMap;
    float4 _DetailTex_ST;
    half _DetailSmoothnessScale;
    half _DetailNormalMapScale;
#endif
half4 _AmbientColor;
//-------------------------------------------------------------------------------------
// Input functions

struct VertexInput
{
    float4 vertex   : POSITION;
    half3 normal    : NORMAL;
    half4 color     : COLOR;
    float2 uv0      : TEXCOORD0;
    float2 uv1      : TEXCOORD1;
#if defined(USE_COMBINE_DRAW_CALL) || defined(UNITY_PASS_META)
    float2 uv2      : TEXCOORD2;
#endif
#ifdef _TANGENT_TO_WORLD
    half4 tangent   : TANGENT;
#endif
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

float4 TexCoords(VertexInput v)
{
    float4 texcoord;
    texcoord.xy = TRANSFORM_TEX(v.uv0, _MainTex); // Always source from uv0
    //texcoord.zw = TRANSFORM_TEX(((_UVSec == 0) ? v.uv0 : v.uv1), _DetailAlbedoMap);
#ifdef USE_DETAIL_LERP
    texcoord.zw = TRANSFORM_TEX(v.uv0, _DetailTex);
#else
    texcoord.zw = 0;
#endif
    return texcoord;
}

half DetailMask(float2 uv)
{
    return 1;
}

half3 Albedo(float4 texcoords)
{
    return 1;
}

half Alpha(float2 uv)
{
    return 1;
}

half Occlusion(float2 uv)
{
    return 1;
}

half4 SpecularGloss(float2 uv)
{
    return 1;
}

half2 MetallicGloss(float2 uv)
{
    return 1;
}

half2 MetallicRough(float2 uv)
{
    return 1;
}

half3 Emission(float2 uv)
{
    return 1;
}

float4 Parallax (float4 texcoords, half3 viewDir)
{
    return 1;
}

half4 GetMaskTex(float2 uv)
{
    half4 maskTex = UNITY_SAMPLE_TEX2D_SAMPLER(_MaskTex, _MainTex, uv);
    return maskTex;
}
half3 GetNormalTS(float2 uv)
{
    half4 normalTex = UNITY_SAMPLE_TEX2D_SAMPLER(_NormalMap, _MainTex, uv);
    half3 normal;
    normal.xy = (normalTex.xy * 2 - 1);
	normal.xy *= ACCESS_COMBINE_DC_PROP(_NormalScale);
    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
	return normal;
}
//用get emission internal
half3 GetEmission(float2 uv)
{
    half4 emissionTex = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionTex, _MainTex, uv);
	half emissionStrength = ACCESS_COMBINE_DC_PROP(_EmissionStrength);
	return emissionTex.rgb * emissionStrength;
}

half3 GetBloom(float2 uv,half dotVN, half3 albedo)
{
    half3 bloomBaseColor = 1;
    half3 emissionColor = 1;
    half3 rimColor = 1;
    #if defined(_BLOOMCLASS_OFF)
        return 0;
    #elif defined(_BLOOMCLASS_COLOR)
        bloomBaseColor = 1;
        emissionColor = ACCESS_COMBINE_DC_PROP(_EmissionColor);
        rimColor = ACCESS_COMBINE_DC_PROP(_RIMColor);
    #elif defined(_BLOOMCLASS_TEXTURE)
        bloomBaseColor = albedo;
        emissionColor = ACCESS_COMBINE_DC_PROP(_EmissionColor);
        emissionColor = max(emissionColor.r,max(emissionColor.g,emissionColor.b));
        rimColor = ACCESS_COMBINE_DC_PROP(_RIMColor);
        rimColor = max(rimColor.r,max(rimColor.g,rimColor.b));
    #else
        return 0;
    #endif
    half4 bloomTex = UNITY_SAMPLE_TEX2D_SAMPLER(_EmissionTex, _MainTex, uv);
    
    //边缘光
    half rimPow = ACCESS_COMBINE_DC_PROP(_RimPow);
    half rimDistance = ACCESS_COMBINE_DC_PROP(_RimDistance);
    half3 rim = max(pow(max(0.00001, 1 - dotVN- rimDistance), rimPow), 0.00001) * rimColor;

    return bloomBaseColor * (emissionColor * bloomTex.r + rim * bloomTex.g);
}

#endif // UNITY_STANDARD_INPUT_INCLUDED
