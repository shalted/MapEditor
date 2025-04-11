Shader "Xcqy/VFX/Spec_UV2Star"
{
	Properties
	{
		_MainTex("主纹理", 2D) = "white" {}
		_StarTex("星空纹理", 2D) = "white" {}
		_StarSpeedX("星空速度X", Float) = 0
		_StarSpeedY("星空速度Y", Float) = 0
		_Lerp("星空插值", Range( 0 , 1)) = 0
		[HDR]_FresnelColor("边缘光颜色", Color) = (0,0,0,0)
		_FresnelPower("边缘光宽度", Float) = 0
		_SpecMask("R高光G星空", 2D) = "white" {}
		_SpecPower("高光范围", Float) = 0
		_SpecColor1("高光颜色", Color) = (0,0,0,0)
		_SpecIntensity("高光强度", Float) = 0
	}
	
	SubShader
	{
		
		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="AlphaTest" }

		Blend SrcAlpha OneMinusSrcAlpha
		Cull Back
		ZWrite On

		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="UniversalForward" }
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"  
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"  
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"  
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"  
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"  
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"  
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"


			struct appdata
			{
				float4 vertex : POSITION;
				float4 uv1 : TEXCOORD0;
				float4 uv2 : TEXCOORD1;
				half3 normal : NORMAL;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
			};
			
			TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
			TEXTURE2D(_SpecMask);		SAMPLER(sampler_SpecMask);			
			TEXTURE2D(_StarTex);	SAMPLER(sampler_StarTex);	
			uniform half4 _MainTex_ST;
			uniform half4 _StarTex_ST;
			uniform half4 _SpecMask_ST;
			uniform half4 _FresnelColor;
			uniform half4 _SpecColor1;
			uniform half _StarSpeedX;
			uniform half _StarSpeedY;
			uniform half _FresnelPower;
			uniform half _Lerp;
			uniform half _SpecPower;
			uniform half _SpecIntensity;

			
			v2f vert ( appdata v )
			{
				v2f o;

				o.worldNormal.xyz = TransformObjectToWorldNormal(v.normal);
				o.uv.xy = v.uv1.xy;
				o.uv.zw = v.uv2.xy;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			half4 frag (v2f i ) : SV_Target
			{
				float3 WorldPosition = i.worldPos;
				float2 uv_MainTex = i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half2 StarSpeed = half2(_StarSpeedX , _StarSpeedY);
				half2 uv2_StarTex = i.uv.zw * _StarTex_ST.xy + _StarTex_ST.zw;
				half2 StarPanner =  _Time.y * StarSpeed + uv2_StarTex;
				float2 uv_SpecMask = i.uv.xy * _SpecMask_ST.xy + _SpecMask_ST.zw;
				half4 SpecTex = SAMPLE_TEXTURE2D( _SpecMask, sampler_SpecMask, uv_SpecMask );
				float3 worldViewDir = GetCameraPositionWS() - i.worldPos;//UnityWorldSpaceViewDir(WorldPosition);
				worldViewDir = normalize(worldViewDir);
				half3 worldNormal = i.worldNormal.xyz; 
				half NdotV = dot( worldNormal, worldViewDir );
				half fresnel = ( 0.0 + 1.0 * saturate(pow( 1.0 - NdotV, _FresnelPower )) );
				half4 lerpResult = lerp( SAMPLE_TEXTURE2D( _MainTex, sampler_MainTex, uv_MainTex ) , ( SAMPLE_TEXTURE2D( _StarTex, sampler_StarTex, StarPanner ) + ( SpecTex.g * ( saturate( fresnel ) * _FresnelColor ) ) ) , ( SpecTex.g * _Lerp ));
				half3 normalizedWorldNormal = normalize( worldNormal );
				half3 worldSpaceLightDir = normalize(_MainLightPosition.xyz-i.worldPos);
				worldViewDir = normalize( worldViewDir );
				half3 H = normalize( ( worldSpaceLightDir + worldViewDir ) );
				half NdotH = dot( normalizedWorldNormal , H );
				
				
				half4 finalColor = ( lerpResult + ( max( saturate( pow( ( ( NdotH * 0.5 ) + 0.5 ) , _SpecPower ) ) , 0.001 ) * _SpecColor1 * SpecTex.r * _SpecIntensity ) );
				return finalColor;
			}
			ENDHLSL
		}
	}
}