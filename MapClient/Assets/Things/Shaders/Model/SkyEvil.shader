Shader "ShiYue/Character/SkyEvil"
{
	Properties
	{
		[Header(__MainTex__)]
		_MainTex("主纹理", 2D) = "black" {}
		_Height1("1层深度", Range( -2 , 2)) = 2
		_Height2("2层深度", Range( -1 , 2)) = 0.87
		_Speed("XY_1层速度 ZW_2层速度", Vector) = (0.02,0.02,-0.03,-0.03)

		[Header(__AddTex__)]
		_AddTex("花纹纹理",2D) = "black" {}
		[HDR]_AddColor("花纹颜色",Color) = (0,0,0,0)


		[Space(20)]
		[Header(__ADDColor__)]
		[HDR]_ColorTop("顶部颜色", Color) = (1,1,1,0)
		[HDR]_ColorButtom("底部颜色", Color) = (0,0,0,0)
		_ColorLerp("颜色渐变微调", Range( -1 , 1)) = 0

		[Space(20)]
		[Header(__Spcular__)]
		[HDR]_FresnelColor("边缘光颜色", Color) = (1,1,1,0)
		_FresnelPower("边缘光宽度", Range( 0 , 10)) = 2.3

		[Space(10)]
		[HDR]_SpcularColor("高光颜色", Color) = (1,1,1,0)		
		_SpcularPower("高光范围", Range( 0 , 30)) = 2
		_SpcularSmooth("高光软硬边微调", Range( 0 , 0.5)) = 0.2
		_HeightStep("高光高度限制", Range( 0 , 1)) = 1		
		_FakeLightDir("模拟光照方向", Vector) = (1,1,1,1)


	}

	SubShader
	{			
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }							
		Pass
		{						
			Tags { "LightMode"="UniversalForward" }						
			
			Cull Back
			ZWrite On
			ZTest LEqual
			
			HLSLPROGRAM
			
			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"						




			struct VertexInput
			{
				float4 vertex : POSITION;
				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;
				float3 normal : NORMAL;				
				float4 tangent : TANGENT;
				

			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;				

				float2 uv0 : TEXCOORD0;
				float2 uv1 : TEXCOORD1;

				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				float3 worldTangent : TEXCOORD4;
				float3 worldBitangent : TEXCOORD5;
				float3 fakeLightDir : TEXCOORD6;
				

			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_ST;
			float _Height1;
			float _Height2;
			half4 _Speed;
			
			half4 _AddColor;
			float4 _AddTex_ST;

			half4 _ColorTop;
			half4 _ColorButtom;
			half _ColorLerp;

			half4 _FresnelColor;
			half  _FresnelPower;
						
			half4 _SpcularColor;
			half  _SpcularPower;
			half  _SpcularSmooth;
			half  _HeightStep;			
			half4 _FakeLightDir;
			
			CBUFFER_END

			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
			TEXTURE2D(_AddTex);	    SAMPLER(sampler_AddTex);

			VertexOutput vert ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;

				o.clipPos = TransformObjectToHClip( v.vertex.xyz );

				o.uv0 = v.uv0;
				o.uv1 = v.uv1;//颜色上下渐变的关键
								
				o.worldPos = TransformObjectToWorld( v.vertex.xyz );

				///假光照方向
				o.fakeLightDir = TransformObjectToWorld(normalize(_FakeLightDir.xyz));

				///TBN矩阵
				o.worldNormal.xyz = TransformObjectToWorldNormal(v.normal);
				o.worldTangent.xyz = TransformObjectToWorldDir(v.tangent.xyz);								
				half vertexTangentSign = v.tangent.w * unity_WorldTransformParams.w;
				o.worldBitangent.xyz = cross( o.worldNormal.xyz, o.worldTangent.xyz ) * vertexTangentSign;
														
				return o;
			}

									
			half4 frag ( VertexOutput IN  ) : SV_Target
			{
			///主纹理
				float2 uv_MainTex = IN.uv0.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				
			///花纹纹理
				float2 uv_AddTex = IN.uv0.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half4 AddTexColor = SAMPLE_TEXTURE2D( _AddTex,sampler_AddTex, uv_AddTex);
				AddTexColor = AddTexColor * _AddColor;

			///视差采样纹理						
				///TBN
				half3 worldTangent   =	normalize( IN.worldTangent.xyz );
				half3 worldNormal    =  normalize( IN.worldNormal.xyz );
				half3 worldBitangent =	normalize( IN.worldBitangent.xyz );
				half3 tanToWorld0 = float3( worldTangent.x, worldBitangent.x, worldNormal.x );
				half3 tanToWorld1 = float3( worldTangent.y, worldBitangent.y, worldNormal.y );
				half3 tanToWorld2 = float3( worldTangent.z, worldBitangent.z, worldNormal.z );
				
				///切线空间视角方向
				float3 WorldPosition = IN.worldPos;	
				float3 worldViewDir = normalize( _WorldSpaceCameraPos.xyz - WorldPosition );				
				half3 tanViewDir =  normalize(tanToWorld0 * worldViewDir.x + tanToWorld1 * worldViewDir.y  + tanToWorld2 * worldViewDir.z);

				///视差偏移UV				
				float2 Parallax_uv1 = ( (_Height1 - 1) * tanViewDir.xy ) + uv_MainTex + frac(_Speed.xy * _Time.y);		//偏移视差后的UV
				float2 Parallax_uv2 = ( (_Height2 - 1)* tanViewDir.xy ) + uv_MainTex + frac(_Speed.zw * _Time.y);
				half3 ParallaxCol =  SAMPLE_TEXTURE2D( _MainTex,sampler_MainTex, Parallax_uv1).xyz + SAMPLE_TEXTURE2D( _MainTex,sampler_MainTex, Parallax_uv2).xyz;

			
			///颜色上下渐变
				half3 AddColor = lerp(_ColorTop,_ColorButtom,saturate(1 - (IN.uv1.y + _ColorLerp))).xyz;
				

			///高光
				///Blinn Phong				
				half3 fakeLightDir = normalize (_FakeLightDir.xyz);													//世界空间 假光照方向
				half3 halfDir = normalize(worldViewDir + fakeLightDir);				
				half NdotH = saturate(dot(worldNormal,halfDir));
				half spcular_base  = pow(NdotH,max(1,_SpcularPower));												//防止负数出现
				spcular_base = smoothstep(0,max(0.001,_SpcularSmooth),spcular_base);								//高光边缘微调				
				half HeightStep = smoothstep( _HeightStep,1,IN.uv1.y);												//高光高度限制
				half3 spcularColor = (spcular_base * HeightStep *_SpcularColor.xyz);

				///菲涅尔	
				half NdotV = 1 - saturate(dot( worldNormal, worldViewDir ));
				half Fresnel_base = pow(NdotV,max(1,_FresnelPower));												//防止负数出现				
				half3 FresnelColor = (Fresnel_base * _FresnelColor.xyz);
				
				
			///混合
				half3 finalRGB = lerp(ParallaxCol,AddTexColor.xyz,AddTexColor.w) + spcularColor + FresnelColor + AddColor;
				return half4(finalRGB,1);								
				//return AddTexColor;
			}

			ENDHLSL
		}

	
	}

}