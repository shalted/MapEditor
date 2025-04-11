Shader "XianXia/SpineBlack"
{
	Properties
	{
		_MainTex ("Sprite Texture", 2D) = "white" {}
		_Color ("Tint", Color) = (1,1,1,1)

		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15

		_ColorfulTex("_ColorfulTex", Color) = (0.6, 0.6, 0.6, 1)
		_ColorfulTime("_ColorfulTime", Float) = 0.5
		_ColorfulStartTime("_ColorfulStartTime", Float) = 0

		[Toggle(GAME_GREY)] _Grey("是否灰度", Float) = 0
		[HideInInspector][HDR]_ProceduralColor ("Procedural Color", Color) = (1, 1, 1, 1)
	}

	SubShader
	{
		Tags
		{
			"Queue"="Transparent"
			"IgnoreProjector"="True"
			"RenderType"="DefaultUI"
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

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			#pragma multi_compile __ GAME_GREY

			struct appdata_t
			{
				float4 vertex   : POSITION;
				fixed4 color    : COLOR;
				float2 texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
                float2 uv  : TEXCOORD0;
				half4  mask : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;
            float _UIMaskSoftnessX;
            float _UIMaskSoftnessY;
			fixed4 _ProceduralColor;
			fixed4 _ColorfulTex;
            half _ColorfulTime;
            half _ColorfulStartTime;


			v2f vert(appdata_t IN)
			{
				v2f OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				UNITY_INITIALIZE_OUTPUT(v2f, OUT);
				OUT.vertex = UnityObjectToClipPos(IN.vertex);

				OUT.uv = TRANSFORM_TEX(IN.texcoord, _MainTex);

				OUT.color = IN.color * _Color;
				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 tex_col = (tex2D(_MainTex, IN.uv) + _TextureSampleAdd);

				fixed4 color = tex_col * IN.color;

				fixed leftT = 0.5;
				fixed right = 1 - leftT;

				//先慢提升，快速衰减
				fixed t = _Time.y - _ColorfulStartTime;
				fixed x = t / (_ColorfulTime * leftT);
				x = x - 1;
				x = x * x * x + 1;

				// fixed val = x * step(t, _ColorfulTime * 0.66) + smoothstep(_ColorfulTime, _ColorfulTime * 0.66, t) * step(_ColorfulTime * 0.66, t);
				fixed val = x * step(t, _ColorfulTime * leftT) + smoothstep(1, 0, (t - _ColorfulTime * leftT)/(_ColorfulTime * right)) * step(_ColorfulTime * leftT, t);


				// // 超过爆白时间，就用原本的颜色了
				val *= step(t, _ColorfulTime);

				color.rgb += _ColorfulTex.rgb * val;

				#ifdef GAME_GREY
				color.rgb = dot(color.rgb, unity_ColorSpaceLuminance.rgb);
				#endif
				return color * _ProceduralColor;
			}

			ENDCG
		}
	}
}
