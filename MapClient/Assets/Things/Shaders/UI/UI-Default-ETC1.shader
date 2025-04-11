Shader "UI/xProject-Default-ETC1"
{
	Properties
	{
		_MainTex ("Sprite Texture", 2D) = "white" {}
		_AlphaTex ("Alpha Channel", 2D) = "black" {}
		_Color ("Tint", Color) = (1,1,1,1)
		
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
		[Toggle(GAME_GREY)] _Grey("是否灰度", Float) = 0
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
		ZTest [unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask [_ColorMask]

		Pass
		{
			Name "Default"
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "../CGInclude/GameCGDefines.cginc"
			#include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma multi_compile __ GAME_GREY
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				fixed4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
			};

			sampler2D _AlphaTex;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.texcoord = IN.texcoord;
				
				#ifdef UNITY_HALF_TEXEL_OFFSET
				OUT.vertex.xy += (_ScreenParams.zw-1.0) * half2(-1, 1) * OUT.vertex.w;
				#endif
				
				OUT.color = IN.color * _Color;
				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 color = fixed4(tex2D(_MainTex, IN.texcoord).rgb + _TextureSampleAdd.rgb, tex2D(_AlphaTex, IN.texcoord).r + _TextureSampleAdd.a) * IN.color;
                
				#ifdef UNITY_UI_CLIP_RECT
				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
				#endif

				#ifdef UNITY_UI_ALPHACLIP
				clip (color.a - 0.001);
				#endif

				#ifdef GAME_GREY
				color.rgb = dot(color.rgb, _GameGreyColor);
				#endif

				return color;
			}
		ENDCG
		}
	}
}
