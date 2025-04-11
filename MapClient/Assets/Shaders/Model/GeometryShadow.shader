//####copyRight LuoYao 2019/8

Shader "XianXia/GeometryShadow"
{
	Properties
	{
		_ShadowPlane("Shadow Plane", Vector) = (0, -2.747478, 1.585, 0.02)
		_ShadowColor("Shadow Color", Color) = (0, 0, 0, 0.294)
		_lightDirection("LightDir", Vector) = (15.3, 59.6, -169.7,1)
		_WorldOffset("_WorldOffset", Vector) = (0, 0, 0, 0)
		_WorldScale("_WorldScale", float) = 1
	}
	SubShader
	{
		Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" "RenderObjectType" = "Shadow" }

		pass{
			Name "SHADOW"
			Stencil {
				Ref 2
				Comp NotEqual
				Pass Replace
			}
			Lighting Off
			Cull Back
			ZTest LEqual
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex GameShadowVert
			#pragma fragment GameShadowFrag
			#pragma multi_compile __ GAME_DIR_DISSOLUTION
			#pragma multi_compile __ USE_PERSPECTIVE_MATRIX
			#include "../CGInclude/GameCGDefines.cginc"

			struct v2f {
				float4 pos : SV_POSITION;
				#if GAME_DIR_DISSOLUTION
				float2 uv : TEXCOORD1;
				GAME_DIR_DISSOLUTION_COORDS(2)
				#endif
			};

			uniform half4 _ShadowPlane;
			uniform half4 _ShadowPara;
			uniform half3 _lightDirection;
			uniform fixed4 _ShadowColor;
			uniform half3 _WorldOffset;
			float _WorldScale;

			v2f GameShadowVert(appdata_base v)
			{
				v2f o;
				v.vertex.xyz = v.vertex.xyz * _WorldScale;
				float3 vt = mul(unity_ObjectToWorld , v.vertex).xyz;
				float3 tmpvar_3 = (vt - (( (dot (_ShadowPlane.xyz, vt) - _ShadowPlane.w) / dot (_ShadowPlane.xyz, _lightDirection)) * _lightDirection));
				tmpvar_3.xyz += _WorldOffset.xyz;

				#if GAME_DIR_DISSOLUTION
				o.uv = v.texcoord;
				GAME_TRANSFER_DIR_DISSOLUTION(o, vt);
				#endif
				#ifdef USE_PERSPECTIVE_MATRIX
				o.pos = GetPerspectiveClipPos(tmpvar_3);
				#else
				o.pos = mul(UNITY_MATRIX_VP , float4(tmpvar_3, 1));
				#endif
				return o;
			}

			fixed4 GameShadowFrag(v2f f) : COLOR
			{
				fixed4 color = _ShadowColor;
				GAME_APPLY_DIR_DISSOLUTION_NO_COLOR(f);
				return color;
			}
			ENDCG
		}
	}
}
