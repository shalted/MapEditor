#ifndef MODELCOMPUTEFOGLIBRARY
#define MODELCOMPUTEFOGLIBRARY

#include "UnityCg.cginc"
#pragma multi_compile _ _MODELFOG

float4  _FogPosAndRange,//X：近裁剪面；Y：远裁剪面；Z：雾区边缘位置；W：雾区边缘过渡范围
        _HeightFogValue;//X：高度雾开始位置；Y高度雾结束位置；Z：高度雾低处亮度；W：高度雾高处亮度

half4 _NearFogColor,//XYZ：近处雾颜色；W：远处雾效衰减位置
	  _FarFogColor;//XYZ：远处雾颜色；W：远处雾强度

sampler2D _CloudMap;
float4 _CloudMap_ST;
float4 _CloudMove;

void ComputeCloudShadow(float3 positionWS, inout half3 finalColor)
{
	float2 uv = float2(positionWS.xz);
	uv = TRANSFORM_TEX(uv, _CloudMap) + _CloudMove.xy * fmod(_Time.x, _CloudMove.z);
	half4 cloudColor = tex2D(_CloudMap, uv);
	finalColor = lerp(finalColor, 0, cloudColor.r);
}

void ComputeModelFog(float positionCS_z, float positionWS_y, inout half3 finalColor)
{
	#if _MODELFOG
	half3 nearFogColor = _NearFogColor.rgb;
	half3 farFogColor = _FarFogColor.rgb;

	// #if UNITY_COLORSPACE_GAMMA
	// // nearFogColor = GammaToLinearSpace(nearFogColor);
	// // farFogColor = GammaToLinearSpace(farFogColor);
	// #endif

	//深度值映射
	// #if UNITY_REVERSED_Z
	// 	float fogX = -1 + _FogPosAndRange.y / _FogPosAndRange.x;
	// 	float fogY = 1;
	// #else
	// 	float farDivNear = _FogPosAndRange.y / _FogPosAndRange.x;
	// 	float fogX = 1 - farDivNear;
	// 	float fogY = farDivNear;
	// #endif
	                
	// half depth = 1.0 / (fogX * positionCS_z + fogY);//Linear01Depth()
	half depth = Linear01Depth(positionCS_z);//Linear01Depth()
            		
	//深度雾颜色
	half fogColorWeight = smoothstep(_FogPosAndRange.x, _FogPosAndRange.y, depth);
	half3 fogColor = lerp(nearFogColor, farFogColor, fogColorWeight);

	//叠加高度雾颜色
	float height = smoothstep(_HeightFogValue.x, _HeightFogValue.y, positionWS_y);
	fogColor = lerp(fogColor * _HeightFogValue.z, fogColor * _HeightFogValue.w, height);

	//雾效遮罩
	half fogMask = smoothstep(_FogPosAndRange.z, _FogPosAndRange.z + _FogPosAndRange.w, depth);
	
	fogMask = lerp(fogMask, _FarFogColor.w, smoothstep(_NearFogColor.w, _NearFogColor.w + 0.2, fogMask));

	#if UNITY_COLORSPACE_GAMMA
	fogColor = LinearToGammaSpace(fogColor);
	fogMask = LinearToGammaSpace(fogMask);
	#endif

	half4 ModelFog = half4(fogColor, fogMask);
	finalColor.rgb = finalColor.rgb * (1 - ModelFog.a) + ModelFog.rgb * ModelFog.a;
	#endif
}

half4 ComputeModelFogWithoutHeightFog(float positionCS_z)
{
	half3 nearFogColor = _NearFogColor.rgb;
	half3 farFogColor = _FarFogColor.rgb;

	// #if UNITY_COLORSPACE_GAMMA
	// nearFogColor = GammaToLinearSpace(nearFogColor);
	// farFogColor = GammaToLinearSpace(farFogColor);
	// #endif
				
	//深度值映射
	// #if UNITY_REVERSED_Z
	// 	float fogX = -1 + _FogPosAndRange.y / _FogPosAndRange.x;
	// 	float fogY = 1;
	// #else
	// 	float farDivNear = _FogPosAndRange.y / _FogPosAndRange.x;
	// 	float fogX = 1 - farDivNear;
	// 	float fogY = farDivNear;
	// #endif
	                
	// half depth = 1.0 / (fogX * positionCS_z + fogY);//Linear01Depth()
	half depth = Linear01Depth(positionCS_z);//Linear01Depth()
            		
	//深度雾颜色
	half fogColorWeight = smoothstep(_FogPosAndRange.x, _FogPosAndRange.y, depth);
	half3 fogColor = lerp(nearFogColor, farFogColor, fogColorWeight);

	//雾效遮罩
	half fogMask = smoothstep(_FogPosAndRange.z, _FogPosAndRange.z + _FogPosAndRange.w, depth);

	fogMask = lerp(fogMask, _FarFogColor.w, smoothstep(_NearFogColor.w, _NearFogColor.w + 0.2, fogMask));

	#if UNITY_COLORSPACE_GAMMA
	fogColor = LinearToGammaSpace(fogColor);
	fogMask = LinearToGammaSpace(fogMask);
	#endif

	return half4(fogColor, fogMask);
}

half ComputeModelFogMask(float positionCS_z)
{
    // #if UNITY_COLORSPACE_GAMMA
    // nearFogColor = GammaToLinearSpace(nearFogColor);
    // farFogColor = GammaToLinearSpace(farFogColor);
    // #endif
				
    //深度值映射
    // #if UNITY_REVERSED_Z
    // 	float fogX = -1 + _FogPosAndRange.y / _FogPosAndRange.x;
    // 	float fogY = 1;
    // #else
    // 	float farDivNear = _FogPosAndRange.y / _FogPosAndRange.x;
    // 	float fogX = 1 - farDivNear;
    // 	float fogY = farDivNear;
    // #endif
    //              
    // half depth = 1.0 / (fogX * positionCS_z + fogY);//Linear01Depth()
    half depth = Linear01Depth(positionCS_z);//Linear01Depth()

    //雾效遮罩
    half fogMask = smoothstep(_FogPosAndRange.z, _FogPosAndRange.z + _FogPosAndRange.w, depth);

	fogMask = lerp(fogMask, _FarFogColor.w, smoothstep(_NearFogColor.w, _NearFogColor.w + 0.1, fogMask));

	#if UNITY_COLORSPACE_GAMMA
	fogMask = LinearToGammaSpace(fogMask);
	#endif

    return fogMask;
}

#endif