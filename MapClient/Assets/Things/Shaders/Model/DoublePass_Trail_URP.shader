Shader "Xcqy/VFX/DoublePass_Trail"
{
	Properties
	{
		_MaskTex("颜色渐变遮罩", 2D) = "white" {}
		_MaskSpeedX("遮罩速度X", Float) = 0
		_MaskSpeedY("遮罩速度Y", Float) = 0
		[HDR]_FrontColor1("正面渐变颜色1", Color) = (0,0,0,0)
		[HDR]_FrontColor2("正面渐变颜色2", Color) = (0,0,0,0)
		[HDR]_BackColor1("背面渐变颜色1", Color) = (0,0,0,0)
		[HDR]_BackColor2("背面渐变颜色2", Color) = (0,0,0,0)
		_NoiseTex("正面花纹", 2D) = "black" {}
		_NoiseSpeedX("正面花纹速度X", Float) = 0
		_NoiseSpeedY("正面花纹速度Y", Float) = 0
		[HDR]_FrontColor3("正面花纹颜色", Color) = (0,0,0,0)
		_Noise2Tex("背面花纹", 2D) = "black" {}
		_Noise2SpeedX("背面花纹速度X", Float) = 0
		_Noise2SpeedY("背面花纹速度Y", Float) = 0
		[HDR]_BackColor3("背面花纹颜色", Color) = (0,0,0,0)
		_EffMask("R光边 G透明度 B正面花纹遮罩", 2D) = "black" {}
		[HDR]_FrontColor4("正面光边颜色", Color) = (0,0,0,0)
		[HDR]_BackColor4("背面光边颜色", Color) = (0,0,0,0)

	}
	
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }


		Pass
		{
			Tags { "LightMode" = "UniversalForward" }
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Front
			ZWrite On
			ZTest LEqual
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float3 normal : NORMAL;
				float4 uv : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float2 uv : TEXCOORD1;
			};

			TEXTURE2D(_MaskTex);	SAMPLER(sampler_MaskTex);
			TEXTURE2D(_NoiseTex);	SAMPLER(sampler_NoiseTex);
			TEXTURE2D(_Noise2Tex);	SAMPLER(sampler_Noise2Tex);
			TEXTURE2D(_EffMask);	SAMPLER(sampler_EffMask);
			CBUFFER_START(UnityPerMaterial)
			uniform half _MaskSpeedX;
			uniform half _MaskSpeedY;
			uniform half4 _MaskTex_ST;
			uniform half _NoiseSpeedX;
			uniform half _NoiseSpeedY;
			uniform half4 _NoiseTex_ST;
			uniform half _Noise2SpeedX;
			uniform half _Noise2SpeedY;
			uniform half4 _Noise2Tex_ST;
			uniform half4 _EffMask_ST;
			uniform half4 _BackColor1;
			uniform half4 _BackColor2;
			uniform half4 _BackColor3;
			uniform half4 _BackColor4;
			CBUFFER_END
			
			v2f vert ( appdata v )
			{
				v2f o;

				o.uv.xy = v.uv.xy;
				float3 worldNormal = TransformObjectToWorldNormal(v.normal);

				float3 vertexValue = ( worldNormal * 0.001 );

				v.vertex.xyz += vertexValue;
				float3 positionWS = TransformObjectToWorld(v.vertex);
                float4 positionCS = TransformWorldToHClip(positionWS);
				o.vertex = positionCS;

				o.worldPos = positionWS;
				return o;
			}
			
			
			half4 frag (v2f i , half ase_vface : VFACE) : SV_Target
			{
				float3 WorldPosition = i.worldPos;
				half2 MaskSpeed = float2(_MaskSpeedX , _MaskSpeedY);
				float2 uv_MaskTex = i.uv.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half2 MaskPanner = _Time.y * MaskSpeed + uv_MaskTex;
				float4 MaskColor = SAMPLE_TEXTURE2D( _MaskTex,sampler_MaskTex, MaskPanner );
				half2 Noise2Speed = float2(_Noise2SpeedX , _Noise2SpeedY);
				float2 uv_Noise2Tex = i.uv.xy * _Noise2Tex_ST.xy + _Noise2Tex_ST.zw;
				half2 Noise2Panner = _Time.y * Noise2Speed + uv_Noise2Tex;
				half4 Noise2Color = SAMPLE_TEXTURE2D( _Noise2Tex,sampler_Noise2Tex, Noise2Panner );
				float2 uv_EffMask = i.uv.xy * _EffMask_ST.xy + _EffMask_ST.zw;
				half4 EffMaskColor = SAMPLE_TEXTURE2D( _EffMask, sampler_EffMask,uv_EffMask );
				half4 MainColorLerp = lerp( _BackColor1 , _BackColor2 , MaskColor.r);
				half4 switchResult1 = MainColorLerp + Noise2Color.r * _BackColor3 + EffMaskColor.r * _BackColor4;
				half4 finalColor = float4(switchResult1.rgb , EffMaskColor.g);
				return finalColor;
			}
			ENDHLSL
		}

		Pass
		{
			Tags { "LightMode" = "UniversalForwardOnly" }
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Back 
			ZWrite On
			ZTest LEqual
			HLSLPROGRAM

		
			#pragma vertex vert
			#pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float3 normal : NORMAL;
				float4 uv : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float2 uv : TEXCOORD1;
			};

			TEXTURE2D(_MaskTex);	SAMPLER(sampler_MaskTex);
			TEXTURE2D(_NoiseTex);	SAMPLER(sampler_NoiseTex);
			TEXTURE2D(_Noise2Tex);	SAMPLER(sampler_Noise2Tex);
			TEXTURE2D(_EffMask);	SAMPLER(sampler_EffMask);
			CBUFFER_START(UnityPerMaterial)
			uniform half _MaskSpeedX;
			uniform half _MaskSpeedY;
			uniform half4 _MaskTex_ST;
			uniform half _NoiseSpeedX;
			uniform half _NoiseSpeedY;
			uniform half4 _NoiseTex_ST;
			uniform half _Noise2SpeedX;
			uniform half _Noise2SpeedY;
			uniform half4 _Noise2Tex_ST;
			uniform half4 _EffMask_ST;
			uniform half4 _FrontColor1;
			uniform half4 _FrontColor2;
			uniform half4 _FrontColor3;
			uniform half4 _FrontColor4;
			CBUFFER_END

			
			v2f vert ( appdata v )
			{
				v2f o;

				o.uv.xy = v.uv.xy;
				float3 worldNormal = TransformObjectToWorldNormal(v.normal);

				float3 vertexValue = ( worldNormal * -0.001 );

				v.vertex.xyz += vertexValue;
				float3 positionWS = TransformObjectToWorld(v.vertex);
                float4 positionCS = TransformWorldToHClip(positionWS);
				o.vertex = positionCS;

				o.worldPos = positionWS;
				return o;
			}
			
			
			half4 frag (v2f i , half ase_vface : VFACE) : SV_Target
			{

				float3 WorldPosition = i.worldPos;
				half2 MaskSpeed = float2(_MaskSpeedX , _MaskSpeedY);
				float2 uv_MaskTex = i.uv.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				half2 MaskPanner = _Time.y * MaskSpeed + uv_MaskTex;
				half4 MaskColor = SAMPLE_TEXTURE2D( _MaskTex,sampler_MaskTex, MaskPanner );
				half4 lerpResult6 = lerp( _FrontColor1 , _FrontColor2 , MaskColor.r);
				half2 NoiseSpeed = float2(_NoiseSpeedX , _NoiseSpeedY);
				float2 uv_NoiseTex = i.uv.xy * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
				half2 NoisePanner =  _Time.y * NoiseSpeed + uv_NoiseTex;
				half4 NoiseColor = SAMPLE_TEXTURE2D( _NoiseTex,sampler_NoiseTex, NoisePanner );
				float2 uv_EffMask = i.uv.xy * _EffMask_ST.xy + _EffMask_ST.zw;
				half4 EffMaskColor = SAMPLE_TEXTURE2D( _EffMask,sampler_EffMask, uv_EffMask );
				float NoiseMask = saturate(1.0 - NoiseColor.r + (1-EffMaskColor.b) )   ;
				half4 switchResult1 = ( ( lerpResult6 * NoiseMask ) + ( NoiseColor.r * _FrontColor3 * EffMaskColor.b) ) + ( _FrontColor4 * EffMaskColor.r ) ;
				half4 finalColor = float4(switchResult1.rgb , EffMaskColor.g);

				return finalColor;
			}
			ENDHLSL
		}
		
	}
}