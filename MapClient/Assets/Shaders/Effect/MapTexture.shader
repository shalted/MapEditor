Shader "XianXia/MapTexture"
{
	Properties
	{
		_MainTex ("_MainTex", 2D) = "white" {}
		_Color ("_Color", Color) = (1, 1, 1, 1)
		[Toggle(GAME_GREY)] _Grey ("Grey", int) = 0
		[HideInInspector]_ProceduralColor ("Procedural Color", Color) = (1, 1, 1, 1)
	}
	SubShader
	{
		Tags{"RenderType" = "RenderType" "Queue" = "Transparent" }
		Pass
		{
			Lighting Off
			Cull Back

			CGPROGRAM
			#include "../CGInclude/GameCGDefines.cginc"
			#pragma multi_compile __ GAME_GREY
			#pragma vertex vert
			#pragma fragment frag

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _Color;
				col *= _ProceduralColor;

				#if GAME_GREY
				col.rgb = dot(col.rgb, _GameGreyColor);
				#endif

				return col;
			}
			ENDCG
		}
	}
}
