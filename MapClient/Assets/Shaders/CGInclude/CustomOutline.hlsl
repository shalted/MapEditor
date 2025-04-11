#ifndef UNIVERSAL_SHIYUE_OUTLINE_INCLUDED
#define UNIVERSAL_SHIYUE_OUTLINE_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// Returns 'true' if the current view performs a perspective projection.
bool IsPerspectiveProjection_Outline()
{
    return (unity_OrthoParams.w == 0);
}

float GetOutLineScale(float z, float nPower = 1.05, float fPower = 0.2)
{
    return pow(z, z < 1 ? nPower : fPower) * lerp(1, UNITY_MATRIX_P._m00, IsPerspectiveProjection_Outline() ? 0.60 : 1.0);
}


float3 TransformObjectToView(float3 positionOS)
{
    return mul(GetWorldToViewMatrix(), float4(mul(GetObjectToWorldMatrix(), float4(positionOS, 1.0)).xyz, 1.0)).xyz;
}


struct Attributes
{
    float4 positionOS : POSITION;
    float2 texcoord : TEXCOORD0;
    float3 normalOS : NORMAL;
    float4 color : COLOR;
    float4 tangentOS : TANGENT;

    #if defined(UV2_AS_NORMALS)
        float4 uv2 : TEXCOORD1;
    #endif

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 color : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


float3x3 GetTBNMatrix(Attributes input)
{
    
    float3 normalOS = input.normalOS;
    float4 tangentOSOS = input.tangentOS;
    float3 binormal = cross(normalize(normalOS),
                            normalize(tangentOSOS.xyz)) * tangentOSOS.w;

    float3x3 objectToTangentMatrix = float3x3(tangentOSOS.xyz, binormal, normalOS);

    return objectToTangentMatrix;
}

float3x3 GetTBNMatrixInverseObject(Attributes input)
{
    float3 normalOS = input.normalOS;
    float4 tangentOSOS = input.tangentOS;
    float3 binormalOS = cross(normalize(normalOS), normalize(tangentOSOS.xyz)) * tangentOSOS.w;

    float3 matRow1 = float3(tangentOSOS.x, binormalOS.x, normalOS.x);
    float3 matRow2 = float3(tangentOSOS.y, binormalOS.y, normalOS.y);
    float3 matRow3 = float3(tangentOSOS.z, binormalOS.z, normalOS.z);

    float3x3 tangentOSToObjectMatrix = float3x3(matRow1, matRow2, matRow3);

    return tangentOSToObjectMatrix;
}

float3 GetNormalOS(float3 normalTS, Attributes input)
{

    TransformTangentToWorld(normalTS, GetTBNMatrix(input));
    
    float3x3 objectToTangentMatrix = GetTBNMatrix(input);
    float3 normalOS = normalize(mul(normalTS, objectToTangentMatrix));
    return normalOS;
}

float3 GetNormalOS2(float3 normalTS, Attributes input)
{
    float3x3 TBNMatrixInverse = GetTBNMatrixInverseObject(input);

    float3 normalOS = mul(TBNMatrixInverse, normalTS);

    return normalOS;
}

///
///https://zhuanlan.zhihu.com/p/109101851
///
Varyings OutLinePassVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    #if !USEOUTLINE
        return output;
    #endif
    
    float3 normal = input.normalOS;

    #if COLORS_AS_NORMALS
        //通过自算逆矩阵的方式 可行
        // normal = GetNormalOS2(v.color.rgb  * 2 - 1, v);
        //通过mul参数互换的方式 可行
        normal = GetNormalOS(input.color.rgb * 2 - 1, input);
        output.color = input.color;
    #elif UV2_AS_NORMALS
        normal = GetNormalOS(input.uv2.xyz, input);
    #endif

    float outlineWidth = _Outline_Width * input.color.a;
    float4 projNoraml = TransformWViewToHClip(normal);
    
    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
    normal = mul(unity_ObjectToWorld, float4(normal, 0)).xyz;
    float2 clipNormals = normalize(mul(UNITY_MATRIX_VP, float4(normal,0)).xy);
    
    float screenRatio = _ScreenParams.x / _ScreenParams.y;
    output.positionCS.xy += clipNormals.xy * (outlineWidth * 0.01) * float2(1.0, screenRatio);
    //output.positionCS.xy +=  projNoraml.xy * outlineWidth * 0.01;
					
    return output;
}

half4 OutlinePassFragment(Varyings input) : SV_Target
{
    return half4(_OutlineColor.rgb, 1);
}

float GetOutlineWidth(Attributes input)
{
    float outlineWidth = _Outline_Width;
    return outlineWidth;
}

half4 OutlinePassFragmentNew(Varyings input) : SV_Target
{
    #if defined(USEOUTLINE)
        half4 finalOutlineColor;
        #if defined(USEOUTLINEMAP)
            half4 outlineMapColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
            finalOutlineColor.rgb = outlineMapColor.rgb * _OutlineColor.rgb;
        #else
            finalOutlineColor.rgb = _OutlineColor.rgb;
        #endif
        finalOutlineColor.a = 1;
        return finalOutlineColor;
    #else
        return 0;
    #endif
}

#endif
