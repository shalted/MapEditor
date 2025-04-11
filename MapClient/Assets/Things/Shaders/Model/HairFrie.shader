Shader "ShiYue/Character/HairFrie"
{
	Properties
	{
		_MainTex("主纹理", 2D) = "white" {}
		_VoTex("顶点偏移纹理", 2D) = "white" {}
		_VoSpeedX("顶点偏移纹理速度X", Float) = 0
		_VoSpeedY("顶点偏移纹理速度Y", Float) = 0
		_VO_Mask("顶点偏移遮罩", 2D) = "white" {}
		_VoIntensity("顶点偏移轴向强度", Vector) = (0,0,0,0)
		[HDR]_FresnelColor("边缘光颜色", Color) = (1,1,1,0)
		_FresnelPower("边缘光宽度", Float) = 5
		_AddNoiseTex("叠加噪波纹理", 2D) = "black" {}
		_NoiseSpeedX("噪波速度X", Float) = 0
		_NoiseSpeedY("噪波速度Y", Float) = 0


		[Space(20)]
		[Header(__DISSOLVE__)]				
		[Toggle(_DISSOLVE)]_DissolveOn ("溶解开关", Float) = 0
		
		_DissolveTex("溶解贴图", 2D) = "white"{}
		_dissolveIntensity("溶解强度", Range(-1, 1)) = 0
		_dissolveSoftnessIntensity("溶解边缘柔软度", Range(0, 1)) = 0
		[HDR]_dissolveBrightnessColor("溶解亮边颜色", Color) = (1, 1, 1, 1)
		_dissolveBrightnessWidth("溶解亮边宽度", Range(0, 1)) = 0.1
	}

	SubShader
	{
		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }

		Pass
		{
			Cull Back
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On
			ZTest LEqual
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_local_fragment _ _DISSOLVE	//开启溶解

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct VertexInput
			{
				float4 vertex : POSITION;
				half4 color : COLOR;
				float3 normal : NORMAL;
				float4 uv1 : TEXCOORD0;
				float4 uv2 : TEXCOORD1;
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float4 uv : TEXCOORD3;
				float3 worldNormal : TEXCOORD4;
			};

			CBUFFER_START(UnityPerMaterial)
				half4 _VoTex_ST;
				half4 _VO_Mask_ST;
				half4 _MainTex_ST;
				half4 _FresnelColor;
				half4 _AddNoiseTex_ST;
				half4 _DissolveTex_ST;
				half4 _dissolveBrightnessColor;
				half3 _VoIntensity;
				half _VoSpeedX;
				half _VoSpeedY;
				half _FresnelPower;
				half _NoiseSpeedX;
				half _NoiseSpeedY;

				half _DissolveOn;
				half _dissolveIntensity;
				half _dissolveSoftnessIntensity;
				half _dissolveBrightnessWidth;
			CBUFFER_END
			sampler2D _VoTex;
			sampler2D _VO_Mask;
			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
			TEXTURE2D(_AddNoiseTex);	SAMPLER(sampler_AddNoiseTex);
			TEXTURE2D(_DissolveTex);	SAMPLER(sampler_DissolveTex);


			
			VertexOutput vert ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				half2 VoSpeed = half2(_VoSpeedX , _VoSpeedY);
				half2 uv2_VoTex = v.uv2.xy * _VoTex_ST.xy + _VoTex_ST.zw;
				half2 VoPanner = _Time.y * VoSpeed + uv2_VoTex;
				half4 VoColor = tex2Dlod( _VoTex, float4( VoPanner, 0, 0.0) );
				float2 uv2_VO_Mask = v.uv2.xy * _VO_Mask_ST.xy + _VO_Mask_ST.zw;
				
				half3 worldNormal = TransformObjectToWorldNormal(v.normal);
				o.worldNormal.xyz = worldNormal;
				o.uv.xy = v.uv1.xy;
				o.uv.zw = v.uv2.xy;

				float3 vertexValue = ( ( VoColor.r * _VoIntensity ) * v.color.a * tex2Dlod( _VO_Mask, float4( uv2_VO_Mask, 0, 0.0) ).rgb );
				v.vertex.xyz += vertexValue;

				v.normal = v.normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );
				o.worldPos = positionWS;
				o.clipPos = positionCS;
				return o;
			}


			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				float3 WorldPosition = IN.worldPos;
				float2 uv_MainTex = IN.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half4 mainColor = SAMPLE_TEXTURE2D( _MainTex,sampler_MainTex,uv_MainTex );
				float3 worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				worldViewDir = normalize(worldViewDir);
				half3 worldNormal = IN.worldNormal.xyz;
				half NdotV = saturate(dot( worldNormal, worldViewDir ));
				half fresnel = pow( 1.0 - NdotV, _FresnelPower );
				half2 NoiseSpeed = half2(_NoiseSpeedX , _NoiseSpeedY);
				half2 uv2_AddNoiseTex = IN.uv.zw * _AddNoiseTex_ST.xy + _AddNoiseTex_ST.zw;
				half2 AddNoiseSpeed = _Time.y * NoiseSpeed + uv2_AddNoiseTex;
				
				half3 finalCol = ( mainColor + ( saturate( fresnel ) * _FresnelColor ) + ( SAMPLE_TEXTURE2D( _AddNoiseTex, sampler_AddNoiseTex,AddNoiseSpeed ) * mainColor ) ).rgb;
				half alpha = 1;

				//return half4( Color, Alpha );

				//溶解
				#if _DISSOLVE
					half dissolveValue = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, IN.uv.zw * _DissolveTex_ST.xy + _DissolveTex_ST.zw).r;

					half dissolveIntensity = _dissolveIntensity;
					half clipValue = smoothstep(dissolveIntensity, dissolveIntensity + _dissolveSoftnessIntensity, dissolveValue);

					clip(clipValue - 0.001);
					
					half dissolveBrightnessArea = smoothstep(dissolveIntensity + _dissolveBrightnessWidth, dissolveIntensity + _dissolveSoftnessIntensity * saturate(_dissolveBrightnessWidth * 1000) + _dissolveBrightnessWidth, dissolveValue);

					finalCol = lerp(_dissolveBrightnessColor.rgb, finalCol, dissolveBrightnessArea);
					alpha = saturate(alpha * clipValue);
				#endif
				
				return half4(finalCol, alpha);


			}
			ENDHLSL
		}
	}
}