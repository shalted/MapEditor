//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA
#include "Common.hlsl"
//Properties
sampler2D _WindMap;       
float4 _GlobalWindParams;
//X: Strength
//W: (int bool) Wind zone present
float _WindStrength;
float _WindBack;
//Nature Renderer parameters
float4 GlobalWindDirectionAndStrength;
//X: Gust dir X
//Y: Gust dir Y
//Z: Gust speed
//W: Gust strength
float4 _GlobalShiver;
//X: Shiver speed
//Y: Shiver strength

struct WindSettings
{
	half mask;
	half speed;
	half4 direction;

	half gustStrength;
	half gustFrequency;
};

WindSettings PopulateWindSettings(in half strength, half speed, half4 direction, half mask, half gustStrength, half gustFrequency)
{
	WindSettings s;

	//Apply WindZone strength
	if (_GlobalWindParams.w > 0) 
	{
		strength *= _GlobalWindParams.x;
		gustStrength *= _GlobalWindParams.x;
	}

	//Nature renderer params
	if (_GlobalShiver.y > 0) {
		strength += _GlobalShiver.y;
		speed += _GlobalShiver.x;
	}
	if (GlobalWindDirectionAndStrength.w > 0) {
		gustStrength += GlobalWindDirectionAndStrength.w;
		direction.xz += GlobalWindDirectionAndStrength.xy;
	}
	
	s.mask = mask;
	s.speed = speed;
	s.direction = direction;

	s.gustStrength = gustStrength;
	s.gustFrequency = gustFrequency;

	return s;
}

//World-align UV moving in wind direction
float2 GetGustingUV(float3 wPos, WindSettings s) {
	return (wPos.xz * s.gustFrequency * 0.01) + (_Time.y * s.speed * s.gustFrequency * 0.01) * -s.direction.xz;
}

float SampleGustMapLOD(float3 wPos, WindSettings s) {

	float2 gustUV = GetGustingUV(wPos, s);
	//gustUV *=2;
	float gust = tex2Dlod(_WindMap, float4(gustUV,0,0)).r - _WindBack;
	//gust = gust * 2 - 1;
	//gust *=.6;
	gust *= s.gustStrength * s.mask * 360;

	return gust;
}

float SampleGustMap(float3 wPos, WindSettings s)
{
	float2 gustUV = GetGustingUV(wPos, s);

	float gust = tex2D(_WindMap, gustUV).r;

	gust *= s.gustStrength * s.mask;

	//Apply WindZone strength
	if (_GlobalWindParams.w > 0)
	{
		gust *= _GlobalWindParams.x;
	}

	return gust;
}

float4 GetWindOffset(in float3 positionWS, in float3 wPivotPos, WindSettings s)
{
	//Apply gusting
	//float gust = SampleGustMapLOD(positionWS, s) ;
	float gust = SampleGustMapLOD(wPivotPos, s) ;
	
	//Mask by direction vector + gusting push
	float3 axis = cross(s.direction.xyz, float3(0, -1, 0));

	float angle =  gust * UNITY_PI / 180;

	//float4 offset = float4(RotateAroundAxis(positionWS - wPivotPos, axis, angle), 1);
	float4 offset = float4(RotateAroundAxis(wPivotPos, positionWS, axis, angle), 1);
	return offset ;
}

float3 GetSimpleWind(in float3 positionWS,  WindSettings s, half uv)
{
	float2 gustUV = GetGustingUV(positionWS, s);//将世界坐标与风效参数用于计算采样UV
	//float y = 1 - normalize(positionWS).y;//把固定点方向反向（Y越高动得越不明显）
	//float y2 = y*y;//平方获得Y轴曲线变化效果 0-1
	half gust = (tex2Dlod(_WindMap, float4(gustUV,0,0)).r - _WindBack) * uv * uv * s.gustStrength;  //采噪声图，WindBack用于惯性回摆 
    positionWS.xz += sin(gust) ;
    return positionWS ;
}

float3 GetSimpleWindHeight(in float3 positionWS,  WindSettings s, half uv)
{
	float2 gustUV = GetGustingUV(positionWS, s);//将世界坐标与风效参数用于计算采样UV
	//float y = 1 - normalize(positionWS).y;//把固定点方向反向（Y越高动得越不明显）
	//float y2 = y*y;//平方获得Y轴曲线变化效果 0-1
	half gust = (tex2Dlod(_WindMap, float4(gustUV,0,0)).r - _WindBack) * uv * uv * s.gustStrength;  //采噪声图，WindBack用于惯性回摆 
	positionWS.y += sin(gust);
	return positionWS ;
}

void GetSimpleWindWithNormal(inout float3 positionWS,in float3 positionOS, in float3 normalWS, in half3 color, WindSettings s, half uv, half d)
{
	float2 gustUV = GetGustingUV(positionOS, s);//将世界坐标与风效参数用于计算采样UV
	//float y = 1 - normalize(positionWS).y;//把固定点方向反向（Y越高动得越不明显）
	//float y2 = y*y;//平方获得Y轴曲线变化效果 0-1
	half gust = (tex2Dlod(_WindMap, float4(gustUV,0,0)).r - _WindBack) * uv * uv * s.gustStrength;  //采噪声图，WindBack用于惯性回摆
	// half ao = sin(gust);
	positionWS.xz += sin(gust) * (1 - d);
	positionWS.y += sin(gust) * d;
	
	// positionWS.xyz +=  (color - 0.5) * 2 * sin(gust) ;
	// return ao;
}