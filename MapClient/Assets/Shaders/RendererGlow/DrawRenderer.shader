Shader "Hidden/RendererGlow/DrawRenderer" {
	Subshader
	{
		Tags{ "RenderType" = "RendererGlowObject" }
		Pass {
			Cull Off
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			float4 vert(float4 vertex : POSITION) : SV_POSITION
			{
				return UnityObjectToClipPos(vertex);
			}
			fixed4 frag() : SV_Target
			{
				return 0;
			}
			ENDHLSL
		}
	}
}
