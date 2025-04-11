Shader "XianXia/Scene3D/Lit/Standard"
{
    Properties
    {
        [Group]_GroupOne("基础", float) = 1
		_MainTexValue("亮度", Range(0, 3.0)) = 1
		_MainTexSaturation("饱和度", Range(0, 2.0)) = 1
		_MainTexContrast("对比度", Range(0, 2.0)) = 1
        [Toggle(_AlphaTest)]
        _UseAlphaTest("开启全透明",Float) = 0
        _Cutoff("透明阈值",Range(0,1)) = 0
        [HDR]_Color("主贴图颜色", Color) = (1, 1, 1, 1)
        _MainTex("主贴图", 2D) = "white" {}
		[Toggle(_NORMALMAP)]
		_UseNormalMap("开启法线贴图", Float) = 0
        _NormalScale("法线缩放", Range(0, 2)) = 0.5
        [NoScaleOffset]_NormalMap("法线贴图", 2D) = "white" {}
        [NoScaleOffset]_MaskTex("通道图(R：光滑度 G：金属度 B：环境光遮蔽)", 2D) = "white" {}
		_SmoothnessScale("光滑度缩放", Range(0, 1.0)) = 0.7
		_MetallicScale("金属度缩放", Range(0, 2.0)) = 0
		_AmbientOcclusionStrength("环境光遮蔽强度", Range(0, 1)) = 0
		_AmbientSpecularScale("环境高光反射强度", Range(0, 2.0)) = 0.5
        [Space(10)]
//		_EmissionStrength("自发光强度", Range(0, 2.0)) = 1
        [Group]_BloomGroup("辉光", float) = 0
//        [KeywordEnum(OFF,COLOR,TEXTURE)] _BloomType("辉光类型",FLoat) = 0
        [KeywordEnum(OFF,COLOR,TEXTURE)] _BloomClass("辉光类型",FLoat) = 0
		[NoScaleOffset]_EmissionTex("辉光贴图（R：自发光 G：边缘光）", 2D) = "white" {}
        [HDR]_EmissionColor("自发光颜色",Color) = (0,0,0,1) 
        [HDR]_RIMColor("边缘光颜色",Color) = (0,0,0,1)
        _RimPow("边缘光过渡",Range(0.01,10)) = 0
        _RimDistance("边缘光范围",Range(0,1)) = 0
        
        [Group]_GroupSec("细节", float) = 0
		[Toggle(USE_DETAIL_LERP)]
		_UseDetailTex("开启细节", Float) = 0
        _DetailTex("细节贴图(RGB：固有色 A：光滑度)", 2D) = "white" {}
        _DetailNormalMapScale("细节法线缩放", Range(0, 2)) = 0.5
		[NoScaleOffset]_DetailNormalMap("细节法线贴图", 2D) = "bump" {}
        _DetailSmoothnessScale("细节光滑度缩放", Range(0, 1.0)) = 0
        _CloudMap ("云阴影", 2D) = "black"{}
        _CloudMove ("云流动速度", Vector) = (0,0,0,0)

    }

	CustomEditor "ShaderEditor.GameShaderGUI"

    CGINCLUDE
        #define UNITY_SETUP_BRDF_INPUT MetallicSetup
        #include "SceneLightingDefine.hlsl"
    ENDCG

    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType"="Opaque" "PerformanceChecks"="False" }
        Cull Back

        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            
            CGPROGRAM
            #pragma target 3.5
            // #pragma multi_compile __ USE_GLOBAL_SCENE_FADE
            #pragma multi_compile_local __ _NORMALMAP
            #pragma multi_compile_local __ _AlphaTest
            #pragma multi_compile_local __ USE_DETAIL_LERP
            #pragma multi_compile_fwdbase
            #pragma skip_variants VERTEXLIGHT_ON DYNAMICLIGHTMAP_ON DIRLIGHTMAP_COMBINED SHADOWS_SOFT FOG_EXP FOG_EXP2

            #pragma multi_compile_local_fragment _BLOOMCLASS_OFF _BLOOMCLASS_COLOR _BLOOMCLASS_TEXTURE
            #pragma shader_feature _ SHADING_BAKER
            //#pragma multi_compile_instancing

            #pragma vertex vertBase
            #pragma fragment fragBase
            #include "Builtin/UnityStandardCoreForward.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 3.5
            #pragma multi_compile_local __ _NORMALMAP
            #pragma multi_compile_local __ _AlphaTest
            #pragma multi_compile_local __ USE_DETAIL_LERP
            #pragma multi_compile_fwdadd
            #pragma skip_variants DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_SOFT FOG_EXP FOG_EXP2
            #pragma shader_feature _ SHADING_BAKER
            
            #pragma vertex vertAdd
            #pragma fragment fragAdd
            #include "Builtin/UnityStandardCoreForward.cginc"

            ENDCG
        }
		Pass {
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }

			ZWrite On ZTest LEqual

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile_local __ _AlphaTest
			#include "UnityCG.cginc"

			struct v2f {
				float2 uv : TEXCOORD2;
				V2F_SHADOW_CASTER;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				#if defined(_AlphaTest)
				fixed4 color = GetMainTex(i.uv);
				clip(color.a - _Cutoff);
				#endif
				
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
        // ------------------------------------------------------------------
        // Extracts information for lightmapping, GI (emission, albedo, ...)
        // This pass it not used during regular rendering.
        Pass
        {
            Name "META"
            Tags { "LightMode"="Meta" }

            Cull Off

            CGPROGRAM
            #pragma vertex vert_meta
            #pragma fragment frag_meta
            #pragma shader_feature_local __ USE_DETAIL_LERP
            #pragma shader_feature EDITOR_VISUALIZATION
            #include "Builtin/UnityStandardMeta.cginc"
            ENDCG
        }

        UsePass "Hidden/Procedural/SelectiveWaterReflection/BASE"
    }
}
