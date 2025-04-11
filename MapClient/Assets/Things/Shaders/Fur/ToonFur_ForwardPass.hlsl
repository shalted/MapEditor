#ifndef TOONFUR_FORWARDPASS_INCLUDE
#define TOONFUR_FORWARDPASS_INCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//#include "ShaderLibrary/CustomColor.hlsl"
//#include "ShaderLibrary/Common.hlsl"
//#include "ShaderLibrary/CharacterCustomShadow.hlsl"
// #include "ShaderLibrary/AdditionalLightData.hlsl"
// #include "ShaderLibrary/Effects_Addition.hlsl"
// #include "ShaderLibrary/HackSpace.hlsl"
// #include "ShaderLibrary/AdditionalInput.hlsl"

// 顶点输入结构
struct Attributes
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangentOS : TANGENT;
	half2 texcoord0 : TEXCOORD0;
	half2 texcoord1 : TEXCOORD1;
	half2 texcoord2 : TEXCOORD2;
	float4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

// 顶点着色器输出结构
struct Varyings
{
    float4 positionCS : SV_POSITION;
	float4 positionWS : TEXCOORD0; // w：fog coords
    float4 uv : TEXCOORD1; //xy：UV, zw：Noise UV
	float4 normalWS                 : TEXCOORD2;    // xyz: normal, w: 毛发长度
	float4 tangentWS                : TEXCOORD3;    // xyz: tangent, w: 毛发朝向X
	float4 bitangentWS              : TEXCOORD4;    // xyz: bitangent, w: 毛发朝向Y
	float4 newNormalWS				: TEXCOORD5;	// xyz: 使用毛发朝向后的法线，w：毛发朝向Z
	
	float4 screenPos : TEXCOORD6;
	float4 uv2 : TEXCOORD7;//xy: uv1  zw：uv2
	float4 Color : TEXCOORD8;//给Houdini毛发和合批毛发用
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};
Varyings vert_fur(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

	output.Color = input.color;
	output.Color.a = _FUR_OFFSET;
	
    // 计算纹理坐标
    #if _FUR_ON
	    output.uv.xy = input.texcoord0.xy;
		output.uv.zw = input.texcoord0.xy * _FurNoiseMap_ST.xy + _FurNoiseMap_ST.zw;
	
		//毛发朝向
		float4 furFlowMapValue = SAMPLE_TEXTURE2D_LOD(_FurFlowMap, sampler_FurFlowMap, input.texcoord0.xy * _FurFlowMap_ST.xy + _FurFlowMap_ST.zw, 0);
		float2 furDirection_xy =  furFlowMapValue.xy * 2.0f - 1.0f;
		float furDirection_z = max(1.0e-16, sqrt(1.0f - saturate(dot(furDirection_xy, furDirection_xy))));

		float3 bitangentOS = normalize(cross(input.normal.xyz, input.tangentOS.xyz)) * input.tangentOS.w;
		float3 furDirection = normalize(mul(float3(furDirection_xy, furDirection_z), float3x3(input.tangentOS.xyz, bitangentOS, input.normal.xyz)));

		//卷毛设置
		half curlyFurWeight = 1.0h - _FUR_OFFSET;
		curlyFurWeight = pow(curlyFurWeight, _CurlyFurRange);
		curlyFurWeight = 1.0h - curlyFurWeight;
	
		half furFlowMapIntensity = lerp(_FurFlowMapIntensity, 0.0h, curlyFurWeight);

		//减弱根部毛发受朝向影响强度
		half rootFurWeight = smoothstep(_RootFurRange, _RootFurRange + lerp(0.0h, 1.5h, saturate(_RootFurRange * 100.0h)), _FUR_OFFSET);
		furFlowMapIntensity = lerp(0.0h, furFlowMapIntensity, rootFurWeight);
	
		furDirection = normalize(lerp(input.normal, furDirection, furFlowMapIntensity));

		float3 direction = lerp(furDirection, _Gravity.xyz * _Gravity.w + furDirection * (1 - _Gravity.w), _FUR_OFFSET);

		//毛发遮罩
		float3 furPosition = direction;
		furPosition *= _FUR_OFFSET;
		furPosition *= _FurLength;
		furPosition *= furFlowMapValue.w;
	
		float3 newPosition = input.vertex.xyz + furPosition;
		//half3 p = input.vertex.xyz + input.normal * _FurLength * _FUR_OFFSET * input.color.a * min(1 + length(dis) * _LengthByWind, 1.5f);

		//正常坐标计算
		VertexPositionInputs vertexInput = GetVertexPositionInputs(newPosition);

		VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
		
		output.positionCS = vertexInput.positionCS;
		output.positionWS.xyz = vertexInput.positionWS;
		output.normalWS.xyz = vertexNormalInput.normalWS;
		output.tangentWS.xyz = vertexNormalInput.tangentWS;
		output.bitangentWS.xyz = vertexNormalInput.bitangentWS;
	
		output.normalWS.w = furFlowMapValue.w;

		//FlowDotView
		output.newNormalWS.xyz = TransformObjectToWorldDir(furDirection, false);
		output.newNormalWS.w = 0.0f;

		//原始毛发朝向
		float3 furDirectionWS = mul(float3(furDirection_xy, furDirection_z), float3x3(output.tangentWS.xyz, output.bitangentWS.xyz, output.normalWS.xyz));
		output.tangentWS.w = furDirectionWS.x;
		output.bitangentWS.w = furDirectionWS.y;
		output.newNormalWS.w = furDirectionWS.z;
	
	#else
		VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);
		VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
		output.positionCS = vertexInput.positionCS;
		output.positionWS.xyz = vertexInput.positionWS;
		output.normalWS.xyz = vertexNormalInput.normalWS;
		output.tangentWS.xyz = vertexNormalInput.tangentWS;
		output.bitangentWS.xyz = vertexNormalInput.bitangentWS;
		output.uv.xy = input.texcoord0;
		output.normalWS.w = 1.0f;
		output.newNormalWS = 1.0f;
	#endif
	output.screenPos = ComputeScreenPos(output.positionCS);
	output.positionWS.w = ComputeFogFactor(output.positionCS.z);
	output.uv2.xy = input.texcoord1;
	output.uv2.zw = input.texcoord2;
	
    return output;
}

//============================================Houdini毛发==============================================
Varyings vert_fur_Houdini(Attributes input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
	
	output.Color = input.color;
	half FUR_OFFSET = input.color.a;
	
    // 计算纹理坐标
	#if _FUR_ON
	    output.uv.xy = input.texcoord0.xy;
		output.uv.zw = input.texcoord0.xy * _FurNoiseMap_ST.xy + _FurNoiseMap_ST.zw;
	
		//毛发朝向
		float4 furFlowMapValue = SAMPLE_TEXTURE2D_LOD(_FurFlowMap, sampler_FurFlowMap, input.texcoord0.xy * _FurFlowMap_ST.xy + _FurFlowMap_ST.zw, 0);
		float2 furDirection_xy =  furFlowMapValue.xy * 2.0f - 1.0f;
		float furDirection_z = max(1.0e-16, sqrt(1.0f - saturate(dot(furDirection_xy, furDirection_xy))));

		float3 bitangentOS = normalize(cross(input.normal.xyz, input.tangentOS.xyz)) * input.tangentOS.w;
		float3 furDirection = normalize(mul(float3(furDirection_xy, furDirection_z), float3x3(input.tangentOS.xyz, bitangentOS, input.normal.xyz)));

		//卷毛设置
		half curlyFurWeight = 1.0h - FUR_OFFSET;
		curlyFurWeight = pow(curlyFurWeight, _CurlyFurRange);
		curlyFurWeight = 1.0h - curlyFurWeight;
	
		half furFlowMapIntensity = lerp(_FurFlowMapIntensity, 0.0h, curlyFurWeight);

		//减弱根部毛发受朝向影响强度
		half rootFurWeight = smoothstep(_RootFurRange, _RootFurRange + lerp(0.0h, 1.5h, saturate(_RootFurRange * 100.0h)), FUR_OFFSET);
		furFlowMapIntensity = lerp(0.0h, furFlowMapIntensity, rootFurWeight);
	
		furDirection = normalize(lerp(input.normal, furDirection, furFlowMapIntensity));

		float3 direction = lerp(furDirection, _Gravity.xyz * _Gravity.w + furDirection * (1 - _Gravity.w), FUR_OFFSET);

		//毛发遮罩
		float3 furPosition = direction;
		furPosition *= FUR_OFFSET;
		furPosition *= _FurLength;
		furPosition *= furFlowMapValue.w;
	
		float3 newPosition = input.vertex.xyz + furPosition;
		//half3 p = input.vertex.xyz + input.normal * _FurLength * FUR_OFFSET * input.color.a * min(1 + length(dis) * _LengthByWind, 1.5f);

		//正常坐标计算
		VertexPositionInputs vertexInput = GetVertexPositionInputs(newPosition);

		VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
		
		output.positionCS = vertexInput.positionCS;
		output.positionWS.xyz = vertexInput.positionWS;
		output.normalWS.xyz = vertexNormalInput.normalWS;
		output.tangentWS.xyz = vertexNormalInput.tangentWS;
		output.bitangentWS.xyz = vertexNormalInput.bitangentWS;
	
		output.normalWS.w = furFlowMapValue.w;

		//FlowDotView
		output.newNormalWS.xyz = TransformObjectToWorldDir(furDirection, false);
		output.newNormalWS.w = 0.0f;

		//原始毛发朝向
		float3 furDirectionWS = mul(float3(furDirection_xy, furDirection_z), float3x3(output.tangentWS.xyz, output.bitangentWS.xyz, output.normalWS.xyz));
		output.tangentWS.w = furDirectionWS.x;
		output.bitangentWS.w = furDirectionWS.y;
		output.newNormalWS.w = furDirectionWS.z;
	
	#else
		VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);
		output.positionCS = vertexInput.positionCS;
		output.uv.xy = input.texcoord0;
		output.normalWS.w = 1.0f;
	
		output.newNormalWS = 1.0f;
	#endif
	output.screenPos = ComputeScreenPos(output.positionCS);
	output.positionWS.w = ComputeFogFactor(output.positionCS.z);
	output.uv2.xy = input.texcoord1;
	output.uv2.zw = input.texcoord2;
	
    return output;
}
//====================================================================================================

//=============================================合批毛发=================================================
struct AttributesShell
{ 
	uint vertexID : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

ByteAddressBuffer _DeformedData;
ByteAddressBuffer _StaticData;

Varyings vert_fur_Deformed(AttributesShell input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
	
	float3 positionOS = GetDeformedData_Position(_DeformedData, input.vertexID);
	float3 normalOS = GetDeformedData_Normal(_DeformedData, input.vertexID);
	float4 tangentOS = GetDeformedData_Tangent(_DeformedData, input.vertexID);
	float2 texcoord = GetStaticData_TexCoord0(_StaticData, input.vertexID);
	float2 texcoord1 = GetStaticData_TexCoord1(_StaticData, input.vertexID);
	float2 texcoord2 = GetStaticData_TexCoord2(_StaticData, input.vertexID);
	half FUR_OFFSET = input.instanceID / _FUR_NUM;
	output.Color.a = FUR_OFFSET;//这里顶点色xyz通道还没拿
	
	
    // 计算纹理坐标
    #if _FUR_ON
		output.uv.xy = texcoord.xy;
		output.uv.zw = texcoord.xy * _FurNoiseMap_ST.xy + _FurNoiseMap_ST.zw;
	
		//毛发朝向
		float4 furFlowMapValue = SAMPLE_TEXTURE2D_LOD(_FurFlowMap, sampler_FurFlowMap, texcoord.xy * _FurFlowMap_ST.xy + _FurFlowMap_ST.zw, 0);
		float2 furDirection_xy =  furFlowMapValue.xy * 2.0f - 1.0f;
		float furDirection_z = max(1.0e-16, sqrt(1.0f - saturate(dot(furDirection_xy, furDirection_xy))));

		float3 bitangentOS = normalize(cross(normalOS.xyz, tangentOS.xyz)) * tangentOS.w;
		float3 furDirection = normalize(mul(float3(furDirection_xy, furDirection_z), float3x3(tangentOS.xyz, bitangentOS, normalOS.xyz)));

		//卷毛设置
		half curlyFurWeight = 1.0h - FUR_OFFSET;
		curlyFurWeight = pow(curlyFurWeight, _CurlyFurRange);
		curlyFurWeight = 1.0h - curlyFurWeight;
	
		half furFlowMapIntensity = lerp(_FurFlowMapIntensity, 0.0h, curlyFurWeight);

		//减弱根部毛发受朝向影响强度
		half rootFurWeight = smoothstep(_RootFurRange, _RootFurRange + lerp(0.0h, 1.5h, saturate(_RootFurRange * 100.0h)), FUR_OFFSET);
		furFlowMapIntensity = lerp(0.0h, furFlowMapIntensity, rootFurWeight);
	
		furDirection = normalize(lerp(normalOS, furDirection, furFlowMapIntensity));

		float3 direction = lerp(furDirection, _Gravity.xyz * _Gravity.w + furDirection * (1 - _Gravity.w), FUR_OFFSET);

		//毛发遮罩
		float3 furPosition = direction;
		furPosition *= FUR_OFFSET;
		furPosition *= _FurLength;
		furPosition *= furFlowMapValue.w;
	
		float3 newPosition = positionOS.xyz + furPosition;
		//half3 p = vertex.xyz + normal * _FurLength * FUR_OFFSET * color.a * min(1 + length(dis) * _LengthByWind, 1.5f);

		//正常坐标计算
		VertexPositionInputs vertexInput = GetVertexPositionInputs(newPosition);

		VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(normalOS, tangentOS);
		
		output.positionCS = vertexInput.positionCS;
		output.positionWS.xyz = vertexInput.positionWS;
		output.normalWS.xyz = vertexNormalInput.normalWS;
		output.tangentWS.xyz = vertexNormalInput.tangentWS;
		output.bitangentWS.xyz = vertexNormalInput.bitangentWS;
	
		output.normalWS.w = furFlowMapValue.w;

		//FlowDotView
		output.newNormalWS.xyz = TransformObjectToWorldDir(furDirection, false);
		output.newNormalWS.w = 0.0f;

		//原始毛发朝向
		float3 furDirectionWS = mul(float3(furDirection_xy, furDirection_z), float3x3(output.tangentWS.xyz, output.bitangentWS.xyz, output.normalWS.xyz));
		output.tangentWS.w = furDirectionWS.x;
		output.bitangentWS.w = furDirectionWS.y;
		output.newNormalWS.w = furDirectionWS.z;
	
	#else
		VertexPositionInputs vertexInput = GetVertexPositionInputs(positionOS.xyz);
		output.positionCS = vertexInput.positionCS;
		output.uv.xy = texcoord;
		output.uv.zw = texcoord.xy * _FurNoiseMap_ST.xy + _FurNoiseMap_ST.zw;
		output.normalWS.w = 1.0f;
	
		output.newNormalWS = 1.0f;
	#endif
	
	output.screenPos = ComputeScreenPos(output.positionCS);
	output.positionWS.w = ComputeFogFactor(output.positionCS.z);
	output.uv2.xy = texcoord1;
	output.uv2.zw = texcoord2;
    return output;
}
//====================================================================================================

// 计算高光
float StrandSpecular(float3 T, float3 V, float3 L, float exponent) {
	float3 H = normalize(L + V);
	float dotTH = dot(T, H);
	float sinTH = sqrt(1 - dotTH * dotTH);
	float dirAtten = smoothstep(-1, 0, dotTH);
	return dirAtten * pow(sinTH, exponent);
}

void InitializeInputData(Varyings input,half3 normalTS, out InputData inputData)
{
	inputData = (InputData)0;
	inputData.positionWS = input.positionWS;
        
	#if defined(_NORMALMAP)
	//float sgn = input.tangentWS.w;      // should be either +1 or -1
	inputData.normalWS = TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
	#else
	inputData.normalWS = input.normalWS;
	#endif
	
	inputData.normalWS = normalize(inputData.normalWS);
	
	// #if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
		inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
	// #else
	// 	inputData.shadowCoord = float4(0, 0, 0, 0);
	// #endif
    
	float3 viewDirWS = GetCameraPositionWS().xyz - input.positionWS.xyz;
	viewDirWS = SafeNormalize(viewDirWS);
	inputData.viewDirectionWS = viewDirWS;
	inputData.bakedGI = SampleSH(inputData.normalWS);

	//适配场景sh
	//inputData.bakedGI.rbg = input.vertexSH.rbg;
	half3 ShTint = lerp(unity_AmbientGround, unity_AmbientSky, saturate((inputData.normalWS.y + 1.0h) * 0.5h));
	ShTint = lerp(unity_AmbientEquator, ShTint, saturate(abs(inputData.normalWS.y)));
	inputData.bakedGI.rgb *= ShTint;
	//inputData.bakedGI.rbg *= _SHExposure;

	inputData.normalizedScreenSpaceUV = input.screenPos.xy / input.screenPos.w;
}

half LinearStep(half minValue, half maxValue, half In) // shadowThreshold - shadowSmooth, shadowThreshold + shadowSmooth, radiance
{
	return saturate((In-minValue) / (maxValue - minValue));
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

half3 StylizedRadiance(half halflambert, half shadowThreshold, half shadowSmooth, half3 shadowColor, half3 lightColor)
{
	shadowSmooth *= 0.5;
	half radiance = LinearStep(shadowThreshold - shadowSmooth, shadowThreshold + shadowSmooth, halflambert);
	half3 diffuse = lerp(shadowColor.rgb, lightColor.rgb, radiance);
    
	return diffuse;
}

inline void  GetMainDiffuseColor( half radiance,half LightShadow,out half3 diffuse)
{
    diffuse = StylizedRadiance(radiance, _RampThreshold, _RampSmoothing, _SColor.rgb, _HColor.rgb);
}

/*half3 EffectInout(half3 color,half3 normalWS,half3 viewDirectionWS,half2 uv)
{
	#if _WEAKNESS_ON
	half4 effectMask=SAMPLE_TEXTURE2D(_EffectsMaskTex,sampler_EffectsMaskTex,uv);
	#endif
	
	#if _DISSLOVE_ON
	Disslove(uv.xy,_DissloveEdgeLength,_DissloveThreshold,_DissloveEdgeColor,color.rgb);
	#endif
	color.rgb+=Fresnel(normalWS,viewDirectionWS,_FresnelF0,_FresnelColor);
	#if _WEAKNESS_ON
	Weakness(normalWS,viewDirectionWS,effectMask.r,color);
	#endif

	
	return color;
}*/

inline void GetFurDiffuseColor(half3 albedo, half3 drakColor, half furLengthMask, half FlowDotView, inout half radiance, half baseLayerAO, out half3 diffuseColor)
{//计算毛发阴影颜色
	//========阴影========
	half3 currentDiffuseColor = 0;

	currentDiffuseColor = lerp(drakColor, _HColor.rgb, radiance);
	currentDiffuseColor = lerp(currentDiffuseColor, currentDiffuseColor * albedo, _DiffuseBlendAlbedo);

	//阴影AO
	half diffuseBlendAOWeight = radiance * 0.5h + 0.5h;
	diffuseBlendAOWeight = lerp(0.0h, _DiffuseBlendAO, diffuseBlendAOWeight);
	diffuseBlendAOWeight *= furLengthMask;//毛发长短
	
	half currentDiffuseAO = baseLayerAO;
	
	#if _AODEEPEN
	currentDiffuseAO = lerp(1.0h, currentDiffuseAO, FlowDotView);//避免在正对着毛发朝向时，毛发根部会有一圈黑色AO的问题
	diffuseBlendAOWeight *= FlowDotView;//避免在正对着毛发朝向时，毛发根部会亮起来
	#else
	currentDiffuseAO = lerp(currentDiffuseAO, 1.0h, FlowDotView);//避免在正对着毛发朝向时，毛发根部会有一圈黑色AO的问题
	diffuseBlendAOWeight = lerp(diffuseBlendAOWeight, 0.0h, FlowDotView);//避免在正对着毛发朝向时，毛发根部会有一圈黑色AO的问题
	#endif
	
	currentDiffuseAO = lerp(1.0h, currentDiffuseAO * 1.5h, diffuseBlendAOWeight);
	
	currentDiffuseColor *= currentDiffuseAO;
	radiance *= baseLayerAO;//用于后续高光计算

	diffuseColor = currentDiffuseColor;
}

inline void GetFurSpecularColor(half3 albedo, half furLengthMask, half NdotH, half FlowDotView, half TdotH, half radiance, out half3 specularColor)
{//计算毛发高光颜色
	//==============简化版PBR高光==============
	half roughness = 1 - _FurSmoothness;
	roughness *= roughness;
            	
	roughness += HALF_MIN_SQRT;
	roughness = saturate(roughness);

	half OneMinusNoHSqr = 1.0h - NdotH * NdotH;
    
	half n = NdotH * roughness;
	half p = roughness / (OneMinusNoHSqr + n * n);
	half specularTerm = p * p;
	specularTerm *= 0.45h;//强度与标准GGX校正

	half3 currentSpecularColor = lerp(_FurSpecularColor.rgb, _FurSpecularColor.rgb * albedo, _FurSpecularColorBlender);
	currentSpecularColor *= specularTerm;
	currentSpecularColor *= _FurSpecularBrightness;
	currentSpecularColor *= radiance;
	currentSpecularColor *= lerp(1.0h, furLengthMask, _FurSpecularBlendLength);//毛发长短

	#if _AODEEPEN
	currentSpecularColor *= lerp(1.0h, FlowDotView, _FurSpecularRootAOIntensity);//避免在正对着毛发朝向时，毛发根部会亮起来
	#else
	currentSpecularColor *= 1.0h - smoothstep(1.0h - _FurSpecularRootAOIntensity, 1.0, FlowDotView);//避免在正对着毛发朝向时，毛发根部会亮起来
	#endif

	//========各向异性高光========
	half anisotropyNdotH = sqrt(1.0h - TdotH * TdotH);
	anisotropyNdotH = pow(anisotropyNdotH, _FurAnisotropySmoothness * 500.0h);

	anisotropyNdotH *= _FurAnisotropyBrightness;
	anisotropyNdotH *= radiance;
	anisotropyNdotH *= lerp(1.0h, furLengthMask, _FurSpecularBlendLength);//毛发长短
	
	anisotropyNdotH = saturate(anisotropyNdotH);

	specularColor = currentSpecularColor + anisotropyNdotH;
}

//剔除ShaderLibrary引用文件，解耦出来独立毛发
// inline void GetFurAddLightColor(half3 albedo, half furLengthMask, half FlowDotView, half baseLayerAO, half3 normalWS, half3 furDirNormalWS, AdditionalLightData addLightData, InputData inputData, half4 shadowMask, AmbientOcclusionFactor aoFactor, uint meshRenderingLayers, out half3 addLightColor)
// {//算毛发多光源颜色
// 	half3 additionalLightsColor = 0.0;
//
// 	#if defined(_ADDITIONAL_LIGHTS)
// 		uint pixelLightCount = GetAdditionalLightsCount();
// 	
// 		#if USE_FORWARD_PLUS
// 		[loop] for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++)
// 		{
// 			FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK
// 	    
// 			Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
// 	    
// 			#ifdef _LIGHT_LAYERS
// 			if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
// 				#endif
// 			{
// 				// additionalLightsColor += LightingPhysicallyBased(brdfData, brdfDataClearCoat, light,
// 				//                                                               inputData.normalWS, inputData.viewDirectionWS,
// 				//                                                               surfaceData.clearCoatMask, specularHighlightsOff);
// 				//这里自己实现对应的多盏平行光计算逻辑
// 				additionalLightsColor += 0.0h;
// 			}
// 		}
// 		#endif
// 		LIGHT_LOOP_BEGIN(pixelLightCount)
// 			Light light = GetAdditionalLight(lightIndex, inputData, shadowMask, aoFactor);
// 		float index = 0.0;
// 		#ifdef _LIGHT_LAYERS
// 		if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
// 		#endif
// 		{
// 			//向量计算
// 			half3 halfDir = normalize(inputData.viewDirectionWS + light.direction);
// 			half NdotH = saturate(dot(furDirNormalWS, halfDir));
// 			half TdotH = dot(furDirNormalWS, normalize(-inputData.viewDirectionWS + light.direction));//各向异性高光
//
// 			//========各向异性阴影========
// 			half TdotL = dot(furDirNormalWS, light.direction);
// 			half anisotropyNdotL = sqrt(1.0h - TdotL * TdotL);
// 			anisotropyNdotL = 1 - anisotropyNdotL;
// 			anisotropyNdotL *= sign(TdotL);
//
// 			half anisotropyHalfLambert = anisotropyNdotL * 0.5h + 0.5h;
// 			anisotropyHalfLambert = anisotropyHalfLambert * (light.shadowAttenuation * 0.5 + 0.5);
// 			anisotropyHalfLambert = LinearStep(addLightData.multipleLightRange, addLightData.multipleLightRange + addLightData.multipleLightSoftness, anisotropyHalfLambert);
// 			
// 			half radiance = saturate(anisotropyHalfLambert);
// 			// radiance *= light.shadowAttenuation;
//
// 			//阴影计算
// 			half3 diffuseColor = 0.0h;
// 			GetFurDiffuseColor(albedo, 0.0h, furLengthMask, FlowDotView, radiance, baseLayerAO, diffuseColor);
//
// 			//高光计算
// 			half3 specularColor = 0.0h;
// 			GetFurSpecularColor(albedo, furLengthMask, NdotH, FlowDotView, TdotH, radiance, specularColor);
//
// 			//多光源颜色计算
// 			half3 currentLightColor = light.color * light.distanceAttenuation;
// 			
// 			//最终color的阈值不超1
// 			half maxRGBValue = max(currentLightColor.r, max(currentLightColor.g, currentLightColor.b));
// 			maxRGBValue /= addLightData.multipleLightBrightness; 
// 			currentLightColor = maxRGBValue > 1 ? (currentLightColor / maxRGBValue) : currentLightColor;
// 			
//
// 			half3 finalColor = albedo * diffuseColor;
// 			finalColor += specularColor;
// 			finalColor *= currentLightColor;
//
// 			additionalLightsColor += finalColor;
// 		}
// 		LIGHT_LOOP_END
// 	#endif
//
// 	addLightColor = additionalLightsColor;
// }

half4 frag_fur(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
	
	//Dither——剔除ShaderLibrary引用文件，解耦出来独立毛发
	//DitherThreshold(input.screenPos,input.positionCS.xy,_DitherTimer);

	half4 newNormalWS_inputData = input.newNormalWS;
	half4 tangentWS_inputData = input.tangentWS;
	half4 bitangentWS_inputData = input.bitangentWS;
	half4 normalWS_inputData = input.normalWS;

	FurLitBaseData baseData;
	InitializeFragmentData(input.uv.xy * _BaseMap_ST.xy + _BaseMap_ST.zw, normalWS_inputData.w,input.Color.a, baseData);
	
	InputData inputData;
	InitializeInputData(input, baseData.normalTS.xyz, inputData);

	half4 shadowMask = unity_ProbesOcclusion;
	Light mainLight;
	mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);

	//——剔除ShaderLibrary引用文件，解耦出来独立毛发
	// AdditionalLightData addLightData;
	// GetAdditionalLightData_2024(mainLight,_StoryLightDir,addLightData);

	half atten = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
	atten = LerpWhiteTo(atten, _ShadowIntensity);
	

	//========毛发形状========
	half furNoise = SampleTexture(input.uv.zw, TEXTURE2D_ARGS(_FurNoiseMap, sampler_FurNoiseMap)).r;
	furNoise = lerp(0.5h, furNoise, lerp(1.0h, _FurContrast, baseData.alpha));

	half furShape = furNoise;
	furShape -= lerp(input.Color.a, input.Color.a * input.Color.a, _FurDensity);
	furShape = saturate(furShape);

	
	//========向量准备========
	half3 normalWS = MergeTexUnpackNormalRG(SampleTexture(input.uv.xy, TEXTURE2D_ARGS(_MaskMap, sampler_MaskMap)), _BumpScale);
	normalWS = TransformTangentToWorldDir(normalWS, half3x3(tangentWS_inputData.xyz, bitangentWS_inputData.xyz, normalWS_inputData.xyz), true);

	normalWS_inputData.xyz = normalize(normalWS_inputData.xyz);
	
	half3 furDirNormalWS = normalize(newNormalWS_inputData.xyz);
	half3 furDirectionWS = normalize(half3(tangentWS_inputData.w, bitangentWS_inputData.w, newNormalWS_inputData.w));
	

	//========光照数据准备========
	// half ndl = dot(inputData.normalWS, mainLight.direction);
    half NdotL = dot(normalWS, mainLight.direction);
    half NdotV = saturate(dot(normalWS, inputData.viewDirectionWS));
	
	half3 halfDir = normalize(inputData.viewDirectionWS + mainLight.direction);
	half NdotH = saturate(dot(normalWS, halfDir));
	half NdotH1 = saturate(dot(furDirNormalWS, halfDir));

	half halfLambert = NdotL * 0.5 + 0.5;
	
	half TdotH = dot(furDirNormalWS, normalize(-inputData.viewDirectionWS + mainLight.direction));//各向异性高光

	//毛发AO遮罩，避免观察方向与毛发朝向夹角为0时的效果奇怪的问题
	half FlowDotView = 1.0;

	#if _AODEEPEN
	FlowDotView = dot(furDirectionWS, inputData.viewDirectionWS);
	half angle = acos(FlowDotView);
	angle *= 0.31831f;
	angle = LinearStep(0.15h, 0.45h, angle);

	FlowDotView = saturate(angle);
	#else
	FlowDotView = dot(furDirNormalWS, inputData.viewDirectionWS);
	FlowDotView = FlowDotView * 0.5h + 0.5h;
	#endif

	
	//========各向异性阴影========
	half TdotL = dot(furDirNormalWS, mainLight.direction);
	half anisotropyNdotL = sqrt(1.0h - TdotL * TdotL);
	anisotropyNdotL = 1.0h - anisotropyNdotL;
	anisotropyNdotL *= sign(TdotL);
	
	half anisotropyHalfLambert = anisotropyNdotL * 0.5 + 0.5;
	halfLambert = saturate(lerp(halfLambert, anisotropyHalfLambert, _AnisotropyDiffuse));

	
	//========radiance========
	half radiance = LinearStep(_RampThreshold, _RampThreshold + _RampSmoothing, halfLambert);
	radiance *= atten;

	
	//========AO========
	half aoWeight = saturate(lerp(1.0h, input.Color.a, _FurAOIntensity));//_FUR_OFFSET:[0, 1]

	half aoFresnelMask = pow(NdotV, _FurAORange);
	aoFresnelMask = aoFresnelMask * 0.28h;
	aoWeight = lerp(aoWeight, 1.0h, aoFresnelMask);
	
	half baseLayerAO = aoWeight;//用于阴影和高光AO
	
	
	#if _AODEEPEN
	aoWeight *= lerp(LerpWhiteTo(halfLambert, aoWeight * 1.2h), aoWeight, radiance);//避免背光面体积感、细节过强而有漏光、油腻的感觉
	#else
	aoWeight = lerp(lerp(0.5h, 0.0h, halfLambert), aoWeight, radiance);//避免背光面体积感、细节过强而有漏光、油腻的感觉
    #endif

	aoWeight *= normalWS_inputData.w;//毛发长短

	half3 furAO = lerp(_FurAOColor.rgb, _FurAOColor.rgb * baseData.albedo, _FurAOBlendAlbedo);
	furAO = lerp(furAO, 1.0h, aoWeight);

	
	//========阴影颜色========
	half3 diffuseColor = 0.0h;
	GetFurDiffuseColor(baseData.albedo, _SColor.rgb, normalWS_inputData.w, FlowDotView, radiance, baseLayerAO, diffuseColor);
	//ChangeDiffuseColorOfTod(baseData.albedo, addLightData, diffuseColor);//角色阴影适配TOD颜色——剔除ShaderLibrary引用文件，解耦出来独立毛发

	//========高光颜色========
	half3 specularColor = 0.0h;
	GetFurSpecularColor(baseData.albedo, normalWS_inputData.w, NdotH1, FlowDotView, TdotH, radiance, specularColor);

	//========多光源颜色========
	half3 addLightColor = 0.0h;
	
	//支持 SSAO 和 RenderingLayer
	AmbientOcclusionFactor aoFactor = CreateAmbientOcclusionFactor(inputData.normalizedScreenSpaceUV, 1/*surfData.occlusion*/);
	uint meshRenderingLayers = GetMeshRenderingLayer();

	//剔除ShaderLibrary引用文件，解耦出来独立毛发
	//GetFurAddLightColor(baseData.albedo, normalWS_inputData.w, FlowDotView, baseLayerAO, normalWS, furDirNormalWS, addLightData, inputData, shadowMask, aoFactor, meshRenderingLayers, addLightColor);
	
	//========边缘光========
	half rim = 1.0h - saturate(dot(inputData.viewDirectionWS, normalWS_inputData));
	half3 rimColor = lerp(_SideLightColor.rgb, _SideLightColor.rgb * baseData.albedo, _SideLightBlendAlbedo);
	rimColor *= pow(rim, _SideLightScale * 2.0h) * _SideLightPow;
	rimColor *= halfLambert;//让透光过渡自然一点，用halfLambert而不是radiance
	rimColor *= radiance * 0.5h + 0.5h;

	
	//========gi========
	inputData.bakedGI = SampleSH(furDirNormalWS);
	
	//适配场景sh
	half3 ShTint = lerp(unity_AmbientGround, unity_AmbientSky, saturate((furDirNormalWS.y + 1.0h) * 0.5h));
	ShTint = lerp(unity_AmbientEquator, ShTint, saturate(abs(furDirNormalWS.y)));
	inputData.bakedGI.rgb *= ShTint;
	
	//颜色——剔除ShaderLibrary引用文件，解耦出来独立毛发
	// half3 finalBakeGI = lerp(inputData.bakedGI * addLightData.bakeAmbientIntensity * _SHExposure, addLightData.ambientColor.rgb, addLightData.ambientColor.a);
	// half3 giColor = finalBakeGI * baseData.albedo;//input.vertexLight * baseData.albedo;

	half3 giColor = inputData.bakedGI * baseData.albedo;//input.vertexLight * baseData.albedo;
	giColor *= furAO;

	#if _FUR_ON
		half3 finalColor = baseData.albedo * diffuseColor;
		finalColor += specularColor;
		finalColor *= mainLight.color.rgb;
		finalColor += giColor;
		finalColor += addLightColor;
		finalColor += rimColor;
	
		half alpha = furShape;

	// finalColor = atten;
	
	#else
		// Light mainLight;
		// mainLight = GetMainLight();
		//
		// AdditionalLightData addLightData;
		// GetAdditionalLightData(mainLight, addLightData);
	
		half3 finalColor = SampleTexture(input.uv,TEXTURE2D_ARGS(_BaseMap,sampler_BaseMap));
		finalColor *= diffuseColor;
		finalColor *= mainLight.color.rgb;
		
		half alpha = 1.0h;
	#endif

	#if defined(_ALPHATEST_ON)
	clip(alpha - _Cutoff);
	#else
	clip(alpha - 0.001h);
	#endif
	
	//特效接口——剔除ShaderLibrary引用文件，解耦出来独立毛发
	// DissloveData dissloveData;
	// dissloveData = (DissloveData)0;
	// dissloveData.DissloveThreshold = _DissloveThreshold;
	// dissloveData.DissloveEdgeLength = _DissloveEdgeLength;
	// dissloveData.DissloveEdgeColor = _DissloveEdgeColor;
	//
	// FresnelData fresnelData;
	// fresnelData = (FresnelData)0;
	// fresnelData.FresnelF0 = _FresnelF0;
	// fresnelData.FresnelColor = _FresnelColor;
	// 	
	// //finalColor.rgb=EffectInout(finalColor,input.normalWS,inputData.viewDirectionWS,input.uv);
	// finalColor.rgb = EffectInout_Fur(TEXTURE2D_ARGS(_EffectsMaskTex, sampler_EffectsMaskTex),finalColor,inputData.positionWS,normalWS_inputData,inputData.viewDirectionWS,input.uv, dissloveData, fresnelData);
	//
	//
	// finalColor = HackColor(finalColor);
	
	finalColor.rgb = MixFog(finalColor, input.positionWS.w);

	//毛发半透数值计算
	alpha = alpha + lerp(1.0h, _FurAlpha, baseData.alpha);
	alpha = saturate(alpha);
	

    // return half4(test.xxx, alpha);
    // return half4((anisotropyNdotL).xxx, alpha);
	// return half4(addLightColor, alpha);
    return half4(finalColor, alpha);
}


Varyings Vertex(Attributes input)
{
	return vert_fur(input);
}


half4 Fragment(Varyings input) : SV_TARGET{
	
	return frag_fur(input);
}
float4 DepthOnlyFragment (Varyings input) : SV_Target{
	//Dither——剔除ShaderLibrary引用文件，解耦出来独立毛发
	//DitherThreshold(input.screenPos,input.positionCS.xy,_DitherTimer);
	return 0;
}
void DepthNormalsPassFragment(
		   Varyings input
		   , out half4 outNormalWS : SV_Target
	   #ifdef _WRITE_RENDERING_LAYERS
		   , out float4 outRenderingLayers : SV_Target1
	   #endif
	   )
{
	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
	//Dither——剔除ShaderLibrary引用文件，解耦出来独立毛发
	//DitherThreshold(input.screenPos,input.positionCS.xy,_DitherTimer);

            	
	half3 normal = input.normalWS;

	outNormalWS = half4(normal,1);
	#ifdef _WRITE_RENDERING_LAYERS
	uint renderingLayers = GetMeshRenderingLayer();
	outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
	#endif
                
}

#endif
