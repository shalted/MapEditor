Shader "XianXia/CommonFuncs"
{
	Properties
	{
		_MainTex("_MainTex", 2D) = "white" {}
		_Color("_Color", Color) = (1, 1, 1, 1)
	}

	SubShader
	{
		Pass{ //Draw Texture Combine
			ZWrite Off
			ZTest Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "CGInclude/GameCGDefines.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
			};
			v2f vert(in float2 texcoord : TEXCOORD0, in float4 vertex : POSITION)
			{
				v2f o;
				o.pos = UVToClipPos(vertex);
				o.uv = TRANSFORM_TEX(texcoord, _MainTex);
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				return tex2D(_MainTex, i.uv) * _Color;
			}
			ENDCG
		}

		Pass {//Draw Face Anim Part
			ZWrite Off
			ZTest Off
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};
			struct v2f {
				float4 vertex : SV_POSITION;
				float2 texcoord : TEXCOORD0;
			};
			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord);
				return col;
			}
			ENDCG
		}

		Pass{ //Draw War Cloud Mask
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			ZTest Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
			};
			sampler2D _MainTex;
			float4 _ScreenST;
			fixed4 _Color;
			half _AlphaOffset;

			v2f vert(in float2 texcoord : TEXCOORD0)
			{
				v2f o;
				float2 screenUV = texcoord * _ScreenST.xy + _ScreenST.zw;
				float4 clipPos = float4(1, _ProjectionParams.x, 0, 1);
				clipPos.xy *= (screenUV * 2 - 1);
				o.pos = clipPos;
				o.uv = texcoord;
				return o;
			}
			fixed4 frag(v2f i) : SV_Target
			{
				half4 color = tex2D(_MainTex, i.uv);
				color.a = saturate(color.a + _AlphaOffset) * _Color.a;
				return color;
			}
			ENDCG
		}

		Pass {//Draw Base Face Anim
			ZWrite Off
			ZTest Off
			Blend One Zero
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};
			struct v2f {
				float4 vertex : SV_POSITION;
				float2 texcoord : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord);
				return col;
			}
			ENDCG
		}

		Pass {
			Name "DEPTH_WRITE"
			Blend Zero One
			ZWrite On
			ZTest LEqual
			Cull Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "CGInclude/GameCGDefines.cginc"

			float4 vert (float4 vertex : POSITION) : SV_POSITION
			{
				return CustomObjectToClipPos(vertex);
			}		
			fixed4 frag () : SV_Target
			{
				return fixed4(0, 0, 0, 0);
			}
			ENDCG
		}
	}
}
