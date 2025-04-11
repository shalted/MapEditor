
Shader "ShiYue/MeshEffect/FresnelAddTex"
{
	Properties
	{
		_MainTex("主纹理贴图", 2D) = "white" {}
		_MainIntensity("主纹理亮度", Range( 0 , 1)) = 0
		_SubTex("花纹纹理", 2D) = "white" {}
		[HDR]_SubColor("花纹颜色", Color) = (1,1,1,0)
		[HDR]_FresnelColor("边缘光颜色", Color) = (1,1,1,0)
		_FresnelPower("边缘光宽度", Float) = 3
		_AddTex("加纹理贴图", 2D) = "black" {}
		_AddColor("AddColor", Color) = (1,1,1,0)
		_AddSpeedX("加纹理速度X", Float) = 0
		_AddSpeedY("加纹理速度Y", Float) = 0
		_NoiseTex("扰动纹理", 2D) = "white" {}
		_NoiseSpeedX("扰动纹理速度X", Float) = 0
		_NoiseSpeedY("扰动纹理速度Y", Float) = 0
		_NoiseIntensity("扰动强度", Float) = 0
		
		[CustomGroup] _DissolveSetting("溶解设置（特效）",float) = 1.0 
		[CustomToggle(_DissolveSetting, _DISSOLVE)] _DissolveOn ("开关", Float) = 0
		[CustomHeader(_DissolveSetting._DISSOLVE)] _DissolveTip("只对半透材质有效", Float) = 0
    	[CustomTexture(_DissolveSetting._DISSOLVE)] _DissolveTex("溶解贴图", 2D) = "white"{}
    	[CustomObject(_DissolveSetting._DISSOLVE)] _dissolveIntensity("溶解强度", Range(-1, 1)) = 0
		[CustomObject(_DissolveSetting._DISSOLVE)] _dissolveSoftnessIntensity("溶解边缘柔软度", Range(0, 1)) = 0
    	[CustomObject(_DissolveSetting._DISSOLVE)] [HDR]_dissolveBrightnessColor("溶解亮边颜色", Color) = (1, 1, 1, 1)
	    [CustomObject(_DissolveSetting._DISSOLVE)] _dissolveBrightnessWidth("溶解亮边宽度", Range(0, 1)) = 0.1
	}

	SubShader
	{
		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
		Cull Back
		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_local_fragment _ _DISSOLVE

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 uv1 : TEXCOORD0;
				float4 uv2 : TEXCOORD1;
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				#ifdef ASE_FOG
				float fogFactor : TEXCOORD1;
				#endif
				float4 uv : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _DissolveTex_ST;//溶解设置
			float4 _MainTex_ST;
			float4 _FresnelColor;
			float4 _AddTex_ST;
			float4 _NoiseTex_ST;
			float4 _AddColor;
			float4 _SubTex_ST;
			float4 _SubColor;
			float _MainIntensity;
			float _FresnelPower;
			float _AddSpeedX;
			float _AddSpeedY;
			float _NoiseSpeedX;
			float _NoiseSpeedY;
			float _NoiseIntensity;

			half4 _dissolveBrightnessColor;
			half _dissolveBrightnessWidth;
			half _dissolveSoftnessIntensity;
			half _dissolveIntensity;

			CBUFFER_END
			sampler2D _MainTex;
			sampler2D _AddTex;
			sampler2D _NoiseTex;
			sampler2D _SubTex;
			TEXTURE2D(_DissolveTex);    SAMPLER(sampler_DissolveTex);


						
			VertexOutput vert ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				float3 worldNormal = TransformObjectToWorldNormal(v.normal);
				o.worldNormal.xyz = worldNormal;
				
				o.uv.xy = v.uv1.xy;
				o.uv.zw = v.uv2.xy;
				v.normal = v.normal;
				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );
				o.worldPos = positionWS;

				#ifdef ASE_FOG
				o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif
				o.clipPos = positionCS;
				return o;
			}


			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				float3 WorldPosition = IN.worldPos;
				float2 uv_MainTex = IN.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				half4 mainColor = tex2D( _MainTex, uv_MainTex );
				float3 worldViewDir = _WorldSpaceCameraPos.xyz - WorldPosition;
				worldViewDir = normalize(worldViewDir);
				float3 worldNormal = IN.worldNormal.xyz;
				half NdotV = dot( worldNormal, worldViewDir );
				half fresnelNode = pow( abs(1.0 - NdotV), _FresnelPower );
				half2 AddSpeed = float2(_AddSpeedX , _AddSpeedY);
				float2 uv2_AddTex = IN.uv.zw * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 AddPanner =  _Time.y * AddSpeed + uv2_AddTex;
				half2 NoiseSpeed = float2(_NoiseSpeedX , _NoiseSpeedY);
				float2 uv2_NoiseTex = IN.uv.zw * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
				half2 NoisePanner =  _Time.y * NoiseSpeed + uv2_NoiseTex;
				float2 uv_SubTex = IN.uv.xy * _SubTex_ST.xy + _SubTex_ST.zw;

				half3 Color = ( _MainIntensity * mainColor + saturate( fresnelNode ) * _FresnelColor * mainColor.a + tex2D( _AddTex, ( AddPanner +  tex2D( _NoiseTex, NoisePanner ).r * _NoiseIntensity ) )  * _AddColor * mainColor.a + tex2D( _SubTex, uv_SubTex ).r * _SubColor * mainColor.a ).rgb;
				float Alpha = 1;


				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				#if _DISSOLVE
				half dissolveValue = SAMPLE_TEXTURE2D(_DissolveTex, sampler_DissolveTex, IN.uv * _DissolveTex_ST.xy + _DissolveTex_ST.zw).r;
				
				half dissolveIntensity = _dissolveIntensity;
				half clipValue = smoothstep(dissolveIntensity, dissolveIntensity + _dissolveSoftnessIntensity, dissolveValue);
				
				clip(clipValue - 0.001);
    			        	
				half dissolveBrightnessArea = smoothstep(dissolveIntensity + _dissolveBrightnessWidth, dissolveIntensity + _dissolveSoftnessIntensity * saturate(_dissolveBrightnessWidth * 1000) + _dissolveBrightnessWidth, dissolveValue);
				
				Color = lerp(_dissolveBrightnessColor.rgb, Color, dissolveBrightnessArea);
				Alpha = saturate(Alpha * clipValue);
				
				#endif
				
				return half4( Color, Alpha );
			}

			ENDHLSL
		}
	}

}
