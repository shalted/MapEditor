#ifndef UNIVERSAL_HAIR_PASS_INCLUDED
#define UNIVERSAL_HAIR_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/BSDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "../CGInclude/Characters_AdditionalLightingData.hlsl"
#include "../CGInclude/CustomGiLight.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;

    float4 Color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 uv : TEXCOORD0;
    float4 positionWS : TEXCOORD1;
    float4 normalWS : TEXCOORD2; // xyz: normal, w: viewDir.x
    float4 tangentWS : TEXCOORD3; // xyz: tangent, w: viewDir.y
    float4 bitangentWS : TEXCOORD4; // xyz: bitangent, w: viewDir.z
    float4 vertexColor : COLOR;
    float4 shadowCoord : TEXCOORD7;
    float4 screenPos : TEXCOORD8;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings Vertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    //output.positionWS = vertexInput.positionWS;
    
    half3 positionWS = mul(unity_ObjectToWorld, input.positionOS).xyz;
    output.normalWS = half4(normalInput.normalWS, 1);
    output.tangentWS = half4(normalInput.tangentWS, 1);
    output.bitangentWS = half4(normalInput.bitangentWS, 1);
    output.positionCS = vertexInput.positionCS;
    output.uv.xy = input.uv;
    output.vertexColor = input.Color;
    output.shadowCoord = GetShadowCoord(vertexInput);
    half fog = ComputeFogFactor(vertexInput.positionCS.z);
    output.positionWS = half4(positionWS, fog);

    output.screenPos = ComputeScreenPos(vertexInput.positionCS);
    
    return output;
}

void InitializeInputData(Varyings input, half3 normalTS, out InputLitData inputData)
{
    inputData = (InputLitData)0;
    inputData.positionWS.xyz = input.positionWS.xyz;

    #if defined(_NORMALMAP)
        inputData.normalWS = TransformTangentToWorld(normalTS,
        half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
    #else
    inputData.normalWS.xyz = input.normalWS.xyz;
    #endif
    inputData.normalWS = normalize(inputData.normalWS);
    #if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
            inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
    #else
    inputData.shadowCoord = float4(0, 0, 0, 0);
    #endif

    half3 viewDirWS = GetCameraPositionWS() - input.positionWS.xyz;
    viewDirWS = SafeNormalize(viewDirWS);
    inputData.viewDirectionWS = viewDirWS;
    inputData.bakedGI = SampleSH(inputData.normalWS);
    inputData.fogCoord = input.positionWS.w;
}

inline void InitializeInputDotData(InputLitData inputData, Light mainLight, out InputDotData inputDotData)
{
    inputDotData.NdotL = dot(inputData.normalWS, mainLight.direction.xyz);
    inputDotData.NdotLClamp = saturate(dot(inputData.normalWS, mainLight.direction.xyz));
    inputDotData.HalfLambert = inputDotData.NdotL * 0.5 + 0.5;
    half3 halfDir = SafeNormalize(mainLight.direction + inputData.viewDirectionWS);
    inputDotData.LdotH = saturate(dot(mainLight.direction.xyz, halfDir.xyz));
    inputDotData.NdotH = saturate(dot(inputData.normalWS.xyz, halfDir.xyz));
    inputDotData.NdotV = saturate(dot(inputData.normalWS.xyz, inputData.viewDirectionWS.xyz));
    inputDotData.HalfDir = normalize(mainLight.direction.xyz + inputData.viewDirectionWS.xyz);
    #if defined(_RECEIVE_SHADOWS_OFF)
        inputDotData.atten = 1;
    #else
        inputDotData.atten = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
    #endif
    inputDotData.HalfLambertAtten = inputDotData.HalfLambert * inputDotData.atten;
}

half _HairShadowDistance;
half _DepthShadowCorrect;

inline half GetDepthOffsetShadow(half2 uv, Varyings input, half3 lightDir)
{
    #if UNITY_REVERSED_Z
    float depth = (input.positionCS.z / input.positionCS.w);
    depth = Linear01Depth(depth, _ZBufferParams);
    #else
    float depth = (input.positionCS.z / input.positionCS.w) * 0.5f + 0.5f;
    depth = Linear01Depth(1 - depth, _ZBufferParams);
    #endif

    // 关键算法！
    float2 scrPos = uv;
    float3 viewLightDir = normalize(TransformWorldToViewDir(lightDir)) * (1 / min(input.positionCS.w, 1)) * min(1, 5 / depth);
    float2 samplingPoint = scrPos + _HairShadowDistance / input.positionCS.w * 0.1f * viewLightDir.xy; // 屏幕空间偏移

    //float hairDepth = SAMPLE_TEXTURE2D(_HairSoildColor, sampler_HairSoildColor, samplingPoint).g;
    float hairDepth = SampleSceneDepth(samplingPoint).r;
    depth = SampleSceneDepth(uv).r;
    // float mask = SAMPLE_TEXTURE2D(_DepthMaskMap, sampler_DepthMaskMap, input.uv).r; // 有些地方不许有投影？

    half offset = saturate(1 - (hairDepth - depth) * 100);

    offset = offset < _DepthShadowCorrect ? 0 : 1;
	
    offset = smoothstep(-fwidth(offset) * 2, fwidth(offset) * 2, offset);
    offset = LerpWhiteTo(offset, 1);
    //offset = lerp(1,offset,mask);

    // 将mask部分设置为白色
    // half result = saturate(lerp(offset,1,mask));

    return offset;
}
 
inline half3 GetDiffuse(HairSurfaceData surfData, BRDFBaseData brdfData, InputDotData inputDotData, Varyings input)
{
    half halfLambertAtten = inputDotData.HalfLambert * inputDotData.atten;
    halfLambertAtten = 0.5 * (halfLambertAtten + surfData.AO);

    #if _DIFFUSERAMP
        #if _USE_RAMPID
            float uv_y =  SampleTexture(input.uv.xy, TEXTURE2D_ARGS(_RampUV_Y_ID_Map,sampler_RampUV_Y_ID_Map)).r;
            float2 uv = float2(halfLambertAtten, uv_y);
        #else
            float2 uv = float2(halfLambertAtten, _RampYOffset);
        #endif
        half3 rampColor = SampleTexture(uv, TEXTURE2D_ARGS(_ShadowMap,sampler_ShadowMap)).rgb;
        half3 radiance = rampColor;// rampColor *  diffuse;
    #elif _DIFFUSECEL
        half ramp = saturate(1 + (halfLambertAtten - _RampThreshold - _RampSmoothing)/ max(_RampSmoothing,1e-5));
        half3 radiance = lerp(_SColor.rgb, _HColor.rgb, ramp);
    #else
        half3 radiance = halfLambertAtten;
    #endif
    
    return radiance;
}

inline half3 GetRealKKSpecular(HairSurfaceData surfData, Varyings input, InputLitData inputData, InputDotData inputDotData, Light mainLight)
{
    half3 specularCol;
    #if _SPECULARHAIR_ON
        half4 specMask = surfData.specMask;
        HairSpecularData hairSpecularData;
        InitializeHairSpecularData(hairSpecularData);
        float2 detailUV = TRANSFORM_TEX(input.uv.xy,_DetailNormalMap);
        half4 detailNormal = SampleTexture(detailUV,TEXTURE2D_ARGS(_DetailNormalMap,sampler_DetailNormalMap));
            
        float3 T = normalize(input.bitangentWS.xyz);

        float2 jitter =(detailNormal.y-0.5) * float2(hairSpecularData.Spread1,hairSpecularData.Spread2);

        float3 t1 = ShiftTangent(T, inputData.normalWS, hairSpecularData.SpecularShift + jitter.xxx);
        float3 t2 = ShiftTangent(T, inputData.normalWS, hairSpecularData.SecondarySpecularShift + jitter.yyy);

        float3 hairSpec1 = hairSpecularData.SpecularCol * hairSpecularData.SpecularStrength *
            D_KajiyaKay(t1, inputDotData.HalfDir, hairSpecularData.SpecularExponent);
    
        float3 hairSpec2 = hairSpecularData.SecondarySpecularCol * hairSpecularData.SecondarySpecularStrength *
            D_KajiyaKay(t2, inputDotData.HalfDir, hairSpecularData.SecondarySpecularExponent);

        float3 spe = (hairSpec1 + 2 * detailNormal.z * hairSpec2) * specMask.a;
        float3 F = F_Schlick(half3(0.2,0.2,0.2), inputDotData.LdotH);
        specularCol = 0.25 * F * (hairSpec1 + hairSpec2) * inputDotData.NdotLClamp;//* saturate(geomNdotV * FLT_MAX);
        
        half LdotV = dot(mainLight.direction.xyz, inputData.viewDirectionWS.xyz);
        float3 normalBase = normalize(input.normalWS);
        float geomNdotV = dot(normalBase, inputData.viewDirectionWS.xyz);
        float geomNdotL = dot(normalBase, mainLight.direction.xyz);
        
        float scatterFresnel1 = pow(saturate(-LdotV), 9.0) * pow(saturate(1.0 - geomNdotV * geomNdotV), 12.0);
        float scatterFresnel2 = saturate(PositivePow((1.0 - geomNdotV), 20.0));
            
        half3 specT = scatterFresnel1 + 0.01 * scatterFresnel2;
        half transmittance = 0.01;
        specularCol += specT * transmittance;
    #endif
    return specularCol;
}

inline float Hairspecular(float3 flow, float3 viewDir, float3 lightDir, float3 N, float aniso, float shift)
{
    float3 hv = normalize(lightDir + viewDir);
    flow = normalize(flow + shift * N);
    float TdotH = dot(flow, hv);
    float sinTH = sqrt(1.0 - TdotH * TdotH);
    float specular = pow(sinTH, aniso) * LinearStep(-1.0, 0.0, TdotH);  

    return specular;
}

// 卡通头发高光
inline half3 GetRealToonSpecular(HairSurfaceData surfData, Varyings input, InputLitData inputData, InputDotData inputDotData, Light mainLight)
{
    
    half3 specularCol;
    #if _TOONKKHAIR_ON
    //     half4 specMask = SampleTexture(input.uv*_SpecMask_ST.xy+_SpecMask_ST.zw + half2(0, _SpecYOffset),TEXTURE2D_ARGS(_SpecMask,sampler_SpecMask));
    //     half3 tangentWS = normalize(input.tangentWS.xyz);
    //     half3 binormalWS = normalize(input.bitangentWS.xyz);
    //     half3 halfDir = normalize(inputData.viewDirectionWS + mainLight.direction);
    //     // 简单kk公式
    //     half ndh = dot(inputData.normalWS, halfDir);
    //     half ndv = saturate(dot(inputData.normalWS, inputData.viewDirectionWS));
    //     half tdh = dot(input.tangentWS, halfDir);
    //     half ndl = saturate(dot(inputData.normalWS, mainLight.direction));
    //     half smooth = max(0.01, (1 - _SpecularSmooth + 0.2 * specMask.r ) );
    //     //smooth = max(0.01, 1 - ndl);
    //     half bdh = dot(binormalWS, halfDir) / smooth;
    //     half specTerm = max(exp(-(tdh * tdh + bdh * bdh) / (1 + ndh)), 0.001);
    //     //half spec_atten = saturate(sqrt(max(0, halflambert / ndv)));
    //     specularCol = specTerm * _SpecularInstensity * inputDotData.HalfLambertAtten * specMask.a * specMask.rgb * _SpecToonKKColor;

    half4 shiftMap = SampleTexture(input.uv.xy * _DetailNormalMap_ST.xy + _DetailNormalMap_ST.zw, TEXTURE2D_ARGS(_DetailNormalMap,sampler_DetailNormalMap));
    float3 T = normalize(input.bitangentWS.xyz);
    half3 normalBias = lerp(inputData.normalWS, normalize(inputData.normalWS + inputDotData.HalfDir), _UseViewDir); 
    float3 shift = ShiftTangent(T, normalBias, shiftMap.r - 0.5 + _SpecYOffset);
    half specTerm = Hairspecular(T, inputData.viewDirectionWS.xyz, mainLight.direction.xyz, inputData.normalWS.xyz, exp2(10 * _SpecularSmooth + 1), shift.x);
    specularCol = specTerm * _SpecularInstensity * _SpecToonKKColor.rgb * surfData.specMask;
    #endif
    return specularCol;
}

inline half3 GetFixSpecular(HairSurfaceData surfData, Varyings input, InputLitData inputData, InputDotData inputDotData, Light mainLight)
{
    half3 specularCol;
    #if _TOONGENHAIR_ON
        // 高光
        // https://www.programmersought.com/article/33165109052/
        // 因为头发的高光不考虑上下方向，只考虑左右，所以将 normal 和 view 转为视空间的xz平面
        half mask = surfData.specMask;
        half3 halfDir = normalize(inputData.viewDirectionWS + mainLight.direction);
        float3 normalV = mul(UNITY_MATRIX_V, inputData.normalWS);
        float3 haldV = mul(UNITY_MATRIX_V, halfDir);
        half ndh = dot(normalize(normalV.xz), normalize(haldV.xz));
        ndh = pow(ndh, 6) * _SpecWidth;
        ndh = pow(ndh, 1 / _SpecLength);
        half lightFeather = _LightFeather * ndh;
        half lightStepMax = saturate(1 - ndh + lightFeather);
        half lightStepMin = saturate(1 - ndh - lightFeather);
        half brightArea = LinearStep(lightStepMin, lightStepMax, min(mask, 0.99));
        half3 lightColor_H = brightArea * _SpecBright.rgb;
        half3 lightColor_L = LinearStep(_SpecThreshold, 1, mask) * _SpecLight.rgb;
        specularCol = (lightColor_L + lightColor_H);
        specularCol *= (inputDotData.HalfLambertAtten * (1 - _specInShadow) + _specInShadow);
    #endif
    return specularCol;
}

half DirectBRDFSpecular2(BRDFBaseData brdfData, half3 LoH, half3 NoH)
{
    float d = NoH.x * NoH.x * brdfData.roughness2MinusOne + 1.00001f;

    half LoH2 = LoH.x * LoH.x;
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

// 高光函数
// 如果是_STYLIZED， specularMap 当作高光大小
// 如果是_PHONG， 光滑度来自光滑度通道
// 如果是_GGX, 光滑度来自光滑度通道，并且乘上specularColor！
half3 CalculateSpecular(InputDotData inputDotData, inout HairSurfaceData surfData, BRDFBaseData brdfData)
{
    half ndoth = inputDotData.NdotH;
    // 区分了金属的高光强度
    //half specIntensity = lerp(1, 1, pbrData.metallic) * specluarIntensity;
    half specIntensity = 1;
    half3 spec = 0;

    spec = DirectBRDFSpecular2(brdfData, inputDotData.LdotH, inputDotData.NdotH) * brdfData.specColor;

    spec = max(0.001f, spec) * specIntensity;
    return spec;
}

inline half3 GetSpecColor(HairSurfaceData surfData, BRDFBaseData brdfData, InputDotData inputDotData, InputLitData inputData, Varyings input, Light mainLight)
{
    half3 specularCol = 0;
    #if _SPECULARHAIR_ON
    specularCol = GetRealKKSpecular(surfData, input, inputData, inputDotData, mainLight);
    #elif _TOONKKHAIR_ON
    specularCol = GetRealToonSpecular(surfData, input, inputData, inputDotData, mainLight);
    #elif _TOONGENHAIR_ON
    specularCol = GetFixSpecular(surfData, input, inputData, inputDotData, mainLight);
    #endif
    
    half3 specPBR = 0;
    #if _PBR
    specPBR = CalculateSpecular(inputDotData, surfData, brdfData) * _PBRSpecIntensity * _PBRSpecColor.rgb;
    #endif
    //return specularCol *surfData.lightMap.r * inputDotData.NdotL * inputDotData.atten;
    return (specularCol * surfData.albedo + specPBR) * inputDotData.HalfLambertAtten;
}

half3 CharacterGlobalIllumination(BRDFBaseData brdfData, half AO, half EnvExposure, half3 normalWS, half3 viewDirectionWS, float envRotate, AdditionalData addData)
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
    indirectSpecular =  irradiance * AO;
    #else // GLOSSY_REFLECTIONS
    indirectSpecular =  _GlossyEnvironmentColor.rgb * AO;
    #endif
    indirectSpecular *= EnvExposure;

    //toolbag add
    half ho = EnvHorizonOcclusion(reflectVector, normalWS, addData.normalWS, addData.horizonFade);
    
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    return surfaceReduction * indirectSpecular * lerp(brdfData.specColor, brdfData.grazingTerm, fresnelTerm) * ho;
}

inline half3 GetGIColor(HairSurfaceData surfData, InputLitData inputData, BRDFBaseData BRDFBaseData)
{
    half3 indirectDiffuse = BRDFBaseData.diffuse * inputData.bakedGI;
    indirectDiffuse *= _SHExposure;
    indirectDiffuse *= surfData.AO;

    half3 indirectSpecular = 0;
    #if _GLOSSYREFLECTIONS_ON
        AdditionalData addData = (AdditionalData)0;
        addData.positionWS = inputData.positionWS;
        InitHDRData(_Use_Custom_SpecCube_HDR,_Custom_SpecCube_HDR,addData);
        half AO = surfData.AO;
        indirectSpecular = CharacterGlobalIllumination(BRDFBaseData, AO, _IndirectIntensity, inputData.normalWS, inputData.viewDirectionWS, _EnvRotate, addData);
            #ifdef _PBR
            indirectSpecular = indirectSpecular * _CubemapColor.rgb * surfData.smoothness * surfData.smoothness;
            #else
            indirectSpecular = indirectSpecular * _CubemapColor.rgb;
            #endif
    #endif 
    
    return  indirectDiffuse + indirectSpecular; 
}

inline half3 GetRimColor(InputDotData inputDotData, InputLitData inputData)
{
    half3 rimColor = 0;
    #if _RIM_ON
        half NdotRimL = saturate(dot(inputData.normalWS,_RimDir.xyz));
        half invertNdotV = 1- inputDotData.NdotV;
        #if CHARACTER_LOD_0
            invertNdotV = Pow4(invertNdotV);
        #else
            invertNdotV = invertNdotV * invertNdotV * invertNdotV;
        #endif
        half rimvalue = LinearStep(_RimThreshold, _RimThreshold + _RimSmooth, invertNdotV);
        rimvalue *= LerpWhiteTo(NdotRimL,_RimDirContribution); // 修改强度，越来越白
        rimColor = rimvalue * _RimColor.rgb;
    #else
        rimColor = 0;
    #endif
    return rimColor;
}

half4 Fragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    HairSurfaceData surfData;
    InitializeSurfaceData(input.uv.xy, surfData);

    InputLitData inputData;
    InitializeInputData(input, surfData.normalTS.xyz, inputData);

    BRDFBaseData brdfBaseData;
    InitalizeHairBRDFData(surfData, brdfBaseData);
    
    // 获取灯光数据
    #if defined(SHADOWS_SHADOWMASK) && defined(lightMap_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined (lightMap_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
    
    //附加灯光脚本全局变化：光源方向，光源颜色，光源阴影 / bakeGI / SpecularColor
    CharacterLightControllerData(mainLight, inputData, brdfBaseData);
    
    InputDotData inputDotData;
    InitializeInputDotData(inputData, mainLight, inputDotData);

    half3 diffuseColor = 0;
    half3 specularColor = 0;
    half3 giColor = 0;
    half3 rimColor = 0;
    half3 finalColor = 0;

    diffuseColor = GetDiffuse(surfData, brdfBaseData, inputDotData, input) * mainLight.color;
    specularColor = GetSpecColor(surfData, brdfBaseData, inputDotData, inputData, input, mainLight) * mainLight.color;
    giColor = GetGIColor(surfData, inputData, brdfBaseData);//环境光计算
    rimColor = GetRimColor(inputDotData, inputData);

    finalColor = (diffuseColor * brdfBaseData.diffuse + specularColor) + giColor + rimColor + surfData.emission;

    finalColor = MixFog(finalColor, inputData.fogCoord) * _ProceduralColor.rgb;
    
    return half4(finalColor, surfData.alpha * _ProceduralColor.a);
}

/*half4 ZS_Fragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    HairSurfaceData nprBaseData;
    InitializeSurfaceData(input.uv.xy, nprBaseData);

    InputLitData inputData;
    InitializeInputData(input, nprBaseData.normalTS.xyz, inputData);

    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, unity_ProbesAO);
    AdditionalLightData addLightData;
    GetAdditionalLightData(mainLight, addLightData);

    half lightAttenuation  = mainLight.distanceAttenuation * mainLight.shadowAttenuation;
    half NdotL = dot(inputData.normalWS, mainLight.direction.xyz);
    half halflambert = NdotL * 0.5 + 0.5;
    halflambert *= lightAttenuation;
    
    //Diffuse
    halflambert = 0.5 * (halflambert + nprBaseData.lightMap.g);

    half _1stShadowStep = floor(halflambert - _ShadowThreshold + 1);
    //half2 rampUV = half2(rampUVX,_RampYOffset);
    //half3 rampColor = SampleTexture(rampUV, TEXTURE2D_ARGS(_ShadowMap,sampler_ShadowMap)).rgb;
    _1stShadowStep = floor(_1stShadowStep);
    half3 rampColor = lerp(1, _ShadowColor.rgb, 1 -_1stShadowStep);
    // half inlineStep = step(_InlineThreshold,nprBaseData.lightMap.g);
    // rampColor = lerp(_InlineColor.rgb,rampColor,inlineStep);
    half3 col = nprBaseData.albedo.xyz * rampColor * mainLight.color;
   
    //HightLight
    half3 halfDir = normalize(inputData.viewDirectionWS + mainLight.direction);
    half NdotH = max(saturate(dot(input.normalWS.xyz, halfDir)),1e-5);
    
    half IF_INVERT_SPECULAR = 1;
    
    half specTerm = pow(lerp(NdotH,1- NdotH,IF_INVERT_SPECULAR),_SpecularShiness);
    specTerm = 1-nprBaseData.lightMap.x + 1 - specTerm;
    specTerm = max(1 - floor(specTerm),0);
   
    specTerm *= nprBaseData.lightMap.z;
    specTerm *= saturate(_1stShadowStep);

    half3 specCol = specTerm * _SpecBright.rgb;
    col +=specCol;
    //return   specCol.xyzz;
    //#if _RIM_ON
    half NdotRimL = saturate(dot(inputData.normalWS,_RimDir.xyz));
    half NdotV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS.xyz));
    half invertNdotV = 1-NdotV;
    //#if CHARACTER_LOD_0
    invertNdotV = Pow4(invertNdotV);
    // #else
    // invertNdotV = invertNdotV * invertNdotV * invertNdotV;
    // #endif
    half rimvalue = LinearStep(_RimThreshold, _RimThreshold + _RimSmooth, invertNdotV);
    rimvalue *= LerpWhiteTo(NdotRimL,_RimDirContribution); // 修改强度，越来越白
    half3 rimColor = rimvalue * _RimColor.rgb;
   // #else
    //half3 rimColor = 0;
    //#endif
    col +=rimColor;
    return  half4(col,1);
}*/

#endif
