
#define AO_MASK				v.uv.y
#define BEND_MASK			v.uv.y
#include "UnityCG.cginc"
#include "AutoLight.cginc"
struct a2v
{ 
	float4 vertex   : POSITION;
	half3 normalOS     : NORMAL;

	float2 uv           : TEXCOORD0;
	float2 lightmapUV	: TEXCOORD1;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
	float4 pos               		: SV_POSITION;
	float2 uv                       : TEXCOORD0;
	half3  normalWS                 : TEXCOORD1;	
	half3 color						: TEXCOORD2;
	float3 positionWS				: TEXCOORD3; 
	UNITY_FOG_COORDS(4)
	unityShadowCoord4 _ShadowCoord 	: TEXCOORD5;
	//SHADOW_COORDS(5) 
	//float3 positionOS               : TEXCOORD7;
	//float4 bakedGI 					: TEXCOORD6;
	//half4 vertexSH					: TEXCOORD7;

#ifdef _ADDITIONAL_LIGHTS_VERTEX
	half3 vertexLight				: TEXCOORD8;
#endif

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
};

struct VertexOutput
{
	float4 positionOS;
	float3 positionWS;
	half3 normalWS;
	float3 pivotWS;
	half4 color;
};


float4x4 _localToWorldMatrix;

float ObjectPosRand01()
{
	return frac(UNITY_MATRIX_M[0][3] + UNITY_MATRIX_M[1][3] + UNITY_MATRIX_M[2][3]);
}

VertexOutput GetVertexData(a2v v,half height)
{	
	half3 color = half3(UNITY_MATRIX_M[3][0], UNITY_MATRIX_M[3][1], UNITY_MATRIX_M[3][2]);
	half scale = UNITY_MATRIX_M[1][1];

	float4x4 objectToWorldMaterix = mul(_localToWorldMatrix, UNITY_MATRIX_M);
	float4 positionOS = v.vertex;
	positionOS.xz *= scale * height;

	VertexOutput data;

	data.positionOS = positionOS;
	data.positionWS = mul(UNITY_MATRIX_M, positionOS).xyz;

	data.normalWS = UnityObjectToWorldNormal(v.normalOS);//input.positionOS;//mul((float3x3)objectToWorldMaterix, input.normalOS);
	//data.pivotWS = float3(objectToWorldMaterix[0][3], objectToWorldMaterix[1][3] + 0.25, objectToWorldMaterix[2][3]);
	data.pivotWS = float3(UNITY_MATRIX_M[0][3], UNITY_MATRIX_M[1][3], UNITY_MATRIX_M[2][3]);
	//data.pivotWS = float3(objectToWorldMaterix[0][3], objectToWorldMaterix[1][3], objectToWorldMaterix[2][3]);
	data.color = half4(color, UNITY_MATRIX_M[3][3]);

	return data;
}
