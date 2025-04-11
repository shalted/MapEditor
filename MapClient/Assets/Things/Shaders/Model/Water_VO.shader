// Made with Amplify Shader Editor v1.9.1.8
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Shiyue/URP/VFX/Water_VO"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		_BaseRamp("渐变纹理", 2D) = "white" {}
		[HDR]_RampColor("渐变色", Color) = (0,0,0,0)
		[HDR]_FresnelColor("边缘光颜色", Color) = (1,1,1,0)
		_FresnelPower("边缘光宽度", Float) = 5
		_FresnelSacle("边缘光亮度", Float) = 1
		_NoiseTex("扰动纹理", 2D) = "white" {}
		_NoiseSpeed("扰动纹理速度XY", Vector) = (0,0,0,0)
		_AddTex("叠加纹理", 2D) = "white" {}
		_AddColor("叠加纹理颜色（A渐变与叠加权重）", Color) = (0,0,0,0)
		_AddMaskOffset("叠加纹理遮罩偏移", Float) = 0
		_AddMaskMax("叠加纹理遮罩最大距离", Range( 0.1 , 5)) = 0.55
		_AddSpeed("叠加纹理速度XY", Vector) = (0,0,0,0)
		_AddNoiseIntensity("叠加纹理扰动强度", Range( 0 , 1)) = 0
		_LerpTex("混合纹理", 2D) = "white" {}
		[HDR]_LerpColor("混合纹理颜色", Color) = (0,0,0,0)
		_LerpSpeed("混合纹理速度", Vector) = (0,0,0,0)
		_LerpNoiseIntensity("混合纹理扰动强度", Float) = 0
		_LerpMask("混合纹理遮罩", 2D) = "white" {}
		_VOTex("顶点偏移纹理", 2D) = "white" {}
		_VOSpeed("顶点偏移速度", Vector) = (0,0,0,0)
		_VOIntensity("顶点偏移强度", Float) = 0
		_VOMask("顶点偏移遮罩", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		[Space(20)]
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("模型面模式", Float) = 0
	}
	
	Category
	{
		SubShader
		{
		LOD 0

			Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" }
			Blend SrcAlpha OneMinusSrcAlpha
			Cull [_Cull]
			ZWrite On
			ZTest LEqual

			Pass
			{
				HLSLPROGRAM
				#define ASE_SRP_VERSION 140008

				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastes
				#pragma target 2.0
				#pragma multi_compile_instancing
				//自定义预处理或宏
				
				//自定义预处理或宏
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
				#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
				#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

				struct appdata
				{
					float4 vertex : POSITION;
					half4 color : COLOR;
					//自定义数据
					float4 texcoord : TEXCOORD0;
					float3 normal : NORMAL;
					//自定义数据
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					half4 color : COLOR;
					//自定义数据
					float4 texcoord2 : TEXCOORD2;
					float4 texcoord3 : TEXCOORD3;
					float4 texcoord4 : TEXCOORD4;
					//自定义数据
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				//全局变量
				sampler2D _VOTex;
				sampler2D _VOMask;
				sampler2D _BaseRamp;
				sampler2D _AddTex;
				sampler2D _NoiseTex;
				sampler2D _LerpTex;
				sampler2D _LerpMask;
				CBUFFER_START( UnityPerMaterial )
				float4 _VOTex_ST;
				float4 _FresnelColor;
				float4 _VOMask_ST;
				float4 _RampColor;
				float4 _BaseRamp_ST;
				float4 _AddTex_ST;
				float4 _NoiseTex_ST;
				float4 _LerpMask_ST;
				float4 _LerpColor;
				float4 _LerpTex_ST;
				float4 _AddColor;
				float2 _VOSpeed;
				float2 _AddSpeed;
				float2 _NoiseSpeed;
				float2 _LerpSpeed;
				float _AddNoiseIntensity;
				float _AddMaskOffset;
				float _AddMaskMax;
				float _FresnelSacle;
				float _VOIntensity;
				float _LerpNoiseIntensity;
				float _FresnelPower;
				CBUFFER_END

				//全局变量

				v2f vert ( appdata v  )
				{
					v2f o;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_TRANSFER_INSTANCE_ID(v, o);
					//自定义算法板块
					float2 uv_VOTex = v.texcoord.xy * _VOTex_ST.xy + _VOTex_ST.zw;
					float2 panner59 = ( 1.0 * _Time.y * _VOSpeed + uv_VOTex);
					float2 uv_VOMask = v.texcoord.xy * _VOMask_ST.xy + _VOMask_ST.zw;
					float3 temp_cast_0 = (( tex2Dlod( _VOTex, float4( panner59, 0, 0.0) ).r * _VOIntensity * tex2Dlod( _VOMask, float4( uv_VOMask, 0, 0.0) ).r )).xxx;
					
					float3 worldPos = TransformObjectToWorld( (v.vertex).xyz );
					o.texcoord3.xyz = worldPos;
					float3 worldNormal = TransformObjectToWorldNormal(v.normal);
					o.texcoord4.xyz = worldNormal;
					
					o.texcoord2.xy = v.texcoord.xy;
					
					//setting value to unused interpolator channels and avoid initialization warnings
					o.texcoord2.zw = 0;
					o.texcoord3.w = 0;
					o.texcoord4.w = 0;
					//自定义算法板块
					v.vertex.xyz += temp_cast_0;
					o.vertex = TransformObjectToHClip(v.vertex.xyz);
					o.color = v.color;
					return o;
				}

				half4 frag ( v2f i  ) : SV_Target
				{
					UNITY_SETUP_INSTANCE_ID( i );
					//自定义算法板块
					float2 uv_BaseRamp = i.texcoord2.xy * _BaseRamp_ST.xy + _BaseRamp_ST.zw;
					float2 uv_AddTex = i.texcoord2.xy * _AddTex_ST.xy + _AddTex_ST.zw;
					float2 panner11 = ( 1.0 * _Time.y * _AddSpeed + uv_AddTex);
					float2 uv_NoiseTex = i.texcoord2.xy * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
					float2 panner19 = ( 1.0 * _Time.y * _NoiseSpeed + uv_NoiseTex);
					float4 tex2DNode18 = tex2D( _NoiseTex, panner19 );
					float4 tex2DNode9 = tex2D( _AddTex, ( panner11 + ( tex2DNode18.r * _AddNoiseIntensity ) ) );
					float2 texCoord27 = i.texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
					float smoothstepResult30 = smoothstep( 0.0 , _AddMaskMax , ( texCoord27.y + _AddMaskOffset ));
					float4 lerpResult32 = lerp( ( _RampColor * tex2D( _BaseRamp, uv_BaseRamp ) ) , ( tex2DNode9 * smoothstepResult30 * _AddColor * _AddColor.a ) , ( _AddColor.a * smoothstepResult30 * tex2DNode9.a ));
					float2 uv_LerpTex = i.texcoord2.xy * _LerpTex_ST.xy + _LerpTex_ST.zw;
					float2 panner37 = ( 1.0 * _Time.y * _LerpSpeed + uv_LerpTex);
					float4 tex2DNode34 = tex2D( _LerpTex, ( ( tex2DNode18.r * _LerpNoiseIntensity ) + panner37 ) );
					float2 uv_LerpMask = i.texcoord2.xy * _LerpMask_ST.xy + _LerpMask_ST.zw;
					float4 tex2DNode51 = tex2D( _LerpMask, uv_LerpMask );
					float4 lerpResult49 = lerp( lerpResult32 , ( tex2DNode34 * _LerpColor * _LerpColor.a * tex2DNode51.r ) , ( tex2DNode34.a * _LerpColor.a * tex2DNode51.r ));
					float3 worldPos = i.texcoord3.xyz;
					float3 worldViewDir = ( _WorldSpaceCameraPos.xyz - worldPos );
					worldViewDir = normalize(worldViewDir);
					float3 worldNormal = i.texcoord4.xyz;
					float fresnelNdotV3 = dot( worldNormal, worldViewDir );
					float fresnelNode3 = ( 0.0 + _FresnelSacle * pow( 1.0 - fresnelNdotV3, _FresnelPower ) );
					float4 lerpResult4 = lerp( lerpResult49 , _FresnelColor , saturate( fresnelNode3 ));
					
					//自定义算法板块
					half4 col;
					col.xyz = lerpResult4.rgb * i.color.xyz;
					col.w = 1 * i.color.w;
					return col;
				}
				ENDHLSL
			}
		}
	}
	
	CustomEditor "ASEMaterialInspector"
	Fallback Off
}/*ASEBEGIN
Version=19108
Node;AmplifyShaderEditor.SimpleAddOpNode;22;-1870.089,-2128.812;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;17;-1250.045,-1759.897;Inherit;True;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;32;-513.1736,-1760.531;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.PannerNode;19;-2844.376,-1682.815;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;23;-2199.313,-1710.457;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;20;-3193.286,-1687.319;Inherit;False;0;18;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;11;-2283.896,-2144.631;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;10;-2724.981,-2169.065;Inherit;False;0;9;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;42;-2191.243,-967.6711;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;40;-1727.199,-645.1014;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;35;-817.6052,-659.7034;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;27;-2162.117,-1378.798;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;28;-1763.102,-1374.967;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;30;-1388.104,-1306.967;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;49;-351.7041,-446.6768;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;33;-882.5215,-1445.257;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;50;-745.7745,-426.1239;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;37;-2089.948,-624.2086;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;38;-2531.033,-648.6425;Inherit;False;0;34;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;4;247.0358,-20.51856;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;5;-845.532,437.6556;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;3;-1323.532,355.6558;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;53;-1240.204,673.6595;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;54;-843.1672,699.1003;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;56;-579.8181,727.8229;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;-318.8182,794.8228;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;694.9588,858.6707;Float;False;True;-1;2;ASEMaterialInspector;0;20;Shiyue/URP/VFX/Water_VO;c07541c6fd4918145a1c26bb0cd884cf;True;SubShader 0 Pass 0;0;0;SubShader 0 Pass 0;3;False;True;2;5;False;;10;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;True;_Cull;False;False;False;False;False;False;False;False;False;False;True;True;1;False;;True;3;False;;False;True;5;RenderPipeline=UniversalPipeline;Queue=Transparent=Queue=0;IgnoreProjector=True;RenderType=Transparent=RenderType;PreviewType=Plane;False;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;0;;0;0;Standard;0;0;1;True;False;;False;0
Node;AmplifyShaderEditor.PannerNode;59;-299.3126,1347.194;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;58;-762.6365,1317.245;Inherit;False;0;60;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;62;545.053,1433.378;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;64;207.941,1648.847;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;1;-1083.532,-2291.121;Inherit;True;Property;_BaseRamp;渐变纹理;0;0;Create;False;0;0;0;False;0;False;-1;487540f8c4bd51742b9c40d3e42e96c1;487540f8c4bd51742b9c40d3e42e96c1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;8;-1534.533,383.6556;Inherit;False;Property;_FresnelSacle;边缘光亮度;4;0;Create;False;0;0;0;False;0;False;1;2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;7;-1536.533,494.6555;Inherit;False;Property;_FresnelPower;边缘光宽度;3;0;Create;False;0;0;0;False;0;False;5;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;6;-865.6419,242.4357;Inherit;False;Property;_FresnelColor;边缘光颜色;2;1;[HDR];Create;False;0;0;0;False;0;False;1,1,1,0;0,1.995044,3.381074,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;12;-2657.223,-1986.277;Inherit;False;Property;_AddSpeed;叠加纹理速度XY;11;0;Create;False;0;0;0;False;0;False;0,0;0,-0.4;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;18;-2592.524,-1709.011;Inherit;True;Property;_NoiseTex;扰动纹理;5;0;Create;False;0;0;0;False;0;False;-1;2a4f9385e34f1a54ebbfb131802c5d7f;2a4f9385e34f1a54ebbfb131802c5d7f;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;21;-3217.703,-1524.461;Inherit;False;Property;_NoiseSpeed;扰动纹理速度XY;6;0;Create;False;0;0;0;False;0;False;0,0;0.2,-0.2;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;24;-2599.754,-1474.818;Inherit;False;Property;_AddNoiseIntensity;叠加纹理扰动强度;12;0;Create;False;0;0;0;False;0;False;0;0.1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;25;-1599.381,-1670.06;Inherit;False;Property;_AddColor;叠加纹理颜色（A渐变与叠加权重）;8;0;Create;False;0;0;0;False;0;False;0,0,0,0;1,1,1,0.5372549;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;29;-1983.102,-1232.967;Inherit;False;Property;_AddMaskOffset;叠加纹理遮罩偏移;9;0;Create;False;0;0;0;False;0;False;0;0.33;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;9;-1662.298,-2164.569;Inherit;True;Property;_AddTex;叠加纹理;7;0;Create;False;0;0;0;False;0;False;-1;db7c96e94c22a05408141a74c1bdb33a;db7c96e94c22a05408141a74c1bdb33a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;31;-1679.103,-1089.106;Inherit;False;Property;_AddMaskMax;叠加纹理遮罩最大距离;10;0;Create;False;0;0;0;False;0;False;0.55;0.5611765;0.1;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;34;-1537.96,-666.8371;Inherit;True;Property;_LerpTex;混合纹理;13;0;Create;False;0;0;0;False;0;False;-1;None;393ce67b613c56d46878fd84eac676e0;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;39;-2464.275,-465.8545;Inherit;False;Property;_LerpSpeed;混合纹理速度;15;0;Create;False;0;0;0;False;0;False;0,0;0,-1;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ColorNode;36;-1597.888,-396.4887;Inherit;False;Property;_LerpColor;混合纹理颜色;14;1;[HDR];Create;False;0;0;0;False;0;False;0,0,0,0;0,4.90737,5.992157,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;41;-2469.643,-894.0711;Inherit;False;Property;_LerpNoiseIntensity;混合纹理扰动强度;16;0;Create;False;0;0;0;False;0;False;0;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;51;-1301.33,-179.1871;Inherit;True;Property;_LerpMask;混合纹理遮罩;17;0;Create;False;0;0;0;False;0;False;-1;None;71015788361adc64e9ffa93635480a8a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;60;-9.739038,1340.411;Inherit;True;Property;_VOTex;顶点偏移纹理;18;0;Create;False;0;0;0;False;0;False;-1;None;83418fba172b8e54686b2603afb7a049;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;63;88.2254,1561.098;Inherit;False;Property;_VOIntensity;顶点偏移强度;20;0;Create;False;0;0;0;False;0;False;0;0.03;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;61;-526.4044,1645.667;Inherit;False;Property;_VOSpeed;顶点偏移速度;19;0;Create;False;0;0;0;False;0;False;0,0;0,-0.7;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;65;171.7473,1891.646;Inherit;True;Property;_VOMask;顶点偏移遮罩;21;0;Create;False;0;0;0;False;0;False;-1;None;0e762b4d944d483499aabc477eedfa1d;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;52;-986.218,1014.353;Inherit;False;Property;_Alpha;整体透明度;22;0;Create;False;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;55;-1169.167,874.1002;Inherit;False;Property;_OffsetAlpha;透明度偏移;23;0;Create;False;0;0;0;False;0;False;-0.28;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;-585.3788,-2287.661;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;67;-896.864,-2614.511;Inherit;False;Property;_RampColor;渐变色;1;1;[HDR];Create;False;0;0;0;False;0;False;0,0,0,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
WireConnection;22;0;11;0
WireConnection;22;1;23;0
WireConnection;17;0;9;0
WireConnection;17;1;30;0
WireConnection;17;2;25;0
WireConnection;17;3;25;4
WireConnection;32;0;66;0
WireConnection;32;1;17;0
WireConnection;32;2;33;0
WireConnection;19;0;20;0
WireConnection;19;2;21;0
WireConnection;23;0;18;1
WireConnection;23;1;24;0
WireConnection;11;0;10;0
WireConnection;11;2;12;0
WireConnection;42;0;18;1
WireConnection;42;1;41;0
WireConnection;40;0;42;0
WireConnection;40;1;37;0
WireConnection;35;0;34;0
WireConnection;35;1;36;0
WireConnection;35;2;36;4
WireConnection;35;3;51;1
WireConnection;28;0;27;2
WireConnection;28;1;29;0
WireConnection;30;0;28;0
WireConnection;30;2;31;0
WireConnection;49;0;32;0
WireConnection;49;1;35;0
WireConnection;49;2;50;0
WireConnection;33;0;25;4
WireConnection;33;1;30;0
WireConnection;33;2;9;4
WireConnection;50;0;34;4
WireConnection;50;1;36;4
WireConnection;50;2;51;1
WireConnection;37;0;38;0
WireConnection;37;2;39;0
WireConnection;4;0;49;0
WireConnection;4;1;6;0
WireConnection;4;2;5;0
WireConnection;5;0;3;0
WireConnection;3;2;8;0
WireConnection;3;3;7;0
WireConnection;54;0;53;2
WireConnection;54;1;55;0
WireConnection;56;0;54;0
WireConnection;57;0;56;0
WireConnection;57;1;52;0
WireConnection;0;0;4;0
WireConnection;0;2;62;0
WireConnection;59;0;58;0
WireConnection;59;2;61;0
WireConnection;62;0;60;1
WireConnection;62;1;63;0
WireConnection;62;2;65;1
WireConnection;18;1;19;0
WireConnection;9;1;22;0
WireConnection;34;1;40;0
WireConnection;60;1;59;0
WireConnection;66;0;67;0
WireConnection;66;1;1;0
ASEEND*/
//CHKSM=18D64B7526798E12EFBD6821CA6F9409619F44C0