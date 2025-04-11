Shader "Hidden/RendererGlow/CameraReplaceRender" {
	Subshader
	{
		Tags{ "RenderType" = "RendererGlowObject" }
		Pass {
			//Blend SrcAlpha OneMinusSrcAlpha
			//ZWrite Off
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
				return fixed4(1, 1, 1, 1);
			}
			ENDHLSL
		}
	}
	Subshader
	{
		Tags{ "RenderType" = "Opaque" }
		Pass {
			//Blend SrcAlpha OneMinusSrcAlpha
			//ZWrite Off
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
				return fixed4(0, 0, 0, 1);
			}
			ENDHLSL
		}
	}
	Subshader
	{
		Tags{ "RenderType" = "DefaultUI" }
		Pass {
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

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

            #pragma multi_compile __ UNITY_UI_CLIP_RECT
			#pragma multi_compile __ UNITY_UI_ALPHACLIP

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
				float4 worldPosition : TEXCOORD1;
			};

			sampler2D _MainTex;
			fixed4 _Color;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
				OUT.uv = IN.texcoord;
				OUT.color = IN.color * _Color;
				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target
			{
				fixed4 color = (tex2D(_MainTex, IN.uv) + _TextureSampleAdd) * IN.color;
				return fixed4(0, 0, 0, color.a);
			}
			ENDHLSL
		}
	}
}
