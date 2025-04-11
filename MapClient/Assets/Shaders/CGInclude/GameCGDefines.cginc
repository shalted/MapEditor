//*************************************************
//****copyRight LuoYao 2019/08
//Update: Add GAME_DIR_DISSOLUTION 2020/09/25
//*************************************************

#ifndef GAME_CG_DEFINES_H
#define GAME_CG_DEFINES_H

#include "UnityCG.cginc"

static const half3 _GameGreyColor = half3(0.2126, 0.7152, 0.0722);

half3 _GameUnitColor = half3(1, 1, 1); //营地面片颜色

fixed4 _ProceduralColor;
sampler2D _MainTex;
float4 _MainTex_ST;
half4 _Color;

/// 绘制顺序约定:(代码里面有引用，修改的时候记得一起改)
//角色单位		2000	Geometry
//背景的地图	2200	Geometry + 200
//半透明		3000	Transparent


//宏定义说明：
//GAME_GREY 灰度
//GAME_RIM_LIGHT 边缘光
//GAME_DIR_DISSOLUTION 方向性溶解


// 把类似UV的坐标（0~1），转化为clip空间坐标（-1~1），兼容各平台
half4 UVToClipPos(half4 uv) {
	uv.xy = uv.xy * 2 - 1;
	uv.yzw = half3(uv.y * _ProjectionParams.x, 0, 1);
	return uv;
}

float3 SafeNormalize(float3 inVec)
{
    float dp3 = max(0.0001, dot(inVec, inVec));
    return inVec * rsqrt(dp3);
}
float4x4 _PerspectiveTransMatrix = float4x4(
	float4(1, 0, 0, 0),
	float4(0, 1, 0, 0),
	float4(0, 0, 1, 0),
	float4(0, 0, 0, 0)
	);
float4x4 _PerspectiveMatrix;
float4 GetPerspectiveClipPos(float3 posOS, float4 clipPos)
{
    float4x4 mvp = mul(mul(_PerspectiveMatrix, _PerspectiveTransMatrix), mul(unity_MatrixV, unity_ObjectToWorld));
    float4 customClipPos = mul(mvp, float4(posOS, 1));
	float clipZ = clipPos.z / clipPos.w;
	clipPos = float4(customClipPos.xy, customClipPos.w * clipZ,  customClipPos.w);
	return clipPos;
}
float4 GetPerspectiveClipPos(float3 posWS)
{
    float4x4 vp = mul(mul(_PerspectiveMatrix, _PerspectiveTransMatrix), unity_MatrixV);
    float4 customClipPos = mul(vp, float4(posWS, 1));
	return customClipPos;
}
float4 CustomObjectToClipPos(float4 vertex)
{
	float4 clipPos = UnityObjectToClipPos(vertex);
	return clipPos;
}

//方向性溶解
#if GAME_DIR_DISSOLUTION
	uniform sampler2D _DirDissolutionTex;
	fixed4 _DirDissolutionColor;
	float4 _DirDissolutionPlane;
	half4 _DirDissolutionSawtoothParam;

	#define GAME_DIR_DISSOLUTION_COORDS(idx) half diss_dist : TEXCOORD##idx;
	#define GAME_TRANSFER_DIR_DISSOLUTION(o, world_pos) \
		o.diss_dist = dot(world_pos, _DirDissolutionPlane.xyz) + _DirDissolutionPlane.w;
	#define GAME_APPLY_DIR_DISSOLUTION_NO_COLOR(i) \
		fixed4 diss_color = tex2D(_DirDissolutionTex, i.uv.xy);\
		half fade_dist = (diss_color.a - 1) * _DirDissolutionSawtoothParam.y + i.diss_dist;\
		clip(fade_dist);
	#define GAME_APPLY_DIR_DISSOLUTION(i, color) \
		GAME_APPLY_DIR_DISSOLUTION_NO_COLOR(i)\
		half fade_alpha = lerp(_DirDissolutionColor.a, 0, saturate(fade_dist / _DirDissolutionSawtoothParam.x));\
		color.rgb *= lerp(1, _DirDissolutionColor.rgb, fade_alpha);
#else
	#define GAME_DIR_DISSOLUTION_COORDS(idx)
	#define GAME_TRANSFER_DIR_DISSOLUTION(o, world_pos)
	#define GAME_APPLY_DIR_DISSOLUTION_NO_COLOR(i)
	#define GAME_APPLY_DIR_DISSOLUTION(i, color)
#endif

sampler2D _SceneOcclusion;
float4 _SceneOcclusionOffsetAndTiling;
half4 _SceneOcclusionColor;

//inline void SceneOcclusionWithColor(inout half3 mainCol, float3 worldPos)
//{
//	#ifdef _SCENEOCCLUSION
//	float2 souv = worldPos.xy - _SceneOcclusionOffsetAndTiling.xy;
//	souv *= _SceneOcclusionOffsetAndTiling.zw;
//	half mask = tex2D(_SceneOcclusion, souv);
//	mainCol = lerp(_SceneOcclusionColor.xyz, mainCol, max(mask , _SceneOcclusionColor.w));
//	#endif
//}
inline half4 SceneOcclusionWithColor(float3 worldPos)
{
	half4 mainCol = 0;
	#ifdef _SCENEOCCLUSION
	float2 souv = worldPos.xy - _SceneOcclusionOffsetAndTiling.xy;
	souv *= _SceneOcclusionOffsetAndTiling.zw;
	half mask = tex2D(_SceneOcclusion, souv);
	mainCol.rgb = _SceneOcclusionColor.xyz;
	mainCol.a = lerp(1, 0, max(mask , _SceneOcclusionColor.w));
	#endif
	return mainCol;
}

#endif