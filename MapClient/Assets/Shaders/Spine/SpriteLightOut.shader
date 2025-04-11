Shader "XianXia/SpriteLightOut" {
	Properties{
		_MainTex("Sprite Texture", 2D) = "white"{}
		_MainColor("Main Color", Color) = (1,1,1,1)
		_LtSoft("Light Soft", Range(0, 8)) = 1
		_LtExpand("Light Expand", float) = 1
		_LtOuterStrength("Outer Light Strength", Range(0, 10)) = 1
		_LtColor("LtColor", Color) = (1,1,1,1)

		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15

		[Toggle(GAME_GREY)] _Grey("是否灰度", Float) = 0
	}
		SubShader{
			Tags {
				"Queue" = "Transparent"
				"RenderType" = "Transparent"
				"IgnoreProjector" = "True"
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

			pass {
				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"

				sampler2D _MainTex;
				int _LtSoft;
				float _LtExpand;
				float _LtOuterStrength;
				float2 _MainTex_TexelSize;
				fixed4 _LtColor;
				fixed4 _MainColor;
				float4 _MainTex_ST;
				#pragma multi_compile __ GAME_GREY


				struct v2f {
					float4 vertex : POSITION;
					float2 uv: TEXCOORD;
				};

				v2f vert(appdata_base v) {
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
					return o;
				}

				fixed4 frag(v2f i) : COLOR {
					fixed alpha = 0;
					fixed4 raw_col = tex2D(_MainTex, i.uv)*_MainColor;
					#ifdef GAME_GREY
						raw_col.rgb = dot(raw_col.rgb, unity_ColorSpaceLuminance.rgb);
					#endif
					float _LtSoft2 = _LtSoft * _LtSoft;
					for (int r1 = -_LtSoft; r1 <= _LtSoft; r1++) {
						for (int r2 = -_LtSoft; r2 <= _LtSoft; r2++) {
							// alpha += lerp(0, tex2D(_MainTex, float2(_MainTex_TexelSize.x*r1, _MainTex_TexelSize.y*r2)*_LtExpand + i.uv).a
							// 	, step(r1 * r1 + r2 * r2, _LtSoft2));
							alpha += tex2D(_MainTex, float2(_MainTex_TexelSize.x*r1, _MainTex_TexelSize.y*r2)*_LtExpand + i.uv).a;
						}
					}

					float rate = 1.0 / (2 * _LtSoft + 1);
					alpha *= rate * rate;
					fixed4 outLight = fixed4(_LtColor.rgb, alpha)*_LtOuterStrength;
					return lerp(outLight, raw_col, raw_col.a);
				}

				ENDCG
			}
		}
}