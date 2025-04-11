#ifndef UNIVERSAL_SHIYUE_CUSTOMG_INCLUDED
#define UNIVERSAL_SHIYUE_CUSTOMGI_INCLUDED

float3 ShouwangSampleSH9(float4 SHCoefficients[7], float3 N)
{
    float4 shAr = SHCoefficients[0];
    float4 shAg = SHCoefficients[1];
    float4 shAb = SHCoefficients[2];
    float4 shBr = SHCoefficients[3];
    float4 shBg = SHCoefficients[4];
    float4 shBb = SHCoefficients[5];
    float4 shCr = SHCoefficients[6];

    // Linear + constant polynomial terms
    float3 res = SHEvalLinearL0L1(N, shAr, shAg, shAb);

    // Quadratic polynomials
    res += SHEvalLinearL2(N, shBr, shBg, shBb, shCr);

    // 不知道为啥跑了这里
    // #ifdef UNITY_COLORSPACE_GAMMA
    // res = LinearToSRGB(res);
    // #endif

    return res;
}

// Samples SH L0, L1 and L2 terms
half3 ShouWangSampleSH(half3 normalWS)
{
    // LPPV is not supported in Ligthweight Pipeline
    float4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;

    return max(half3(0, 0, 0), ShouwangSampleSH9(SHCoefficients, normalWS));
}

//额外数据入口
struct AdditionalData {
    half3 positionWS;
    // 盒装投影用参数
    // #ifdef _CUSTOM_BOXPROJECTION
    half4 boxCenter;
    half4 boxMax;
    half4 boxMin;
    half boxRouness;
    half strength;
    // #endif
    #if _CUSTOM_ENV_CUBE
    half use_Custom_HDR;
    half4 custom_SpecCube_HDR;
    #endif
    half horizonFade;
    half3 normalWS;
};

// #ifdef _CUSTOM_BOXPROJECTION 
// AdditionalData InitBoxData(half4 boxCenter,half4 boxSize,half boxRouness,half  strength, AdditionalData data){
// 	data.boxCenter = boxCenter;
// 	data.boxMax  = boxCenter + boxSize*0.5;
// 	data.boxMin  = boxCenter - boxSize*0.5;
// 	data.boxRouness = abs(boxRouness-1);
// 	data.strength = (strength);
// //	data.positionWS = data.positionWS;
// 	return data;
// }
// #endif

void InitBoxData(half4 boxCenter,half4 boxSize,half boxRouness,half  strength,inout AdditionalData data)
{
    #ifdef _CUSTOM_BOXPROJECTION
    data.boxCenter = boxCenter;
    data.boxMax  = boxCenter + boxSize*0.5;
    data.boxMin  = boxCenter - boxSize*0.5;
    data.boxRouness = abs(boxRouness-1);
    data.strength = (strength);
    #endif
}

void InitHDRData(half use_Custom_HDR,half4 Custom_SpecCube_HDR,inout AdditionalData data)
{
    #if _CUSTOM_ENV_CUBE
    data.use_Custom_HDR = use_Custom_HDR;
    data.custom_SpecCube_HDR = Custom_SpecCube_HDR;
    #endif
}

float3 RotateAround(float3 target, float degree)
{
    float rad = degree * 0.01745f;
    float2x2 m_rotate = float2x2(cos(rad), -sin(rad),
        sin(rad), cos(rad));
    float2 dir_rotate = mul(m_rotate, target.xz);
    target = float3(dir_rotate.x, target.y, dir_rotate.y);
    return target;
}

half EnvHorizonOcclusion(half3 reflectVector, half3 normalWS, half3 vertexNormal, half horizonFade)
{
    half specularOcclusion = saturate(1.0 + horizonFade * dot(reflectVector, vertexNormal));
    // smooth it
    return specularOcclusion * specularOcclusion;
}

#endif
