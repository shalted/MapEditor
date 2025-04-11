Shader "ShouWang/EffectBase"
{
	Properties
	{
        [Enum(Additive,1,AlphaBlend,10)]_BlendModeDst("混合模式",Int) = 10
		[Enum(UnityEngine.Rendering.CullMode)]_CullMode("剔除模式",Int) = 2
		_MainTex("主纹理", 2D) = "white" {}
		[HDR]_MainColor ("主颜色", Color) = (1,1,1,1)

	}

	Category
	{
		SubShader
		{

			Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "RenderType"="Transparent" }


			

			Pass
			{
				Cull  [_CullMode]
				ZWrite Off
				Blend One [_BlendModeDst]

				
				HLSLPROGRAM

				#pragma vertex vert
				#pragma fragment frag
				#pragma multi_compile_instancing
				#pragma shader_feature _BLENDMODE_ADDITIVE _BLENDMODE_ALPHABLEND
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
				#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
				#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

				struct appdata
				{
					float4 vertex : POSITION;
					float4 color : COLOR;
					float4 uv : TEXCOORD0;
					
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float4 color : COLOR;
					float4 uv : TEXCOORD0;
					
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};
				

				
				TEXTURE2D(_MainTex);	SAMPLER(sampler_MainTex);
				CBUFFER_START( UnityPerMaterial )
				float4 _MainTex_ST,_MainColor;
				CBUFFER_END

				v2f vert ( appdata v  )
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);

					o.vertex = TransformObjectToHClip(v.vertex.xyz);
					o.color = v.color;
					o.uv = v.uv;
					return o;
				}

				half4 frag ( v2f i  ) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID( i );
					float2 uv_Maintex = TRANSFORM_TEX(i.uv.xy, _MainTex);

					
					half4 col =  SAMPLE_TEXTURE2D( _MainTex,sampler_MainTex, uv_Maintex )  * i.color;
					col.rgb *= col.a;

					return col;
				}
				ENDHLSL
			}
		}
	}

}