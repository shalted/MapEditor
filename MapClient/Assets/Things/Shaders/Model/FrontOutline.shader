// Made with Amplify Shader Editor v1.9.1.8
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "FrontOutline"
{
    Properties
    {
        [HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
        [HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
        _MainTex("主贴图", 2D) = "white" {}
        _Shadow("阴影强弱", Range( 0 , 1)) = 0.5
        _ShadowSmooth("阴影软硬", Range( 0 , 0.499)) = 0
        _MainFrresnel("内层边缘范围", Range( 0.001 , 10)) = 0
        _FresnelSmooth("内层边缘平滑", Range( 0 , 0.499)) = 0
        [Header(..........................................Outline............................................)][Space(10)]_OutWith("描边宽度", Float) = 0
        [HDR]_OutlineColoe("描边颜色", Color) = (0,0,0,0)
        [KeywordEnum(VERTEXNORMAL,VERTEXCOLOR,SMOOTHNORMALUV2,SMOOTHNORMALUV3)] _NormalSelect("描边模式选择", Float) = 0
        _OutLineNoise("描边噪声图", 2D) = "white" {}
        _OutlineSpeed("描边流动(沿着第二套UV的X轴移动)", Float) = 0
        _OutNoiseIntensity("噪声裁切影响值", Range( 0 , 1)) = 0
        _Threshold("噪声裁切阈值", Range( 0 , 1)) = 0
        _ZOffest("裁剪空间深度偏移", Range( -10 , 10)) = 0
        [HideInInspector] _texcoord( "", 2D ) = "white" {}

    }
    SubShader
    {
		LOD 0

        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
		ZWrite On
		ZTest LEqual
    	
    	Pass
        {
        	
            Name "Main"
        	Tags { "LightMode"="UniversalForward" }
            Cull Back
        	Offset 0 , 0

            HLSLPROGRAM
            #define ASE_SRP_VERSION 140010

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma fragmentoption ARB_precision_hint_fastes
            #pragma multi_compile_instancing

            //自定义预处理或宏
			#pragma shader_feature_local_vertex _NORMALSELECT_VERTEXNORMAL _NORMALSELECT_VERTEXCOLOR _NORMALSELECT_SMOOTHNORMALUV2 _NORMALSELECT_SMOOTHNORMALUV3

			//自定义预处理或宏

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            //全局变量
			CBUFFER_START( UnityPerMaterial )
			float4 _OutlineColoe;
			float4 _OutLineNoise_ST;
			float _OutWith;
			float _ZOffest;
			float _Shadow;
			float _ShadowSmooth;
			float _FresnelSmooth;
			float _MainFrresnel;
			float _OutlineSpeed;
			float _OutNoiseIntensity;
			float _Threshold;
			CBUFFER_END

			//全局变量

            struct appdata
            {
                float4 vertex : POSITION;
				half4 color : COLOR;
            	float4 uv : TEXCOORD0;
				//自定义数据
				float3 normal : NORMAL;
				//自定义数据

				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            	half4 color : COLOR;
            	half2 uv : TEXCOORD0;
				//自定义数据
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				//自定义数据

            	UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert ( appdata v  )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				//自定义算法板块
				float3 worldNormal = TransformObjectToWorldNormal(v.normal);
				o.texcoord1.xyz = worldNormal;
				float3 worldPos = TransformObjectToWorld( (v.vertex).xyz );
				o.texcoord2.xyz = worldPos;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.texcoord1.w = 0;
				o.texcoord2.w = 0;
				//自定义算法板块

				v.vertex.xyz +=  float3( 0, 0, 0 ) ;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.color = v.color;
            	o.uv = v.uv.xy;
				return o;
			}

			half4 frag ( v2f i  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( i );

				//自定义算法板块
				float2 uv_MainTex = i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 tex2DNode88 = tex2D( _MainTex, uv_MainTex );
				float3 worldNormal = i.texcoord1.xyz;
				float dotResult5_g9 = dot( worldNormal , _MainLightPosition.xyz );
				float smoothstepResult76 = smoothstep( _ShadowSmooth , ( 1.0 - _ShadowSmooth ) , (dotResult5_g9*0.5 + 0.5));
				float4 lerpResult74 = lerp( ( tex2DNode88 * _Shadow ) , tex2DNode88 , smoothstepResult76);
				float4 color84 = IsGammaSpace() ? float4(0,0,0,0) : float4(0,0,0,0);
				float3 worldPos = i.texcoord2.xyz;
				float3 worldViewDir = ( _WorldSpaceCameraPos.xyz - worldPos );
				worldViewDir = normalize(worldViewDir);
				float fresnelNdotV79 = dot( worldNormal, worldViewDir );
				float fresnelNode79 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV79, _MainFrresnel ) );
				float smoothstepResult80 = smoothstep( _FresnelSmooth , ( 1.0 - _FresnelSmooth ) , fresnelNode79);
				float4 lerpResult73 = lerp( lerpResult74 , color84 , smoothstepResult80);
				
				//自定义算法板块

				half4 col;
				col.xyz = lerpResult73.rgb;
				col.w = 1;
				return col;
			}
            ENDHLSL
        }
    	
        Pass
        {
            Name "Ouline"
            Cull Front
        	Offset [_ZOffest] , 0

            HLSLPROGRAM
            #define ASE_SRP_VERSION 140010

            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastes
            #pragma multi_compile_instancing

            //自定义预处理或宏
			#define ASE_NEEDS_VERT_COLOR
			#pragma shader_feature_local_vertex _NORMALSELECT_VERTEXNORMAL _NORMALSELECT_VERTEXCOLOR _NORMALSELECT_SMOOTHNORMALUV2 _NORMALSELECT_SMOOTHNORMALUV3

			//自定义预处理或宏

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"


            //全局变量
			sampler2D _OutLineNoise;
			float3 OctahedronToUnitVector1_g10( float2 oct )
			{
				    // float3 unitVec = float3(oct, 1 - dot(float2(1, 1), abs(oct)));
				    //
				    // if (unitVec.z < 0)
				    // {
				    //     unitVec.xy = (1 - abs(unitVec.yx)) *(unitVec.xy >= 0 ? float2(1, 1) : float2(-1, -1));
				    // }
				    float3  unitVec = float3(oct.x, oct.y, 1.0f - abs(oct.x) -  abs(oct.y));
				    float t = max( -unitVec.z, 0.0f );
				    unitVec.x += unitVec.x >= 0.0f ? -t : t;
				    unitVec.y += unitVec.y >= 0.0f ? -t : t;
				    return normalize(unitVec);
			}
			
			float3 OctahedronToUnitVector4_g10( float2 oct )
			{
				    // float3 unitVec = float3(oct, 1 - dot(float2(1, 1), abs(oct)));
				    //
				    // if (unitVec.z < 0)
				    // {
				    //     unitVec.xy = (1 - abs(unitVec.yx)) *(unitVec.xy >= 0 ? float2(1, 1) : float2(-1, -1));
				    // }
				    float3  unitVec = float3(oct.x, oct.y, 1.0f - abs(oct.x) -  abs(oct.y));
				    float t = max( -unitVec.z, 0.0f );
				    unitVec.x += unitVec.x >= 0.0f ? -t : t;
				    unitVec.y += unitVec.y >= 0.0f ? -t : t;
				    return normalize(unitVec);
			}
			
			CBUFFER_START( UnityPerMaterial )
			float4 _OutlineColoe;
			float4 _OutLineNoise_ST;
			float _OutWith;
			float _ZOffest;
			float _Shadow;
			float _ShadowSmooth;
			float _FresnelSmooth;
			float _MainFrresnel;
			float _OutlineSpeed;
			float _OutNoiseIntensity;
			float _Threshold;
			CBUFFER_END

			//全局变量

            struct appdata
            {
                float4 vertex : POSITION;
				half4 color : COLOR;
            	float4 uv : TEXCOORD0;
				//自定义数据
				float3 normal : NORMAL;
				float4 texcoord1 : TEXCOORD1;
				float4 tangent : TANGENT;
				float4 texcoord2 : TEXCOORD2;
				//自定义数据
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            	half4 color : COLOR;
            	half2 uv : TEXCOORD0;
				//自定义数据
				
				//自定义数据
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert ( appdata v  )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				//自定义算法板块
				float2 texCoord2_g10 = v.texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 oct1_g10 = texCoord2_g10;
				float3 localOctahedronToUnitVector1_g10 = OctahedronToUnitVector1_g10( oct1_g10 );
				float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
				float3 worldNormal = TransformObjectToWorldNormal(v.normal);
				float vertexTangentSign = v.tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 worldBitangent = cross( worldNormal, worldTangent ) * vertexTangentSign;
				float3x3 tangentToWorldFast = float3x3(worldTangent.x,worldBitangent.x,worldNormal.x,worldTangent.y,worldBitangent.y,worldNormal.y,worldTangent.z,worldBitangent.z,worldNormal.z);
				float3 tangentTobjectDir8_g10 = normalize( mul( GetWorldToObjectMatrix(), float4( mul( tangentToWorldFast, localOctahedronToUnitVector1_g10 ), 0 ) ).xyz );
				float2 texCoord3_g10 = v.texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float2 oct4_g10 = texCoord3_g10;
				float3 localOctahedronToUnitVector4_g10 = OctahedronToUnitVector4_g10( oct4_g10 );
				float3 tangentTobjectDir7_g10 = normalize( mul( GetWorldToObjectMatrix(), float4( mul( tangentToWorldFast, localOctahedronToUnitVector4_g10 ), 0 ) ).xyz );
				#if defined(_NORMALSELECT_VERTEXNORMAL)
				float4 staticSwitch28_g10 = float4( v.normal , 0.0 );
				#elif defined(_NORMALSELECT_VERTEXCOLOR)
				float4 staticSwitch28_g10 = v.color;
				#elif defined(_NORMALSELECT_SMOOTHNORMALUV2)
				float4 staticSwitch28_g10 = float4( tangentTobjectDir8_g10 , 0.0 );
				#elif defined(_NORMALSELECT_SMOOTHNORMALUV3)
				float4 staticSwitch28_g10 = float4( tangentTobjectDir7_g10 , 0.0 );
				#else
				float4 staticSwitch28_g10 = float4( v.normal , 0.0 );
				#endif
				
				//自定义算法板块
				v.vertex.xyz += ( ( staticSwitch28_g10 * 0.01 * _OutWith ) * v.color.a ).rgb;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.color = v.color;
            	o.uv = v.uv.xy;
				return o;
			}

			half4 frag ( v2f i  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( i );
				//自定义算法板块
				float2 uv_OutLineNoise = i.uv.xy * _OutLineNoise_ST.xy + _OutLineNoise_ST.zw;
				float mulTime50_g10 = _TimeParameters.x * _OutlineSpeed;
				float lerpResult55_g10 = lerp( 1.0 , tex2D( _OutLineNoise, ( uv_OutLineNoise + mulTime50_g10 ) ).r , _OutNoiseIntensity);
				float clampResult57_g10 = clamp( lerpResult55_g10 , 0.0 , 1.0 );
				clip( clampResult57_g10 - _Threshold);
				
				//自定义算法板块
				half4 col;
				col.xyz = _OutlineColoe.rgb;
				col.w = 1;
				return col;
			}
            ENDHLSL
        }

        
    }
	
	CustomEditor "ASEMaterialInspector"
	Fallback Off
}/*ASEBEGIN
Version=19108
Node;AmplifyShaderEditor.LerpOp;73;736.8551,-505.7581;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;74;701.4257,-808.7502;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;75;514.4257,-1098.75;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SmoothstepOpNode;76;323.1028,-707.4029;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;77;-229.5742,-764.7502;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;78;15.42572,-764.7502;Inherit;False;Half Lambert Term;-1;;9;86299dc21373a954aa5772333626c9c1;0;1;3;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;79;39.93402,-381.0864;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;80;458.8698,-352.7904;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;81;292.8698,-193.7904;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;82;-271.1302,-289.7904;Inherit;False;Property;_MainFrresnel;内层边缘范围;3;0;Create;False;0;0;0;False;0;False;0;3.69;0.001;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;83;-6.130188,-197.7904;Inherit;False;Property;_FresnelSmooth;内层边缘平滑;4;0;Create;False;0;0;0;False;0;False;0;0.431;0;0.499;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;84;601.6353,-119.4449;Inherit;False;Constant;_MainColor;MainColor;7;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;85;171.1028,-581.7054;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;86;-149.8972,-582.403;Inherit;False;Property;_ShadowSmooth;阴影软硬;2;0;Create;False;0;0;0;False;0;False;0;0.499;0;0.499;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;87;279.4257,-872.7502;Inherit;False;Property;_Shadow;阴影强弱;1;0;Create;False;0;0;0;False;0;False;0.5;0.882;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;88;125.8289,-1108.724;Inherit;True;Property;_MainTex;主贴图;0;0;Create;False;0;0;0;False;0;False;-1;None;5c49c8b1f31b7d74c81e26f0badc7ab4;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;1182.279,236.5462;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.VertexColorNode;63;978.5748,266.8288;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;90;984.6602,24.41531;Inherit;False;Property;_ZOffest;裁剪空间深度偏移;13;0;Create;False;0;0;0;True;0;False;0;10;-10;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;92;1442.525,-252.3416;Float;False;True;-1;2;ASEMaterialInspector;0;23;FrontOutline;194013c89b525f6458048636ae2b7f78;True;Main;0;0;Main;3;False;True;2;5;False;;10;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;4;RenderPipeline=UniversalPipeline;Queue=Transparent=Queue=0;IgnoreProjector=True;RenderType=Transparent=RenderType;False;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;0;;0;0;Standard;0;0;2;True;True;False;;False;0
Node;AmplifyShaderEditor.FunctionNode;89;985.9068,122.1899;Inherit;False;Outline;5;;10;0b3b8be7a128020439385c66aa63a5c6;0;0;2;COLOR;33;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;93;1427.525,113.6584;Float;False;False;-1;2;ASEMaterialInspector;0;23;New Amplify Shader;194013c89b525f6458048636ae2b7f78;True;Ouline;0;1;Ouline;3;False;True;2;5;False;;10;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;4;RenderPipeline=UniversalPipeline;Queue=Transparent=Queue=0;IgnoreProjector=True;RenderType=Transparent=RenderType;False;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;False;False;False;False;False;False;False;False;True;False;False;True;True;0;True;_ZOffest;0;False;;False;False;False;0;;0;0;Standard;0;False;0
WireConnection;73;0;74;0
WireConnection;73;1;84;0
WireConnection;73;2;80;0
WireConnection;74;0;75;0
WireConnection;74;1;88;0
WireConnection;74;2;76;0
WireConnection;75;0;88;0
WireConnection;75;1;87;0
WireConnection;76;0;78;0
WireConnection;76;1;86;0
WireConnection;76;2;85;0
WireConnection;78;3;77;0
WireConnection;79;3;82;0
WireConnection;80;0;79;0
WireConnection;80;1;83;0
WireConnection;80;2;81;0
WireConnection;81;0;83;0
WireConnection;85;0;86;0
WireConnection;67;0;89;0
WireConnection;67;1;63;4
WireConnection;92;0;73;0
WireConnection;93;0;89;33
WireConnection;93;2;67;0
ASEEND*/
//CHKSM=9D45ABCCE8D9CDDD97591CAE9E1F35CF79ABF56E