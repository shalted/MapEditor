#ifndef INSERTINGPATCHESFUR_FORWARDPASS_INCLUDE
#define INSERTINGPATCHESFUR_FORWARDPASS_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
#include "../CGInclude/Characters_AdditionalLightingData.hlsl"
#include "../CGInclude/CustomGiLight.hlsl"


//=================================================================//
//                       Buffer Struct                             //
//=================================================================//
struct Attributes
{// 顶点输入结构
    half4 vertex : POSITION;
    half3 normal : NORMAL;
    half4 tangentOS : TANGENT;
    half2 texcoord0 : TEXCOORD0;
    half2 texcoord1 : TEXCOORD1;
    half2 texcoord2 : TEXCOORD2;
    half4 color : COLOR;
};

struct Varyings
{// 顶点着色器输出结构
    float4 positionCS : SV_POSITION;
    float4 positionWS : TEXCOORD0; /* w = fog coords */
    float4 uv : TEXCOORD1; //xy: sourceUV  zw:mainTextureUV
    float4 normalWS                 : TEXCOORD2;    // xyz: normal, w: viewDir.x
    float4 tangentWS                : TEXCOORD3;    // xyz: tangent, w: viewDir.y
    float4 bitangentWS              : TEXCOORD4;    // xyz: bitangent, w: viewDir.z
    float4 screenPos : TEXCOORD5;
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord : TEXCOORD6; // 计算阴影坐标
    #endif
    half4 vertexSH : TEXCOORD7;
    float4 uv2 :TEXCOORD8;
    half4 color : COLOR;
};
//=============================END==================================//

//=================================================================//
//                          基础函数计算                             //
//=================================================================//
inline void InitializeSurfaceData(Varyings i, out SurfaceLitData surfData)
{
    surfData = (SurfaceLitData)0;

    //固有色
    half4 albedoAlpha =  SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv.zw);

    surfData.albedoAlpha = albedoAlpha;
    surfData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    surfData.alpha = albedoAlpha.a * _BaseColor.a;
    
    #ifdef _ALPHATEST_ON
        clip(surfData.alpha - _Cutoff);
    #endif

    //法线遮罩图
    half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv.xy);
    
    surfData.maskMap = maskMap;
    surfData.normalTS = MergeTexUnpackNormalRG(maskMap,_BumpStrength);
    surfData.AO = lerp(1.0h, maskMap.z, _AOIntensity);

    //PBR参数
    half4 nprLightMap = SAMPLE_TEXTURE2D(_NPRLightMap, sampler_NPRLightMap, i.uv.xy);

    #if _EMISSION
    surfData.emission =  maskMap.a * _EmissionColor.rgb * _Emission_Instensity;
    #else
    surfData.emission = 0;
    #endif

    surfData.metallic = saturate(nprLightMap.x * _MetallicScale + _MetallicBias);
    surfData.smoothness = saturate(nprLightMap.y * (1.0h - _SmoothnessScales) + _SmoothnessBias);
    surfData.rampID = nprLightMap.z + _RampYOffset;
    surfData.MaskAlpha = nprLightMap.a;
}

inline void InitializeInputData(Varyings input, SurfaceLitData surfData, out InputLitData inputData)
{
    inputData = (InputLitData)0;

    inputData.positionWS = input.positionWS.xyz;
    inputData.positionCS = input.positionCS;

    inputData.tangentToWorld = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
    
    inputData.normalWS = normalize(TransformTangentToWorld(surfData.normalTS.xyz, inputData.tangentToWorld));

    inputData.viewDirectionWS = normalize(half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w));
    
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
    #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    #else
    inputData.shadowCoord = half4(0, 0, 0, 0);
    #endif
    inputData.shadowCoord.z += _CustomShadowBias;//投影偏移
    

    inputData.fogCoord = input.positionWS.w;

    inputData.bakedGI = input.vertexSH.rgb;
    // half4 ShTint = lerp(unity_AmbientGround, unity_AmbientSky, saturate((inputData.normalWS.y + 1.0h) * 0.5h));
    // ShTint = lerp(unity_AmbientEquator, ShTint, saturate(abs(inputData.normalWS.y)));
    //inputData.bakedGI.rgb *= ShTint;  

    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

    inputData.shadowMask = unity_ProbesOcclusion;
}

inline void InitializeInputDotData(InputLitData inputData, Light mainLight, half ShadowIntensity, out InputDotData inputDotData)
{
    inputDotData.NdotL = dot(inputData.normalWS, mainLight.direction.xyz);
    inputDotData.NdotLClamp = saturate(dot(inputData.normalWS, mainLight.direction.xyz));
    inputDotData.HalfLambert = inputDotData.NdotL * 0.5 + 0.5;
    half3 halfDir = SafeNormalize(mainLight.direction + inputData.viewDirectionWS);
    inputDotData.LdotH = saturate(dot(mainLight.direction.xyz, halfDir.xyz));
    inputDotData.NdotH = saturate(dot(inputData.normalWS.xyz, halfDir.xyz));
    inputDotData.NdotV = saturate(dot(inputData.normalWS.xyz, inputData.viewDirectionWS.xyz));
    inputDotData.HalfDir = halfDir;
    
    #if defined(_RECEIVE_SHADOWS_OFF)
    inputDotData.atten = 1;
    #else
    inputDotData.atten = LerpWhiteTo(mainLight.shadowAttenuation, ShadowIntensity) * mainLight.distanceAttenuation;
    #endif
}

inline void InitializeBRDFBaseData(SurfaceLitData surfData, out BRDFBaseData outBRDFBaseData)
{
    outBRDFBaseData = (BRDFBaseData)0;
    
    half oneMinusReflectivity = LinearOneMinusReflectivityFromMetallic(surfData.metallic);
    half reflectivity = 1.0 - oneMinusReflectivity;
    
    outBRDFBaseData.diffuse = surfData.albedo * oneMinusReflectivity;
    outBRDFBaseData.specColor = lerp(unity_LinearColorSpaceDielectricSpec.rgb, surfData.albedo, surfData.metallic);

    outBRDFBaseData.grazingTerm = saturate(surfData.smoothness + reflectivity);
    outBRDFBaseData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surfData.smoothness);
    // NB: CustomLit 使用的是HALF_MIN， 结果GGX在光滑度为1是很小
    outBRDFBaseData.roughness = max(PerceptualRoughnessToRoughness(outBRDFBaseData.perceptualRoughness), HALF_MIN_SQRT); 
    outBRDFBaseData.roughness2 = outBRDFBaseData.roughness * outBRDFBaseData.roughness;

    outBRDFBaseData.normalizationTerm = outBRDFBaseData.roughness * 4.0h + 2.0h;
    outBRDFBaseData.roughness2MinusOne = outBRDFBaseData.roughness2 - 1.0h;
}

inline void GetMainLight(Varyings input, InputLitData inputData, out Light currentLight)
{
    currentLight = (Light)0;
    
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS.xyz, inputData.shadowMask);

    #if _RECEIVE_MAIN_SHADOWS_OFF
    mainLight.shadowAttenuation = 1;
    #endif

    half pershadow = 1;
    // #if _RECEIVE_PEROBJECT_SHADOWS
    // pershadow = SampleScreenSpaceShadowmap(input.screenPos);
    // #endif

    mainLight.shadowAttenuation = mainLight.shadowAttenuation * pershadow;

    currentLight = mainLight;
}

inline void InitializeLightingData(SurfaceLitData surfData, InputLitData inputData, out LightingLitData lightingData)
{
    lightingData = (LightingLitData)0;

    lightingData.giColor = inputData.bakedGI;
    lightingData.mainLightColor = 0.0h;
    lightingData.additionalLightsColor = 0.0h;
    lightingData.vertexLightingColor = 0.0h;
    lightingData.emissionColor = 0.0;
}
//=============================END==================================//


//=================================================================//
//                             着色器                               //
//=================================================================//
inline void GetRenderAlpha(SurfaceLitData surfData, InputDotData inputDotData, out half finalAlpha)
{//插片毛发半透明过渡计算。优化噪点问题
    
    finalAlpha = surfData.alpha;
}

inline void GetRadiance(InputDotData inputDotData, half useHalfLambert, out half radiance)
{
    half ndl = lerp(inputDotData.NdotLClamp, inputDotData.HalfLambert, useHalfLambert);
    
    #if _RAMPSHADING

    #else
    ndl *= inputDotData.atten;
    #endif
    
    radiance = ndl;
}

inline void GetDiffuseColor(SurfaceLitData surfData, InputDotData inputDotData, Light mainlight, inout half radiance, out half3 diffuseColor)
{
    diffuseColor = 1.0h;
    half3 celDiffuseColor = 1.0h;
    half3 rampDiffuseColor = 1.0h;


    //二分阴影
    half celDiffuseValue = _RampSmoothing * 0.5h;
    celDiffuseValue = saturate(1.0h + (radiance - _RampThreshold - celDiffuseValue) / max(celDiffuseValue, 1e-3));
    celDiffuseValue = smoothstep(_RampThreshold, _RampThreshold + _RampSmoothing, radiance);
    celDiffuseColor = lerp(_SColor.rgb, _HColor.rgb, celDiffuseValue);
    
    //Ramp阴影
    half radianceWithShadow = radiance * mainlight.shadowAttenuation;
    
    half2 rampDiffuseId = half2(radiance, surfData.rampID);
    half2 rampDiffuseId_WithShadow = half2(radianceWithShadow, surfData.rampID);
    
    half3 rampDiffuseColor_source = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampDiffuseId).xyz;
    half3 rampDiffuseColor_WithShadow = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampDiffuseId_WithShadow).xyz;

    rampDiffuseColor = lerp(rampDiffuseColor_source, rampDiffuseColor_WithShadow, _ShadowIntensity);
    
    
    #if _CELSHADING
    diffuseColor = celDiffuseColor;
    #elif _RAMPSHADING
    diffuseColor = rampDiffuseColor;
    radiance *= inputDotData.atten;
    #endif
}

half DirectBRDFSpecular2(BRDFBaseData brdfData, half LoH, half NoH)
{
    half d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

    // On platforms where half actually means something, the denominator has a risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
    #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
    #endif

    return specularTerm;
}
inline void GetSpecularColor(Varyings input, SurfaceLitData surfData, InputLitData inputData, BRDFBaseData BRDFBaseData, Light mainLight, InputDotData inputDotData, half radiance, out half3 specularColor)
{
    //简化版PBR高光
    // half OneMinusNoHSqr = 1.0h - inputDotData.NdotH * inputDotData.NdotH;
    // half n = inputDotData.NdotH * BRDFBaseData.roughness;
    // half p = BRDFBaseData.roughness / (OneMinusNoHSqr + n * n);
    // half specularTerm = p * p;
    // specularTerm *= 0.45h;//强度与标准GGX校正
    
    half specularTerm = DirectBRDFSpecular2(BRDFBaseData, inputDotData.LdotH, inputDotData.NdotH);
    
    half specIntensity = lerp(_SpecularIntensity, _SpecularIntensity * (1 + _MetaIntensity), surfData.metallic) * surfData.MaskAlpha;

    half3 pbrSpecularColor = lerp(_SpecularColor.rgb, _SpecularColor.rgb * surfData.albedo, _SpecularColorBlender);
    pbrSpecularColor *= specularTerm * specIntensity;
    pbrSpecularColor *= BRDFBaseData.specColor;
    pbrSpecularColor *= radiance;
    
    //各向异性高光
    half3 tangentWS = normalize(input.tangentWS.xyz);
    half3 bitangentWS = normalize(input.bitangentWS.xyz);

    half roughnessT = BRDFBaseData.roughness * (1 + _Anisotropy);
    half roughnessB = BRDFBaseData.roughness * (1 - _Anisotropy);
    
    half3 Anisotropy_specularTerm = 0;
    float TdotH = dot(tangentWS, inputDotData.HalfDir);
    float TdotL = dot(tangentWS, mainLight.direction);
    float BdotH = dot(bitangentWS, inputDotData.HalfDir);
    float BdotL = dot(bitangentWS, mainLight.direction);
    float TdotV = dot(tangentWS,   inputData.viewDirectionWS);
    float BdotV = dot(bitangentWS, inputData.viewDirectionWS);

    half partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, inputDotData.NdotV, roughnessT, roughnessB);
    
    float3 F = F_Schlick(BRDFBaseData.specColor, inputDotData.LdotH);
    
    float DV = DV_SmithJointGGXAniso(
        TdotH, BdotH, inputDotData.NdotH, inputDotData.NdotV, TdotL, BdotL, inputDotData.NdotL, 
        roughnessT, roughnessB, partLambdaV); // D_GGXAniso() * V_SmithJointGGXAniso()

    Anisotropy_specularTerm = max(0.001, F * DV) * inputDotData.NdotLClamp;
    Anisotropy_specularTerm *= _SpecularAnisotropyIntensity;
    
    //高光颜色
    half3 anisotropySpecularColor = Anisotropy_specularTerm * _SpecularAnisotropyColor.rgb;

    specularColor = pbrSpecularColor;
    #if _ANISOTROPY
    specularColor += anisotropySpecularColor;
    #endif
}

half3 CharacterGlobalIllumination(BRDFBaseData brdfData, half occlusion, half EnvExposure, half3 normalWS, half3 viewDirectionWS, float envRotate, AdditionalData addData)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half3 reflectRotaDir = RotateAround(reflectVector, envRotate);
    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, reflectVector)));
    half3 indirectSpecular = 0;

    // specular:
    #if defined(_GLOSSYREFLECTIONS_ON)
    half mip = PerceptualRoughnessToMipmapLevel(brdfData.perceptualRoughness);
    //half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectRotaDir, mip);
    #ifdef _CUSTOM_ENV_CUBE  
    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(_EvnCubemap, sampler_EvnCubemap, reflectRotaDir, mip);
    #elif _SCENE_ENV
    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(_CharacterCustomEnv, sampler_CharacterCustomEnv, reflectRotaDir, mip);
    #else
    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectRotaDir, mip);
    #endif

    #if _CUSTOM_ENV_CUBE || _SCENE_ENV
    half4 decodeInstructions = lerp(unity_SpecCube0_HDR,addData.custom_SpecCube_HDR,addData.use_Custom_HDR);
    #else
    half4 decodeInstructions =  unity_SpecCube0_HDR;
    #endif
    
    #if !defined(UNITY_USE_NATIVE_HDR)
    half3 irradiance = DecodeHDREnvironment(encodedIrradiance, decodeInstructions);
    #else
    half3 irradiance = encodedIrradiance.rbg;
    #endif
    
    #if UNITY_COLORSPACE_GAMMA
    indirectSpecular =  irradiance.rgb = FastSRGBToLinear(irradiance.rgb);
    #endif
    indirectSpecular =  irradiance * occlusion;
    #else // GLOSSY_REFLECTIONS
    indirectSpecular =  _GlossyEnvironmentColor.rgb * occlusion;
    #endif
    indirectSpecular *= EnvExposure;

    //toolbag add
    half ho = EnvHorizonOcclusion(reflectVector, normalWS, addData.normalWS, addData.horizonFade);
    
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    return surfaceReduction * indirectSpecular * lerp(brdfData.specColor, brdfData.grazingTerm, fresnelTerm) * ho;
}

inline void GetGIColor(SurfaceLitData surfData, InputLitData inputData, BRDFBaseData BRDFBaseData, out half3 giColor)
{
    half3 indirectDiffuse = BRDFBaseData.diffuse * inputData.bakedGI;
    indirectDiffuse *= _SHExposure;
    indirectDiffuse *= surfData.AO;

    half3 indirectSpecular = 0;
    #if _GLOSSYREFLECTIONS_ON
        AdditionalData addData = (AdditionalData)0;
        addData.positionWS = inputData.positionWS;
        InitHDRData(_Use_Custom_SpecCube_HDR,_Custom_SpecCube_HDR,addData);
        half occlusion = surfData.AO;
        indirectSpecular = CharacterGlobalIllumination(BRDFBaseData, occlusion, _IndirectIntensity, inputData.normalWS, inputData.viewDirectionWS, _EnvRotate, addData);
        indirectSpecular = indirectSpecular * _CubemapColor.rgb * surfData.smoothness * surfData.smoothness;
    #endif 
    
    giColor = indirectDiffuse + indirectSpecular; 
}

inline void GetRimColor(SurfaceLitData surfData, InputLitData inputData, InputDotData inputDotData, Light mainLight, half radiance, out half3 rimColor)
{
    half3 rimFinalColor = 0;
    half3 rimDir = lerp(_LightDirOffset * mainLight.direction.xyz, _RimDir.xyz, _RimCustom);
    half NdotRimL = saturate(dot(inputData.normalWS, rimDir));
    half ndv4 = Pow4(1 - inputDotData.NdotV);
    half rimvalue = smoothstep(_RimThreshold, _RimThreshold + _RimSmooth, ndv4);
    rimvalue *= LerpWhiteTo(NdotRimL, _RimDirContribution);

    half3 darkColor = lerp(0, 1, _RimColorBlendMode).xxx;
    rimFinalColor = lerp(darkColor, _RimColor.rgb , rimvalue.xxx);

    rimFinalColor *= lerp(1.0h, inputDotData.atten, _RimMaskUseShadow);
    rimColor = rimFinalColor;
}

inline void GetMapCap(SurfaceLitData surfData, InputLitData inputData, out half3 MapCapColor)
{
    half3 matcap = 0;
    #if _MATCAP
        half2 matcapUV = 0;
        half3 matcapCoordsNormal = mul((half3x3)UNITY_MATRIX_V, inputData.normalWS);
        matcapUV = matcapCoordsNormal.xy * 0.5 + 0.5;
        matcapUV = matcapUV * _MatCapMap_ST.xy + _MatCapMap_ST.zw;

        matcap = SAMPLE_TEXTURE2D(_MatCapMap, sampler_MatCapMap, matcapUV).rgb * _MatCapColor.rgb * surfData.metallic * _MatcapIntensity * surfData.albedo;
        matcap *= surfData.metallic;
    #endif
    MapCapColor = matcap;
}
//=============================END==================================//



//=================================================================//
//                             着色器                               //
//=================================================================//
Varyings Vertex(Attributes input)
{
    Varyings output = (Varyings)0;

    //UV
    output.uv.xy = input.texcoord0.xy;
    output.uv.zw = input.texcoord0.xy * _BaseMap_ST.xy + _BaseMap_ST.zw;
    output.uv2.xy = input.texcoord1;
    output.uv2.zw = input.texcoord2;
    

    //顶点坐标
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);

    float3 positionWS = vertexInput.positionWS;
    float4 positionCS = vertexInput.positionCS;
    output.positionCS = positionCS;

    output.positionWS.xyz = positionWS;
    output.positionWS.w = ComputeFogFactor(positionCS.z);

    output.screenPos = ComputeScreenPos(output.positionCS);
    
    #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = TransformWorldToShadowCoord(vertexInput.positionWS);
    #endif


    //向量
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normal, input.tangentOS);

    output.normalWS.xyz = vertexNormalInput.normalWS;
    output.tangentWS.xyz = vertexNormalInput.tangentWS;
    output.bitangentWS.xyz = vertexNormalInput.bitangentWS;
    
    float3 viewDirWS = GetCameraPositionWS() - positionWS;
    output.normalWS.w = viewDirWS.x;
    output.tangentWS.w = viewDirWS.y;
    output.bitangentWS.w = viewDirWS.z;

    // 环境光
    output.vertexSH = half4(ShouWangSampleSH(output.normalWS.xyz), 1.0h);

    output.color = input.color;
    
    return output;
}

void Fragment(Varyings input, half facing : VFACE, out half4 outColor : SV_Target
#ifdef _WRITE_RENDERING_LAYERS
, out float4 outRenderingLayers : SV_Target1
#endif
)
{
    DitherThreshold(input.screenPos, input.positionCS.xy, _DitherTimer);

    
    //================基础数据准备================
    //贴图数据
    SurfaceLitData surfData;
    InitializeSurfaceData(input, surfData);

    //基础顶点输入数据
    InputLitData inputData;
    InitializeInputData(input, surfData, inputData);

    //PBR参数数据
    BRDFBaseData brdfBaseData;
    InitializeBRDFBaseData(surfData, brdfBaseData);

    //主光源数据
    Light mainLight;
    GetMainLight(input, inputData, mainLight);

    //附加灯光脚本全局变化：光源方向，光源颜色，光源阴影 / bakeGI / SpecularColor
    CharacterLightControllerData(mainLight, inputData, brdfBaseData);
    
    //光照点乘数据
    InputDotData inputDotData;
    InitializeInputDotData(inputData, mainLight, _ShadowIntensity, inputDotData);


    //================光照计算================
    LightingLitData lightingData;
    InitializeLightingData(surfData, inputData, lightingData);
    
    half radiance = 0.0h;
    half3 diffuseColor = 0.0h;
    half3 specularColor = 0.0h;
    half3 giColor = 0.0h;
    half3 rimColor = 0.0h;
    half3 matcap = 0;
    half3 additionalLightsColor = 0.0h;
    half3 emissionColor = 0.0h;

    GetRadiance(inputDotData, _UseHalfLambert, radiance);//阴影系数计算
    GetDiffuseColor(surfData, inputDotData, mainLight, radiance, diffuseColor);//阴影颜色计算
    GetSpecularColor(input, surfData, inputData, brdfBaseData, mainLight, inputDotData, radiance, specularColor);//高光计算
    GetGIColor(surfData, inputData, brdfBaseData, giColor);//环境光计算
    GetRimColor(surfData, inputData, inputDotData, mainLight,radiance, rimColor);//边缘光计算
    GetMapCap(surfData, inputData,matcap);
    
    //多光源计算
    //AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData.normalizedScreenSpaceUV, 1/*surfData.occlusion*/);
    //uint meshRenderingLayers = GetMeshRenderingLayer();

    
    //================最终颜色计算================
    half3 finalColor = surfData.albedo;
    half alpha = surfData.alpha;

    GetRenderAlpha(surfData, inputDotData, alpha);

    //基础光照计算
    lightingData.mainLightColor = (brdfBaseData.diffuse * diffuseColor + specularColor) * mainLight.color;
    lightingData.giColor = giColor;
    lightingData.additionalLightsColor = additionalLightsColor;
    lightingData.emissionColor = surfData.emission;
    
    //finalColor = CalculateLitLightingColor(lightingData, 1.0h);
    finalColor = lightingData.mainLightColor + lightingData.giColor + lightingData.emissionColor;
    
    //角色特殊光照计算
    finalColor += rimColor + matcap;

    //特效效果计算

    finalColor.rgb = MixFog(finalColor, inputData.fogCoord) * _ProceduralColor.rgb;
    
    outColor = half4( finalColor, alpha * _ProceduralColor.a);
    
    //================其他功能================
    #if defined(DEBUG_DISPLAY)
    half4 debugColor = 0;
    if(CanDebugOverrideDefaultOutputColor(inputData, surfData, BRDFBaseData, debugColor))
    {
        outColor = debugColor;
        return;
    }
    #endif

    #ifdef _WRITE_RENDERING_LAYERS
    uint renderingLayers = GetMeshRenderingLayer();
    outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
    #endif
}
//=============================END==================================//

#endif
