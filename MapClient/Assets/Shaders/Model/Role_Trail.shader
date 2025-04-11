Shader "Xcqy/VFX/Role_Trail"
{
	Properties
	{
		[Header(ColorLerp)]
		[HDR]_Color0("根部颜色", Color) = (0,0,0,0)
		[HDR]_Color2("远端颜色", Color) = (0,0,0,0)
		_ColorLerpMin("根部颜色占比", Range( 0 , 0.49)) = 0.22
		_ColorLerpMax("远端颜色占比", Range( 0.51 , 1)) = 0.71
		_Alpha("透明度-大于1为溶解填充率", Range( 0 , 5)) = 5
		[Header(AddTex)]
		_AddTex("加纹理", 2D) = "white" {}
		_Add_X_Speed("加纹理X轴速度", Float) = 0
		_Add_Y_Speed("加纹理Y轴速度", Float) = 0
		[HDR]_AddColor("加纹理颜色", Color) = (1,1,1,1)
		[Header(VertexOffset)]
		_VOTex("顶点偏移纹理", 2D) = "white" {}
		_VO_X_Speed("顶点偏移X轴速度", Float) = 0
		_VO_Y_Speed("顶点偏移Y轴速度", Float) = 0
		_VO_Intensity("顶点偏移强度", Float) = 0
		[Header(Dissolve)]
		_DissolveTex("溶解纹理", 2D) = "white" {}
		_Dissolve_X_Speed("溶解纹理X轴速度", Float) = 0
		_Dissolve_Y_Speed("溶解纹理Y轴速度", Float) = 0
		_Dissolve_Soft("溶解软硬度", Range( 0.51 , 1)) = 0.51
		_Dissolve("溶解进程", Range( 0 , 1)) = 0
		_Dissolve_Offset("溶解过渡偏移", Float) = 0
		[Header(Mask)]
		_MaskTex("遮罩纹理", 2D) = "white" {}
		_Mask_X_Speed("遮罩纹理X轴速度", Float) = 0
		_Mask_Y_Speed("遮罩纹理Y轴速度", Float) = 0
		[Header(Noise)]
		_NoiseTex("扰动纹理", 2D) = "white" {}
		_NoiseIntensity("扰动强度", Range( 0 , 1)) = 0.1
		_Noise_X_Speed("扰动纹理X轴速度", Float) = 0
		_Noise_Y_Speed("扰动纹理Y轴速度", Float) = 0


	}
	
	SubShader
	{
		
		Tags { "LightMode" = "UniversalForward" "RenderType"="Transparent" "Queue"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off
		ZWrite Off

		Pass
		{
			
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"



			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD1;
			};

            TEXTURE2D(_VOTex);	SAMPLER(sampler_VOTex);
            TEXTURE2D(_AddTex);	SAMPLER(sampler_AddTex);
            TEXTURE2D(_DissolveTex);	SAMPLER(sampler_DissolveTex);
            TEXTURE2D(_NoiseTex);	SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_MaskTex);	SAMPLER(sampler_MaskTex);
			uniform float4 _MaskTex_ST;
			uniform float4 _VOTex_ST;
			uniform float4 _AddTex_ST;
			uniform float4 _NoiseTex_ST;
			uniform float4 _DissolveTex_ST;
			uniform half4 _Color0;
			uniform half4 _Color2;
			uniform half4 _AddColor;

			uniform half _VO_Intensity;
			uniform half _VO_X_Speed;
			uniform half _VO_Y_Speed;
			uniform half _ColorLerpMin;
			uniform half _ColorLerpMax;
			uniform half _Add_X_Speed;
			uniform half _Add_Y_Speed;
			uniform half _Dissolve_Soft;
			uniform half _Dissolve_X_Speed;
			uniform half _Dissolve_Y_Speed;
			uniform half _Noise_X_Speed;
			uniform half _Noise_Y_Speed;
			uniform half _NoiseIntensity;
			uniform half _Dissolve;
			uniform half _Dissolve_Offset;
			uniform half _Mask_X_Speed;
			uniform half _Mask_Y_Speed;
			uniform half _Alpha;

			
			v2f vert ( appdata v )
			{
				v2f o;

				float2 uv1 = v.uv.xy;
				half2 VO_Speed = half2(_VO_X_Speed , _VO_Y_Speed);
				float2 uv_VOTex = v.uv.xy * _VOTex_ST.xy + _VOTex_ST.zw;
				float2 panner = _Time.y * VO_Speed + uv_VOTex;
				half3 vertexValue = _VO_Intensity * uv1.y * (-0.5 + SAMPLE_TEXTURE2D_LOD( _VOTex, sampler_VOTex, panner,0 ).r) * v.normal;
				v.vertex.xyz += vertexValue;
				o.uv.xy = v.uv.xy;

				float3 positionWS = TransformObjectToWorld(v.vertex);
                o.vertex = TransformWorldToHClip(positionWS);


				return o;
			}
			
			half4 frag (v2f i ) : SV_Target
			{
				
				float2 uv = i.uv.xy;
				half lerp1 = smoothstep( _ColorLerpMin , _ColorLerpMax , uv.y);
				half4 colorLerp = lerp( _Color0 , _Color2 , lerp1);
				half2 addSpeed = half2(_Add_X_Speed , _Add_Y_Speed);
				float2 uv_AddTex = i.uv.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				float2 addPanner = _Time.y * addSpeed + uv_AddTex;
				half2 dissolveSpeed = half2(_Dissolve_X_Speed , _Dissolve_Y_Speed);
				float2 uv_DissolveTex = i.uv.xy * _DissolveTex_ST.xy + _DissolveTex_ST.zw;
				float2 dissolvePanner = _Time.y * dissolveSpeed + uv_DissolveTex;
				half2 NoiseSpeed = half2(_Noise_X_Speed , _Noise_Y_Speed);
				float2 uv_NoiseTex = i.uv.xy * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
				float2 NoisePanner = _Time.y * NoiseSpeed + uv_NoiseTex;
				half dissolve = smoothstep( ( 1.0 - _Dissolve_Soft ) , _Dissolve_Soft , saturate(SAMPLE_TEXTURE2D( _DissolveTex,sampler_DissolveTex,dissolvePanner + SAMPLE_TEXTURE2D( _NoiseTex,sampler_NoiseTex, NoisePanner ).r * _NoiseIntensity ).r + 1.0 + ( _Dissolve * -2.0 ) + ( ( 1.0 - uv.y ) - _Dissolve_Offset )));
				half sideCut = smoothstep( 0.0 , 0.7 , ( 1.0 - uv.y ));
				half2 maskSpeed = half2(_Mask_X_Speed , _Mask_Y_Speed);
				float2 uv_MaskTex = i.uv.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				float2 maskPanner = _Time.y * maskSpeed + uv_MaskTex;
				half4 finalColor = half4(( colorLerp + SAMPLE_TEXTURE2D( _AddTex,sampler_AddTex, addPanner ).r * _AddColor).rgb , saturate( dissolve * sideCut * SAMPLE_TEXTURE2D( _MaskTex,sampler_MaskTex, maskPanner ).r * _Alpha ));


				
				return finalColor;
			}
			ENDHLSL
		}
	}
}