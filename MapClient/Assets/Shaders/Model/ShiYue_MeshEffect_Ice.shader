
Shader "ShiYue/MeshEffect/Ice"
{
	Properties
	{		
		[Header(__MainTex__)]	
		_BaseColor1("暗色", Color) = (0,0.317647,0.490196,1)
		[HDR]_BaseColor2("亮色", Color) = (0.6745098,0.8901961,1,1)
		_MainTex("主纹理贴图", 2D) = "white" {}	
		_Height("视差贴图", 2D) = "white" {}
		_height("视差高度", Range( 0 , 3)) = 1
		_heightTexSpeed("视差贴图流动速度XY",Vector) = (0,0,0,0)

		[Space(20)]
		[Header(__Spcular__)]		
		[HDR]_SpcularColor("高光颜色", Color) = (0.6650944,0.9221207,1,1)
		[HideInInspector]_FakeLightDir("光照方向xyz",vector) = (1,1,1,0)		//假光照方向
		_Spcular_int("高光强度", Range( 0 , 1)) = 1
		_Spcular_range("高光范围", Range( 0 , 50)) = 10		
		_Fresnel_int("菲涅尔强度", Range( 0 , 1)) = 1
		_Fresnel_range("菲涅尔范围", Range( 0 , 50)) = 10

		[Space(20)]
		[Header(__Clip__)]
		_Clip("溶解度", Range( 0 , 1)) = 0
		[Toggle] _ClipOpen("使用Custom1.x控制溶解",int) = 0
		_ClipTex("溶解贴图", 2D) = "white" {}		
		[HDR]_ClipColor("溶解边颜色", Color) = (1,1,1,1)
		_Clip_line("溶解边线宽", Range( 0 , 0.1)) = 0.04838837
		
		[HideInInspector][HDR]_ProceduralColor ("Procedural Color", Color) = (1, 1, 1, 1)

	}

	SubShader
	{		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="AlphaTest" }
		
		Pass
		{
			Tags { "LightMode"="UniversalForward" }
		
			Cull Back
			Blend SrcAlpha OneMinusSrcAlpha
			Zwrite On
						
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"	
			
			struct VertexInput
			{
				float4 vertex : POSITION;				
				float4 uv : TEXCOORD0;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				half4 color : COLOR;
				
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;							
				float4 uv : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float4 worldNormal : TEXCOORD2;
				float4 worldTangent : TEXCOORD3;				
				float4 worldBitangent : TEXCOORD4;
				float3 fakeLightDir : TEXCOORD5;
				half4 color : COLOR;
				float2 screenUV : TEXCOORD6;
				
			};

			CBUFFER_START(UnityPerMaterial)
			half4 _BaseColor1;
			half4 _BaseColor2;
			half4 _MainTex_ST, _ProceduralColor;
						
			half4 _Height_ST;			
			half _height;
			half4 _heightTexSpeed;
						
			half3 _FakeLightDir;
			half4 _SpcularColor;
			half _Spcular_range;
			half _Spcular_int;
			half _Fresnel_range;
			half _Fresnel_int;

			half _Clip;
			half4 _ClipTex_ST;
			half4 _ClipColor;
			half _Clip_line;
			half _ClipOpen;			

			CBUFFER_END
			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
			TEXTURE2D(_Height);		SAMPLER(sampler_Height);			
			TEXTURE2D(_ClipTex);	SAMPLER(sampler_ClipTex);			

			VertexOutput vert ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;

				o.clipPos = TransformObjectToHClip( v.vertex.xyz );				

				o.uv = v.uv;
				o.color = v.color;
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

			///Clip
				half ClipTex = SAMPLE_TEXTURE2D( _ClipTex, sampler_ClipTex,IN.uv.xy * _ClipTex_ST.xy + _ClipTex_ST.zw).x;								
				half AlphaClipThreshold = (_Clip_line + 1.05) * lerp(_Clip,IN.uv.z,_ClipOpen);
				half Alpha = _Clip_line + ClipTex.r;
				clip( Alpha - AlphaClipThreshold);

				///亮边溶解				
				half ClipTex1 = ClipTex.x;
				half ClipTex2 = ClipTex.x + _Clip_line;
				half3 ClipCol = (step( AlphaClipThreshold,ClipTex2 ) - step( AlphaClipThreshold,ClipTex )) * _ClipColor.xyz;
							
			///主纹理
				float2 uv_MainTex = IN.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half3 MainCol = lerp( _BaseColor1*0.5 , _BaseColor2*0.5 , SAMPLE_TEXTURE2D( _MainTex,sampler_MainTex, uv_MainTex ).r).xyz;
				
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
				float2 _Height_UV = IN.uv.xy * _Height_ST.xy + _Height_ST.zw ;
				half4 Height_Tex = SAMPLE_TEXTURE2D( _Height, sampler_Height,_Height_UV);
				float2 Parallax_uv = ( ( Height_Tex.r - 1 ) * tanViewDir.xy * _height ) + uv_MainTex + frac(_heightTexSpeed.xy * _Time.y);		//偏移视差后的UV，而不是偏移原高度图UV

				half3 ParallaxCol = lerp( _BaseColor1*0.5 , _BaseColor2*0.5 , SAMPLE_TEXTURE2D( _MainTex,sampler_MainTex, Parallax_uv ).r).xyz;

			
			///高光
				///Blinn Phong				
				half3 fakeLightDir = normalize (_FakeLightDir.xyz);								//世界空间 假光照方向
				half3 halfDir = normalize(worldViewDir + fakeLightDir);				
				half NdotH = saturate(dot(worldNormal,halfDir));
				half3 spcular_base  = pow(NdotH,max(5,_Spcular_range));
				half3 spcularColor = (spcular_base * _Spcular_int * _SpcularColor.xyz);

				///菲涅尔	
				half NdotV = 1 - saturate(dot( worldNormal, worldViewDir ));					//防止负数出现
				half Fresnel_base = pow(NdotV,max(5,_Fresnel_range));				
				half3 FresnelColor = (Fresnel_base * _Fresnel_int * _SpcularColor.xyz);
								
			///混合
				half3 finalColor = (MainCol + ParallaxCol + ClipCol + FresnelColor + spcularColor) * IN.color.xyz;				
				half finalAlpha = 1 * IN.color.w;

				return half4( finalColor, finalAlpha) * _ProceduralColor;				
			}

			ENDHLSL
		}		
	
	}	
		
}
