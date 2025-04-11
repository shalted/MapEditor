
#ifndef UNIVERSAL_COMMON_INCLUDED
#define UNIVERSAL_COMMON_INCLUDED

#define UNITY_PI            3.14159265359f
float3 RotateAroundAxis(float3 original, float3 axis, float angle)
{
	float C = cos(angle);
	float S = sin(angle);
	float t = 1 - C;
	float m00 = t * axis.x * axis.x + C;
	float m01 = t * axis.x * axis.y - S * axis.z;
	float m02 = t * axis.x * axis.z + S * axis.y;
	float m10 = t * axis.x * axis.y + S * axis.z;
	float m11 = t * axis.y * axis.y + C;
	float m12 = t * axis.y * axis.z - S * axis.x;
	float m20 = t * axis.x * axis.z - S * axis.y;
	float m21 = t * axis.y * axis.z + S * axis.x;
	float m22 = t * axis.z * axis.z + C;
	float3x3 finalMatrix = float3x3(m00, m01, m02, m10, m11, m12, m20, m21, m22);
	return mul(finalMatrix, original) - original;
}

float3 RotateAroundAxis(float3 center,float3 original, half3 axis, half angle)
{
	original -= center;
	float C = cos(angle);
	float S = sin(angle);
	float t = 1 - C;
	float m00 = t * axis.x * axis.x + C;
	float m01 = t * axis.x * axis.y - S * axis.z;
	float m02 = t * axis.x * axis.z + S * axis.y;
	float m10 = t * axis.x * axis.y + S * axis.z;
	float m11 = t * axis.y * axis.y + C;
	float m12 = t * axis.y * axis.z - S * axis.x;
	float m20 = t * axis.x * axis.z - S * axis.y;
	float m21 = t * axis.y * axis.z + S * axis.x;
	float m22 = t * axis.z * axis.z + C;
	float3x3 finalMatrix = float3x3(m00, m01, m02, m10, m11, m12, m20, m21, m22);
	return mul(finalMatrix, original) + center;
}

//Ҫ�����������0-16 ����
float Encode(float param1, float param2)
{
	return param1 / 16 + param2 / 256;
}

float2 Decode(float param)
{
	float param1 = param * 16;
	float param2 = param * 256 - 16 * param1;

	return float2(param1, param2);
}

#endif



