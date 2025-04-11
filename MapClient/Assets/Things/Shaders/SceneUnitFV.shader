Shader "XianXia/SceneUnitFV" {
	Properties {
		_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
		_Color ("Color", Color) = (1, 1, 1, 0.3)
		[HideInInspector]_ProceduralColor ("Procedural Color", Color) = (1, 1, 1, 1)
	}
	SubShader {
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		Blend SrcAlpha OneMinusSrcAlpha
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				float2 texcoord : TEXCOORD0;
				fixed4 color : COLOR;
			};

			fixed4 _ProceduralColor;
			sampler2D _MainTex;
			fixed4 _Color;
			float4 _MainTex_ST;
			fixed _Cutoff;

			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.color = v.color;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.texcoord) * i.color;
				col *= _ProceduralColor;
				clip(col.a - _Cutoff);
				return col * _Color;
			}
			ENDCG
		}
	}
}
