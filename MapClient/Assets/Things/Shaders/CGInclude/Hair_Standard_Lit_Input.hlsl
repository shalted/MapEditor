#ifndef UNIVERSAL_HAIR_INPUT_INCLUDED
#define UNIVERSAL_HAIR_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//#include "../../ShaderLibrary/CustomLightingLib.hlsl"
//#include "../../ShaderLibrary/Toon_Lit_Surface.hlsl"

TEXTURE2D(_BaseMap);            SAMPLER(sampler_BaseMap);
TEXTURE2D(_LightMap);           SAMPLER(sampler_LightMap);
TEXTURE2D(_ShadowMap);          SAMPLER(sampler_ShadowMap);
TEXTURECUBE(_EvnCubemap);  SAMPLER(sampler_EvnCubemap);

TEXTURE2D(_EmissionMap);            SAMPLER(sampler_EmissionMap);

TEXTURE2D(_BumpMap);            SAMPLER(sampler_BumpMap);
TEXTURE2D(_RampUV_Y_ID_Map);            SAMPLER(sampler_RampUV_Y_ID_Map);
TEXTURE2D(_DetailNormalMap);            SAMPLER(sampler_DetailNormalMap);

//TEXTURE2D(_RandomWidthNoiseTex);        SAMPLER(sampler_RandomWidthNoiseTex); 暂时注释随机描边宽度贴图

CBUFFER_START(UnityPerMaterial)
half4      _BaseMap_ST;
half4      _Color,_ProceduralColor;
half        _Cutoff;

//Ramp 
half       _RampYOffset;
half _RampSmoothing;
half _RampThreshold;
half4 _HColor;
half4 _SColor;

half       _BumpStrength;
half4      _DetailNormalMap_ST;
half       _DetailNormalStrength;
float _Use_Custom_SpecCube_HDR;

//MASK
half        _METAL;
half        _GLOSS;
half        _AO;
half _SPECFIXMASK;
half _SPECMASK;

//PBR Setting
half        _MetallicScale;
half        _MetallicBias;
half        _SmoothnessScale;
half        _SmoothnessBias;
half        _OcclusionStrength;

// GGX
half _PBRSpecIntensity;
half4 _PBRSpecColor;


//Toon KK Specular
half        _Specularhreshold;
half        _SpecularSmooth;
half        _SpecularInstensity;
half4       _SpecToonKKColor;
half        _SpecYOffset;
half        _UseViewDir; // 是否让观察方向参与shift计算

// Gen Specular
half _SpecLength;
half _SpecWidth;
half4 _SpecBright;
half _SpecThreshold;
half _specInShadow;
half4 _SpecLight;
half _LightFeather;

// KK Specular
// half        _HairSpecularJitter;
// half        _HairSpecularJitter1;
half4       _HairSpecularCol;
half        _HairSpecularShift;
half        _HairSpecularStrength;
half        _HairSpecularExponent;
half4       _HairSecondarySpecularCol;
half        _HairSecondarySpecularShift;
half        _HairSecondarySpecularStrength;
half        _HairSecondarySpecularExponent;
half        _HairSpread1;
half        _HairSpread2;
// half        _HairSpecularShiftUP;
// half        _HairSpecularShiftSide;

//RimInfo 
half4      _RimDir;
half       _RimDirContribution;
half4      _RimColor;
half       _RimThreshold;
half       _RimSmooth;

//Emission
half        _EmissionID;
half        _Emission_Lerp;
half3       _EmissionColor;
half        _Emission_Instensity;

//CubeMap
half4      _BoxMin;
half4      _BoxMax;
half4      _BoxCenter;
half       _BoxSmoothness;
half       _SHExposure;
half       _EnvExposure;
half4      _CubemapColor;
float4 _Custom_SpecCube_HDR;
half _EnvDiffuseIntensity;
half _EnvRotate;
half _IndirectIntensity;

// Outline
half4 _OutlineColor;
half _Outline_Width;
half _Offset_Z;
half _UseColorOrMap;
half _CloseFarSameDegree;
half _RandomWidthAmplify;
half _PartColorDegree;
half _RandomWidthMinRatio;
half _RandomWidthMaxRatio;
half4 _OutlineTex_ST;
half4 _RandomWidthNoiseTex_ST;

//shadow
half _ShadowThreshold;
half4 _ShadowColor;
half _InlineThreshold;
half4 _InlineColor;
half _SpecularShiness;
CBUFFER_END

// Hair
struct HairSurfaceData
{
    half3 albedo;
    half4 normalTS;
    half4 lightMap;
    half specMask;
    half3 emission;
    half AO;
    #if _PBR
    half metallic;
    half smoothness;
    #endif
    half  alpha;
};

struct HairSpecularData
{
	// half        Jitter;
    // half        Jitter1;
    half3       SpecularCol;
    half        SpecularShift;
    half        SpecularStrength;
    half        SpecularExponent;
    half3       SecondarySpecularCol;
    half        SecondarySpecularShift;
    half        SecondarySpecularStrength;
    half        SecondarySpecularExponent;
    half        Spread1;
    half        Spread2;
    // half        ShiftUP;
    // half        ShiftSide;
};

struct InputDotData
{
    half NdotL;
    half NdotLClamp;
    half HalfLambert;
    half HalfLambertAtten;
    half NdotV;
    half NdotH;
    half LdotH;
    half atten;
    half3 HalfDir;
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

struct InputLitData
{
    float3  positionWS;
    float3  normalWS;
    half3   viewDirectionWS;
    float4  shadowCoord;
    half    fogCoord;
    half3   bakedGI;
};
half LinearStep(half minValue, half maxValue, half In)

{

    return saturate((In - minValue) / max(maxValue - minValue, 1e-3));

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
#define unity_LinearColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)

inline half LinearOneMinusReflectivityFromMetallic(half metallic)
{
    half oneMinusDielectricSpec = unity_LinearColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

half4 SampleMainTex(half2 uv,TEXTURE2D_PARAM(mainMap, sampler_mainMap))
{
    half4 mainTexCol=0;
    mainTexCol= SAMPLE_TEXTURE2D(mainMap,sampler_mainMap, uv);
    return mainTexCol;
}

half4 SampleTexture(half2 uv,TEXTURE2D_PARAM(map, sampler_map))
{
    half4 mainTexCol=0;
    mainTexCol= SAMPLE_TEXTURE2D(map,sampler_map, uv);
    return mainTexCol;
}

inline half GetChannel(HairSurfaceData outNprStandardBaseData,int ChannelId)
{
    const half3 CHANNEL[3] =
    {
    {1,0,0},
    {0,1,0},
    {0,0,1}
    };
    int ChannelIndex =round(fmod(ChannelId - 1,3));
    half3 maskvalue=half3(outNprStandardBaseData.alpha,outNprStandardBaseData.normalTS.b,outNprStandardBaseData.lightMap.r);
    //half value =step(4,ChannelIndex)>0? dot(outPBRBaseData.lightMap.gba,CHANNEL[round(fmod(ChannelId1,3))+1].xyz): dot(maskvalue,CHANNEL[ChannelIndex].xyz);
    half value = ChannelId >= 1 ? dot(maskvalue,CHANNEL[ChannelIndex].xyz): 0;
    value = ChannelId >= 4 ? dot(outNprStandardBaseData.lightMap.gba,CHANNEL[ChannelIndex].xyz): value;
    return value;
}

inline half GetMetallic(HairSurfaceData outNprStandardBaseData,int metallicId)
{
    half metallic = GetChannel(outNprStandardBaseData,metallicId);
    metallic = saturate(metallic * _MetallicScale + _MetallicBias);
    return metallic;
}

inline half GetSmoothness(HairSurfaceData outNprStandardBaseData,int smoothnessId)
{
    half smoothness = GetChannel(outNprStandardBaseData,smoothnessId);
    smoothness = saturate(smoothness * _SmoothnessScale + _SmoothnessBias);
    return smoothness;
}

inline half GetOcclusion(HairSurfaceData outNprStandardBaseData,int aoId)
{
    half occlusion = GetChannel(outNprStandardBaseData, aoId);
    occlusion = LerpWhiteTo(occlusion,_OcclusionStrength);
    return occlusion;
}

// Blinn phong 工作流的BRDF
inline void InitializeBlinnPhongBRDFData(HairSurfaceData surfData, inout BRDFBaseData brdfData)
{
    brdfData = (BRDFBaseData)0;
    brdfData.diffuse = surfData.albedo;
    brdfData.specColor = 1;
}

inline void InitializeHairBRDFBaseData(half3 albedo, half metallic, half3 specular, half smoothness, half alpha, out BRDFBaseData outBRDFBaseData)
{

    half oneMinusReflectivity = LinearOneMinusReflectivityFromMetallic(metallic);
    half reflectivity = 1.0 - oneMinusReflectivity;

    outBRDFBaseData.diffuse = albedo * oneMinusReflectivity;
    outBRDFBaseData.specColor = lerp(unity_LinearColorSpaceDielectricSpec.rgb, albedo, metallic);

    outBRDFBaseData.grazingTerm = saturate(smoothness + reflectivity);
    outBRDFBaseData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
    outBRDFBaseData.roughness = max(PerceptualRoughnessToRoughness(outBRDFBaseData.perceptualRoughness), HALF_MIN_SQRT);
    outBRDFBaseData.roughness2 = outBRDFBaseData.roughness * outBRDFBaseData.roughness;

    outBRDFBaseData.normalizationTerm = outBRDFBaseData.roughness * 4.0h + 2.0h;
    outBRDFBaseData.roughness2MinusOne = outBRDFBaseData.roughness2 - 1.0h;
}

void InitalizeHairBRDFData(HairSurfaceData surfData, inout BRDFBaseData brdfData)
{
    #if _PBR
        InitializeHairBRDFBaseData(surfData.albedo, surfData.metallic, 1, surfData.smoothness, 1, brdfData);
    #else
        InitializeBlinnPhongBRDFData(surfData, brdfData);
    #endif
}

inline void InitializeHairSpecularData(out HairSpecularData hairSpecularData)
{
    hairSpecularData = (HairSpecularData)0;

    hairSpecularData.SpecularCol                =           _HairSpecularCol.rgb;
    hairSpecularData.SpecularShift              =           _HairSpecularShift;
    hairSpecularData.SpecularStrength           =           _HairSpecularStrength;
    hairSpecularData.SpecularExponent           =           _HairSpecularExponent;
    hairSpecularData.SecondarySpecularShift     =           _HairSecondarySpecularShift;
    hairSpecularData.SecondarySpecularCol       =           _HairSecondarySpecularCol.rgb;
    hairSpecularData.SecondarySpecularStrength  =           _HairSecondarySpecularStrength;
    hairSpecularData.SecondarySpecularExponent  =           _HairSecondarySpecularExponent;
    hairSpecularData.Spread1                    =           _HairSpread1;
    hairSpecularData.Spread2                    =           _HairSpread2;
    // hairSpecularData.ShiftUP  = _HairSpecularShiftUP;
    // hairSpecularData.ShiftSide  = _HairSpecularShiftSide;
}


inline void InitializeSurfaceData(half2 uv, out HairSurfaceData surfData)
{
    half4 albedoAlpha = SampleTexture(TRANSFORM_TEX(uv,_BaseMap),TEXTURE2D_ARGS(_BaseMap,sampler_BaseMap));

    half4 lightMap = SampleTexture(uv,TEXTURE2D_ARGS(_LightMap,sampler_LightMap));
    
    #if _NORMALMAP
        half4 tangentNormal = SampleTexture(uv,TEXTURE2D_ARGS(_BumpMap,sampler_BumpMap));
        //tangentNormal.xyz = UnpackNormalScale(tangentNormal, _BumpStrength);
        // 如果只是用法线的RG通道计算法线的话，可以使用该方法
        tangentNormal.xyz = MergeTexUnpackNormalRG(tangentNormal,_BumpStrength);
    #else
        half4 tangentNormal = half4(0.0h, 0.0h, 1.0h, 1.0h);
    #endif
    
    surfData.albedo = albedoAlpha.rgb * _Color.rgb;
    surfData.alpha = albedoAlpha.a;
    surfData.lightMap = lightMap;
    surfData.normalTS = tangentNormal;
    surfData.specMask = GetChannel(surfData, _SPECMASK);

    #if _EMISSION
        #if _EMISSIONMAP
            half3 emissionValue = SampleTexture(uv.xy,TEXTURE2D_ARGS(_EmissionMap,sampler_EmissionMap)).rgb;
        #else
            half3 emissionValue = GetChannel(surfData,_EmissionID);
        #endif
        surfData.emission = emissionValue * lerp(surfData.albedo, _EmissionColor, _Emission_Lerp) * _Emission_Instensity;
    #else
        surfData.emission = 0;
    #endif
    
    half occlusion = GetOcclusion(surfData, _AO);
    surfData.AO = occlusion;

    #if _PBR
        half metallic = GetMetallic(surfData, _METAL);
        half smoothness = GetSmoothness(surfData, _GLOSS);
        surfData.metallic = metallic;
        surfData.smoothness = smoothness;
    #endif
    
}

#endif