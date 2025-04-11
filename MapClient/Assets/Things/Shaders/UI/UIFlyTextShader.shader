Shader "UI/FlyTextShader"
{
	Properties
	{
		_MainTex ("Sprite Texture", 2D) = "white" {}
		_TexCurve ("TexCurve",2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255


		_ColorMask ("Color Mask", Float) = 15

		//[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
		
		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp] 
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		Blend SrcAlpha OneMinusSrcAlpha
		//Blend SrcAlpha OneMinusSrcAlpha
		ColorMask [_ColorMask]

		Pass
		{
			Name "FlyTextShader"
		CGPROGRAM
			#pragma enable_d3d11_debug_symbols

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"
			#include "./CompressUtils.hlsl"
			#include "UnityUI.cginc"

			//#pragma multiCompile __ UNITY_UI_ALPHACLIP
			
			struct appdata_t
			{
				float4 vertex   : POSITION;  //world pos
				float4 normal    : NORMAL;   //offsets
				float2 texcoord : TEXCOORD0; //uv
				float2 texcoord1: TEXCOORD1; //x: duration, y: startTime(Time.timeSinceLevelLoad), z: scale
				fixed4 color    : COLOR;	 //x: moveDir.x, y: moveDir.y, z: moveDir.z, w: 
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				half2 texcoord  : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				half2 extra		: TEXCOORD2;
			};
			
			fixed4 _Color;
			fixed4 _TextureSampleAdd;

			int texCurveHeight;
			sampler2D _TexCurve; //r:xCurve, g:yCurve, b:scale, a:alpha
			// Texture2D<float4> _TexCurve;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				float duration;
				float scale;
				DecompressFloat(IN.texcoord1.x, duration, scale);
				float time=saturate((_Time.y - IN.texcoord1.y) / duration);

				float4 posScaleAlpa=tex2Dlod(_TexCurve,float4(time,IN.color.w,0,0)).xyzw;
				OUT.worldPosition =IN.vertex+IN.normal * scale;

				// OUT.worldPosition=OUT.worldPosition+posScaleAlpa.x*float4(IN.color.xyz,0);
				const float x_curve = posScaleAlpa.x;
				const float y_curve = posScaleAlpa.y;
				OUT.worldPosition += float4(x_curve * IN.color.x, y_curve * IN.color.y, IN.color.z, 0);
				
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
				OUT.texcoord = IN.texcoord;
				OUT.color.rgb = _Color;
				OUT.color.a = 1 * posScaleAlpa.w;
				OUT.extra = IN.texcoord1;
				return OUT;
			}

			sampler2D _MainTex;

			fixed4 frag(v2f IN) : SV_Target
			{
				half4 color = tex2D(_MainTex, IN.texcoord);
				return color*IN.color*_Color;
			}
		ENDCG
		}
	}
}
