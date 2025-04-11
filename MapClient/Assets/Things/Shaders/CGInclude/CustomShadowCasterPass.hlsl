#ifndef UNIVERSAL_SHIYUE_SHADOW_CASTER_PASS_INCLUDED
#define UNIVERSAL_SHIYUE_SHADOW_CASTER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

float3 _LightDirection;

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float2 texcoord     : TEXCOORD0;
    float3 color        : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv           : TEXCOORD0;
    float4 positionCS   : SV_POSITION;
};

float4 GetShadowPositionHClip(Attributes input)
{
    //风效
    #if defined (_WIND_ON)
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    float2 WindUV =  (_Time.yy + vertexInput.positionWS.xz) * _WindSpeed/25;
    input.positionOS.xyz += SAMPLE_TEXTURE2D_LOD(_NoiseMap, sampler_NoiseMap, WindUV,0)  * _WindStrength * input.color.g;
    #endif

    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif

    return positionCS;
}

Varyings ShadowPassVertex(Attributes input)
{
    Varyings output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.positionCS = GetShadowPositionHClip(input);
    return output;
}

half4 ShadowPassFragment(Varyings input) : SV_TARGET
{
    half alpha =SampleMainTex(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a * _Color.a;
    #if defined(_ALPHATEST_ON)
    clip(alpha - _Cutoff);
    #endif
    return 0;
}

#endif
