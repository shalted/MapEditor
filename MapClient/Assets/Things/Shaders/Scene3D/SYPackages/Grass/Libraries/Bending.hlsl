//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA
#include "Common.hlsl"
//Global parameters
float4 _BendMapUV;
sampler2D _BendMap;
half4 _BendMap_TexelSize;
float4 _BendCameraWS;

struct BendSettings
{
	half mask;
	half pushStrength;
	half flattenStrength;
	half perspectiveCorrection;
};

BendSettings PopulateBendSettings(half mask, half pushStrength, half flattenStrength, half perspCorrection)
{
	BendSettings s = (BendSettings)0;

	s.mask = mask;
	s.pushStrength = pushStrength;
	s.flattenStrength = flattenStrength;
	s.perspectiveCorrection = perspCorrection;

	return s;
}

//UV Utilities
float2 BoundsToWorldUV(in float3 wPos, in float4 b)
{
	//return (wPos.xz * b.z) - (b.xy * b.z);
	float2 uv = (wPos.xz - b.xy) * b.z;

	return uv;
}

//Bend map UV
float2 GetBendMapUV(in float3 wPos) {

	return BoundsToWorldUV(wPos, _BendMapUV);
}

//Texture sampling
float4 GetBendVector(float3 wPos)
{
	float2 uv = GetBendMapUV(wPos);

	float4 v = tex2D(_BendMap, uv).rgba;

	v.x = v.x * 2.0 - 1.0;
	v.z = v.z * 2.0 - 1.0;

	
	return v;
}

float4 GetBendVectorLOD(float3 wPos) 
{
	float2 uv = GetBendMapUV(wPos);

	float4 v = tex2Dlod(_BendMap,float4(uv,0,0)).rgba;

	//Remap from 0.1 to -1.1
	v.x = v.x * 2.0 - 1.0;
	v.z = v.z * 2.0 - 1.0;
	//v.y = 1 - saturate(length(float2(v.x,v.z)));

	return v;
}

float4 GetBendOffset(float3 wPos, float3 wPivotPos, BendSettings b) 
{
	float4 vec = GetBendVectorLOD(wPivotPos);

	float grassHeight = wPos.y;
	float bendHeight = vec.y;
	half dist = grassHeight - bendHeight;

	//Note since 7.1.5 somehow this causes the grass to bend down after the bender reaches a certain height
	//dist = abs(dist); //If bender is below grass, dont bend up

	half weight = saturate(dist);
	//weight = vec.y;
	half mask = b.mask * vec.a * 60;
	//float mask = vec.a * 90;
	half2 dir = normalize(float2(vec.x,vec.z));
	half3 axis = cross(half3(dir.x, 0, dir.y), half3(0, -1, 0));
	half angle = weight * mask * UNITY_PI / 180;
	angle = vec.a * 0.5 * UNITY_PI; 
	//float4 offset = float4(RotateAroundAxis(wPos - wPivotPos, axis, angle), vec.a);
	float4 offset = float4(RotateAroundAxis(wPivotPos,wPos, axis, angle), vec.a);

	return offset;
}

float4 GetBendOffset(float3 wPos, float3 wPivotPos,  float4 bendData, half mask)
{
	//给单人的坐标交互做的
	
	//bendData中，xy为交互物体的世界空间xz坐标，z为交互范围，w为强度

	//使用草与物体的距离与范围计算偏移后的坐标权重
	half weight = saturate((bendData.z - distance(wPos.xz,bendData.xy)) * bendData.z);

	//使用草根与物体坐标计算偏转方向
	float2 dir = -normalize(bendData.xy - wPivotPos.xz);

	//通过方向计算草绕着旋转的轴
	float3 axis = cross(float3(dir.x, 0, dir.y), float3(0, -1, 0));

	//使用uv的y轴与交互强度计算偏转多少角度
	float angle =   UNITY_PI * bendData.w ;

	float3 offset = RotateAroundAxis(wPivotPos,wPos, axis, angle);
	offset.y = min(wPos.y,offset.y);
	return float4(offset,weight);
}

float4 GetBendOffset(float3 wPos, float3 wPivotPos)
{
	//多人交互
	float2 UV = ((wPivotPos.xz - _BendCameraWS.xz)/_BendCameraWS.w) * 0.5 + 0.5;
	UV.y = 1 - UV.y;
	float4 v = tex2Dlod(_BendMap,float4(UV,0,0));
	v.xz = v.xz * 2 - 1;
	//return float4(v.rgb,1);
	half weight = v.g;
	float2 dir = normalize(v.xz);
	//通过方向计算草绕着旋转的轴
	float3 axis = cross(float3(dir.x, 0, dir.y), float3(0, -1, 0));

	//使用uv的y轴与交互强度计算偏转多少角度
	float angle =   UNITY_PI * weight /2;

	float3 offset = RotateAroundAxis(wPivotPos,wPos, axis, angle);
	offset.y = min(wPos.y,offset.y);
	return float4(offset,weight);
}

float4 GetSimpleBendOffset(float3 wPos, float3 wPivotPos, half uv)
{
	//多人交互
	float2 UV = ((wPivotPos.xz - _BendCameraWS.xz)/_BendCameraWS.w) * 0.5f + 0.5f;
	
	#if UNITY_UV_STARTS_AT_TOP
		UV.y = 1 - UV.y;
	#endif
	
	half4 v = tex2Dlod(_BendMap,float4(UV,0,0));
	v.xz = v.xz * 2.0h - 1.0h;
	
	half weight = v.g;
	half2 dir = normalize(v.xz);

	wPos.xz += dir * uv;
	wPos.y -= saturate(distance(_BendCameraWS.xz,wPos)) * uv ;

	return float4(wPos,weight);
}