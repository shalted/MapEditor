Shader "ShouWang_Hair"
{
    Properties
    {
        [CustomKeywordEnum(IntroSetting, _BLINNPHONG, _PBR)] _WorkType ("工作流", float) = 0
        [CustomHeader(IntroSetting._BLINNPHONG)] _BLINNPHONG("Blinn Phong", float) = 1
        [CustomHeader(IntroSetting._PBR)] _PBR("PBR", float) = 1
        
        [CustomGroup] _MapSetting("基本设置", float) = 1
        [CustomTexture(_MapSetting)] _BaseMap ("固有色贴图", 2D) = "white" {}
        [CustomObject(_MapSetting)][Gamma]_Color(" ", Color) = (1, 1, 1, 1)
        [HideInInspector][HDR]_ProceduralColor ("Procedural Color", Color) = (1, 1, 1, 1)
        
        [CustomGroup] _LightMapSetting("Mask(LightMap)贴图",float) = 1.0
        [CustomTexture(_LightMapSetting)] _LightMap ("_LightMap", 2D) = "white" {}
        [CustomHeader(_LightMapSetting._PBR)] _PBRDesc("PBR相关设置：MetallicRoughness",float) = 1.0
        [CustomEnum(_LightMapSetting._PBR,NONE,0,MAIN_A,1,NORMAL_B,2,MASK_R,3,MASK_G,4,MASK_B,5,MASK_A,6)]_METAL("金属度", float) = 0
        [CustomObject(_LightMapSetting._PBR)]_MetallicScale("金属度强度", Range(-1.0, 1.0)) = 1.0
        [CustomObject(_LightMapSetting._PBR)]_MetallicBias("金属度对比度", Range(-1.0, 1.0)) = 0.0
        [CustomEnum(_LightMapSetting._PBR,NONE,0,MAIN_A,1,NORMAL_B,2,MASK_R,3,MASK_G,4,MASK_B,5,MASK_A,6)]_GLOSS("粗糙度", float) = 0
        [CustomObject(_LightMapSetting._PBR)]_SmoothnessScale("光滑度强度", Range(-1.0, 1.0)) = 1.0
        [CustomObject(_LightMapSetting._PBR)]_SmoothnessBias("光滑度对比度", Range(-1.0, 1.0)) = 0.5
        [CustomEnum(_LightMapSetting,NONE,0,MAIN_A,1,NORMAL_B,2,MASK_R,3,MASK_G,4,MASK_B,5,MASK_A,6)]_AO("AO(设置NONE的时候，请把AO强度设置为0)", float) = 0
        [CustomObject(_LightMapSetting)] _OcclusionStrength("AO强度",Range(0,1)) = 0
        
        [CustomGroup] _NormalSetting("法线设置",float) = 1.0
        [CustomTexture(_NormalSetting,_NORMALMAP)] _BumpMap ("法线贴图", 2D) = "white" {}
        [CustomObject(_NormalSetting)] _BumpStrength ("法线强度", Range(0,5)) = 1

        [CustomGroup] _DiffuseSetting("直接光漫反射设置",float) = 1.0
        [CustomKeywordEnum(_DiffuseSetting, _DIFFUSERAMP, _DIFFUSECEL, _DIFFUSEDEFAULT)]_Shadow_Setting("漫反射方式", float) = 0
        [CustomTexture(_DiffuseSetting._DIFFUSERAMP)] _ShadowMap ("阴影贴图", 2D) = "white" {}
        [CustomObject(_DiffuseSetting._DIFFUSERAMP)] _RampYOffset("Ramp贴图Y轴",Range(0,1)) = 0
        [CustomToggle(_DiffuseSetting._DIFFUSERAMP,_USE_RAMPID)] _UseRampID("Y轴使用RampID图", Float) = 1
        [CustomTexture(_DiffuseSetting._DIFFUSERAMP)] _RampUV_Y_ID_Map ("Ramp 分区贴图", 2D) = "black" {}
        [CustomObject(_DiffuseSetting._DIFFUSECEL)] _HColor ("亮部颜色", Color) = (1,1,1,1)
        [CustomObject(_DiffuseSetting._DIFFUSECEL)] _SColor ("暗部颜色", Color) = (0.2,0.2,0.2,1)
        [CustomObject(_DiffuseSetting._DIFFUSECEL)] _RampThreshold ("阈值", Range(0.01,1)) = 0.75
        [CustomObject(_DiffuseSetting._DIFFUSECEL)] _RampSmoothing ("过渡光滑值", Range(0.001,1)) = 0.1
        
        [CustomGroup] _SpecSetting("高光设置",float) = 1.0
        [CustomKeywordEnum(_SpecSetting, _NoneSpec, _SPECULARHAIR_ON, _TOONKKHAIR_ON, _TOONGENHAIR_ON)] _SpecularType ("高光类型", float) = 0
        [CustomEnum(_SpecSetting,NONE,0,MAIN_A,1,NORMAL_B,2,MASK_R,3,MASK_G,4,MASK_B,5,MASK_A,6)]_SPECMASK("高光遮罩", float) = 0
        [CustomTexture(_SpecSetting)] _DetailNormalMap ("Shift Map", 2D) = "white" {}

        [CustomHeader(_SpecSetting._SPECULARHAIR_ON)] _SPECULARHAIR_ON("写实各项异性高光", float) = 1
        [CustomHeader(_SpecSetting._TOONKKHAIR_ON)] _TOONKKHAIR_ON("卡通各项异性高光", float) = 1
        [CustomHeader(_SpecSetting._TOONGENHAIR_ON)] _TOONGENHAIR_ON("固定天使轮高光", float) = 1 
        [CustomObject(_SpecSetting._SPECULARHAIR_ON)] _HairSpecularCol("高光1颜色", Color) = (0,0,0,1)
        [CustomObject(_SpecSetting._SPECULARHAIR_ON)] _HairSpread1("高光1扩散", Range(-1,1)) = 0.0
        [CustomObject(_SpecSetting._SPECULARHAIR_ON)] _HairSpecularShift("高光1位置", Range(-3,3)) = 1.0
        [CustomObject(_SpecSetting._SPECULARHAIR_ON)] _HairSpecularStrength("高光1强度", Range(0, 10)) = 1.0
        [CustomObject(_SpecSetting._SPECULARHAIR_ON)] _HairSpecularExponent("高光1面积", Range(1,1024)) = 1.0
        [CustomObject(_SpecSetting._SPECULARHAIR_ON)] _HairSecondarySpecularCol("高光2颜色", Color) = (0,0,0,1)
        [CustomObject(_SpecSetting._SPECULARHAIR_ON)] _HairSpread2("高光2扩散", Range(-1,1)) = 0.0
        [CustomObject(_SpecSetting._SPECULARHAIR_ON)] _HairSecondarySpecularShift("高光2位置", Range(-3,3)) = 1.0
        [CustomObject(_SpecSetting._SPECULARHAIR_ON)] _HairSecondarySpecularStrength("高光2强度", Range(0, 10)) = 1.0
        [CustomObject(_SpecSetting._SPECULARHAIR_ON)] _HairSecondarySpecularExponent("高光2面积",Range(1,1024)) = 1.0

        [CustomObject(_SpecSetting._TOONKKHAIR_ON)] _SpecularSmooth("高光范围",Range(0,2)) = 1
        [CustomObject(_SpecSetting._TOONKKHAIR_ON)] _SpecularInstensity("高光强度",Range(0,10)) = 1
        [CustomObject(_SpecSetting._TOONKKHAIR_ON)] _SpecToonKKColor("高光颜色",Color) = (1,1,1,1)
        [CustomToggle(_SpecSetting._TOONKKHAIR_ON)] _UseViewDir("偏移根据观察方向移动", float) = 0
        [CustomObject(_SpecSetting._TOONKKHAIR_ON)] _SpecYOffset("高光偏移",Range(-5,5)) = 0

        //[CustomTexture(_SpecSetting._TOONGENHAIR_ON)] _SpecGenMask ("R 遮罩", 2D) = "gray" {}
        [CustomEnum(_SpecSetting._TOONGENHAIR_ON,NONE,0,MAIN_A,1,NORMAL_B,2,MASK_R,3,MASK_G,4,MASK_B,5,MASK_A,6)]_SPECFIXMASK("高光通道", float) = 0
        [CustomObject(_SpecSetting._TOONGENHAIR_ON)] _SpecLength ("高光长度", Range(0,1)) = 0.1
        [CustomObject(_SpecSetting._TOONGENHAIR_ON)] _SpecWidth ("高光宽度", Range(0,1)) = 0
        [CustomObject(_SpecSetting._TOONGENHAIR_ON)] _specInShadow ("阴影处强度", Range(0,1)) = 0
        [CustomObject(_SpecSetting._TOONGENHAIR_ON)] [HDR]_SpecBright ("天使轮高光颜色", Color) = (1,1,1,1)
        [CustomObject(_SpecSetting._TOONGENHAIR_ON)] _SpecLight ("天使轮暗部颜色", Color) = (1,1,1,1)
        [CustomObject(_SpecSetting._TOONGENHAIR_ON)] _SpecThreshold ("天使轮暗部阈值", Range(0,1)) = 0
        [CustomObject(_SpecSetting._TOONGENHAIR_ON)] _LightFeather ("天使轮柔和程度", Range(0,1)) = 0
        
        [CustomGroup] _PBRSpecSetting("PBR高光设置",float) = 1.0
        [CustomObject(_PBRSpecSetting._PBR)] _PBRSpecIntensity("高光强度",Range(0,8)) = 1
        [CustomObject(_PBRSpecSetting._PBR)] _PBRSpecColor("边缘光颜色",Color) =(0,0,0,1)
        
        [CustomGroup] _EmissionSetting("自发光设置",float) = 1.0
        [CustomToggle(_EmissionSetting, _EMISSION)] _emission ("开启自发光", Float) = 0
        [CustomEnum(_EmissionSetting._EMISSION,NONE,0,MAIN_A,1,NORMAL_B,2,MASK_R,3,MASK_G,4,MASK_B,5,MASK_A,6)]_EmissionID("自发光", float) = 0
        [CustomTexture(_EmissionSetting._EMISSION, _EMISSIONMAP)] _EmissionMap ("自发光贴图", 2D) = "black" {}
        [CustomObject(_EmissionSetting._EMISSION)]_EmissionColor ("自发光颜色", Color) = (1,1,1,1)
        [CustomObject(_EmissionSetting._EMISSION)]_Emission_Instensity ("自发光强度", Range(0,2)) = 1
        [CustomObject(_EmissionSetting)] _Emission_Lerp("贴图颜色OR自定义颜色",Range(0,1)) = 0

        // [CustomObject(_GlobalHighLightSetting)] _HairSpecularShiftSide("侧视偏移", Range(-1,1)) = 0.0 
        [CustomGroup] _RimSetting("边缘光设置",float) = 1.0
        [CustomToggle(_RimSetting,_RIM_ON)] _RimLights("使用边缘光", Float) = 1.0
        [CustomLightDir(_RimSetting)] _RimDir("边缘光方向",vector) =(0.5,0.5,0.5,1)
        [CustomObject(_RimSetting)] _RimDirContribution("边缘光影响程度",Range(0,1)) =0
        [CustomObject(_RimSetting)][HDR] _RimColor("边缘光颜色",Color) =(0,0,0,1)
        [CustomObject(_RimSetting)] _RimThreshold("边缘光阈值",Range(0,1)) =0.2
        [CustomObject(_RimSetting)] _RimSmooth("边缘光过渡",Range(0,1)) =0

        [CustomGroup] _GISetting("环境光设置",float) = 1.0
        [CustomObject(_GISetting)] _SHExposure("环境光强度", Range(0,2)) = 1
        
    	[CustomKeywordEnum(_GISetting, _BAKE_ENV, _CUSTOM_ENV_CUBE)] _EnvType ("环境光来源", float) = 0
        [CustomHeader(_GISetting._BAKE_ENV)] _BAKE_ENV("环境光来源：烘焙环境", float) = 1
        [CustomHeader(_GISetting._CUSTOM_ENV_CUBE)] _CUSTOM_ENV_CUBE("环境光来源：材质自定义", float) = 1
        [CustomTexture(_GISetting._CUSTOM_ENV_CUBE)]_EvnCubemap("天空盒", CUBE)="white" {}
        
        [CustomToggle(_GISetting, _GLOSSYREFLECTIONS_ON)] _UseGI ("开启环境高光", Float) = 0
        [CustomToggle(_GISetting._GLOSSYREFLECTIONS_ON)] _Use_Custom_SpecCube_HDR("使用自定义HDR系数", Float) = 1.0
        [CustomObject(_GISetting._GLOSSYREFLECTIONS_ON)] _Custom_SpecCube_HDR("自定义HDR系数",Vector) = (34.49324,2.2,0,1)
        [CustomObject(_GISetting._GLOSSYREFLECTIONS_ON)] _CubemapColor ("环境球颜色", color) = (1,1,1,1)
        [CustomObject(_GISetting._GLOSSYREFLECTIONS_ON)] _EnvRotate ("环境球旋转", Range(0, 360)) = 0
        [CustomObject(_GISetting._GLOSSYREFLECTIONS_ON)] _IndirectIntensity("环境高光强度,遮罩是光滑度", Range(0,8)) = 1
        
        [CustomGroup] _OtherSetting("其他设置",float) = 1.0
        [CustomToggleOff(_OtherSetting,_RECEIVE_SHADOWS_OFF)] _ReceiveShadowOff("开启自阴影", Float) = 1

        [CustomGroup] _OutLineSetting("描边设置",float) = 1.0
        [CustomKeywordEnum(_OutLineSetting, _Normal, COLORS_AS_NORMALS, UV2_AS_NORMALS)] _OutlineType ("法线来源 ", float) = 0
        [CustomToggle(_OutLineSetting,USEOUTLINE)] _UseOutline("开启描边", Float) = 0
        [CustomObject(_OutLineSetting)] _OutlineColor("描边颜色",Color) = (0,0,0,1)
        [CustomObject(_OutLineSetting)] _Outline_Width("描边宽度",Range(0,10)) = 1
        //[CustomObject(_OutLineSetting)] _Offset_Z("Offset Outline with Camera Z-axis",float) =0.38

        [CustomGroup] _StencilSetting("模板设置",float) = 1.0
        [CustomObject(_StencilSetting)] _StencilComp ("Stencil Comparison", Float) = 8
        [CustomObject(_StencilSetting)] _Stencil ("Stencil ID", Float) = 6      //模板值为6,作为角色默认值
        [CustomObject(_StencilSetting)] _StencilOp ("Stencil Operation", Float) = 2
        [CustomObject(_StencilSetting)] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [CustomObject(_StencilSetting)] _StencilReadMask ("Stencil Read Mask", Float) = 255

    	[HideInInspector] _StoryLightDir ("_StoryLightDir", Vector) = (0, 0, 1, 0)


        //渲染设置
		[HideInInspector] _Cutoff("透明裁剪", Range(0.0, 1.0)) = 0.5
		[HideInInspector] _Surface("_surface", Float) = 0.0
		[HideInInspector] _TransparentShadow("__TransparentShadow", Float) = 0.0//在CustomShaderGUINew 238行附近
		[HideInInspector] _AlphaClip("_alphaclip", Float) = 0.0
        [HideInInspector] _Mode ("__mode", Float) = 0.0
		[HideInInspector] _Cull ("__cull", Float) = 2   //[Enum(Cull Off,0, Cull Front,1, Cull Back,2)]
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
		[HideInInspector] _ZTest ("__zt", Float) = 4.0
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"
        }

        Pass
        {
            Name "ForwardLitLOD0"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Blend [_SrcBlend] [_DstBlend]
            ColorMask RGBA
            HLSLPROGRAM
            #define CHARACTER_LOD_0 1

            // Debug
            #pragma shader_feature_local _ _DEBUG
            
            // Material Keywords
            #pragma shader_feature _ _ALPHATEST_ON
            #pragma shader_feature _ _NORMALMAP
            #pragma shader_feature _ _BLINNPHONG _PBR
            #pragma shader_feature _ _DIFFUSERAMP _DIFFUSECEL
            #pragma shader_feature _ _USE_RAMPID
            #pragma shader_feature _ _SPECULARHIGHLIGHTS_ON
            #pragma shader_feature _ _SPECULARHAIR_ON _TOONKKHAIR_ON _TOONGENHAIR_ON
            #pragma shader_feature _ _GLOSSYREFLECTIONS_ON
            #pragma shader_feature _ _CUSTOM_ENV_CUBE
            #pragma multi_compile _ _EMISSION
            #pragma multi_compile _ _EMISSIONMAP
            //#pragma multi_compile _ _CUSTOM_BOXPROJECTION
            #pragma shader_feature _ _RIM_ON
            // Universal Pipeline keywords

            #pragma shader_feature _RECEIVE_SHADOWS_OFF

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            
            #pragma multi_compile_fog

            #pragma vertex Vertex
            #pragma fragment Fragment
            
            #include "../CGInclude/Hair_Standard_Lit_Input.hlsl"
            #include "../CGInclude/Hair_Standard_Lit_ForwardPass.hlsl"
            ENDHLSL
        }
//        Pass
//        {
//            Name "ForwardLitLOD1"
//            Tags
//            {
//                "LightMode" = "UniversalForwardLOD1"
//            }
//
//            Cull [_Cull]
//            ZWrite [_ZWrite]
//            ZTest [_ZTest]
//            Blend [_SrcBlend] [_DstBlend]
//            ColorMask RGB
//            HLSLPROGRAM
//            #define CHARACTER_LOD_1 1
//
//            // Material Keywords
//            #pragma shader_feature _ _ALPHATEST_ON
//            //#pragma shader_feature _ _NORMALMAP
//            #pragma shader_feature _ _BLINNPHONG _PBR
//            #pragma shader_feature _ _DIFFUSERAMP _USE_SHADOWMAP
//            #pragma shader_feature _ _USE_RAMPID
//            #pragma shader_feature _ _SPECULARHIGHLIGHTS_ON
//            #pragma shader_feature _ _SPECULARHAIR_ON _TOONKKHAIR_ON _TOONGENHAIR_ON
//            #pragma shader_feature _ _GLOSSYREFLECTIONS_ON
//            #pragma shader_feature _ _CUSTOM_ENV_CUBE
//            //#pragma multi_compile _ _CUSTOM_BOXPROJECTION
//            #pragma shader_feature _ _RIM_ON
//            // Universal Pipeline keywords
//
//            #pragma shader_feature _RECEIVE_SHADOWS_OFF
//
//            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
//            // #pragma shader_feature _ _MAIN_LIGHT_SHADOWS_CASCADE
//            // #pragma multi_compile _ _ADDITIONAL_LIGHTS
//            // #pragma shader_feature _ _SHADOWS_SOFT
//
//            #pragma vertex Vertex
//            #pragma fragment Fragment
//            #include "Hair_Standard_Lit_Input.hlsl"
//            #include "Hair_Standard_Lit_ForwardPass.hlsl"
//            ENDHLSL
//        }
//        Pass
//        {
//            Name "ForwardLitLOD2"
//            Tags
//            {
//                "LightMode" = "UniversalForwardLOD2"
//            }
//            Cull [_Cull]
//            ZWrite [_ZWrite]
//            ZTest [_ZTest]
//            Blend [_SrcBlend] [_DstBlend]
//            ColorMask RGB
//            HLSLPROGRAM
//            #define CHARACTER_LOD_2 1
//
//            // Material Keywords
//            #pragma shader_feature _ _ALPHATEST_ON
//            //#pragma shader_feature _ _NORMALMAP
//            #pragma shader_feature _ _BLINNPHONG _PBR
//            #pragma shader_feature _ _DIFFUSERAMP _USE_SHADOWMAP
//            #pragma shader_feature _ _USE_RAMPID
//            //#pragma shader_feature _ _SPECULARHIGHLIGHTS_ON
//            //#pragma shader_feature _ _SPECULARHAIR_ON _TOONKKHAIR_ON _TOONGENHAIR_ON
//            #pragma shader_feature _ _GLOSSYREFLECTIONS_ON
//            #pragma shader_feature _ _CUSTOM_ENV_CUBE
//            //#pragma multi_compile _ _CUSTOM_BOXPROJECTION
//            //#pragma shader_feature _ _RIM_ON
//            // Universal Pipeline keywords
//
//            #pragma shader_feature _RECEIVE_SHADOWS_OFF
//
//            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
//            // #pragma shader_feature _ _MAIN_LIGHT_SHADOWS_CASCADE
//            // #pragma multi_compile _ _ADDITIONAL_LIGHTS
//            // #pragma shader_feature _ _SHADOWS_SOFT
//
//            #pragma vertex Vertex
//            #pragma fragment Fragment
//            #include "Hair_Standard_Lit_Input.hlsl"
//            #include "Hair_Standard_Lit_ForwardPass.hlsl"
//            ENDHLSL
//        }
        Pass
        {
            Name "HairShadow"
            Tags
            {
                "LightMode" = "HairShadow"
            }

            Cull Off
            ZTest LEqual
            ZWrite On

            HLSLPROGRAM
            #define CHARACTER_LOD_0 1

            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS: POSITION;
                float4 color: COLOR;
            };

            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float4 color: COLOR;
            };


            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.color = input.color;
                return output;
            }

            half4 frag(Varyings input): SV_Target
            {
                #if UNITY_REVERSED_Z
                    float depth = (input.positionCS.z / input.positionCS.w);
                #else
					float depth = (input.positionCS.z / input.positionCS.w) * 0.5 + 0.5;
                #endif

                return float4(depth, 0, 0, 1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            ZWrite On
            ZTest LEqual
            Cull [_Cull]
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON

            //--------------------------------------
            // GPU Instancing
            //#pragma multi_compile_instancing
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragmentBlend


            #include "../CGInclude/Hair_Standard_Lit_Input.hlsl"
            #include "../CGInclude/CustomShadowCasterPass.hlsl"

            void transparencyClip(float alpha, float2 screenPos)
            {
                float4x4 thresholdMatrix =
                {
                    1.0 / 17.0, 9.0 / 17.0, 3.0 / 17.0, 11.0 / 17.0,
                    13.0 / 17.0, 5.0 / 17.0, 15.0 / 17.0, 7.0 / 17.0,
                    4.0 / 17.0, 12.0 / 17.0, 2.0 / 17.0, 10.0 / 17.0,
                    16.0 / 17.0, 8.0 / 17.0, 14.0 / 17.0, 6.0 / 17.0
                };

                clip(alpha - thresholdMatrix[fmod(screenPos.x, 4)][fmod(screenPos.y, 4)]);
            }

            half4 ShadowPassFragmentBlend(Varyings input) : SV_TARGET
            {
                half alpha = SampleMainTex(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a * _Color.a;
                // TODO：半透的keyword有问题
                 #if defined(_ALPHATEST_ON)
					 clip(alpha - _Cutoff);
                // #elif _ALPHABLEND_ON
					// float2 screenPos = input.positionCS.xy / (input.positionCS.w + 0.0001);
					// transparencyClip(alpha, screenPos);
                #endif
                return 0;
            }
            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask 0
            Cull [_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            //#pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "../CGInclude/Hair_Standard_Lit_Input.hlsl"
            #include "../CGInclude/CustomDepthOnlyPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Name "OutLine"
            Tags
            {
                "LightMode" = "OutLine"
            }
            Cull Front
            ZWrite [_ZWrite]
            ZTest [_ZTest] 
            Blend [_SrcBlend] [_DstBlend]

            HLSLPROGRAM
            #pragma multi_compile _ USEOUTLINE
            #pragma multi_compile _ _Normal COLORS_AS_NORMALS  UV2_AS_NORMALS
            #pragma vertex OutLinePassVertex
            #pragma fragment OutlinePassFragmentNew

            #include "../CGInclude/Hair_Standard_Lit_Input.hlsl"
            #include "../CGInclude/CustomOutline.hlsl"
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "CustomShaderEditor.CustomShaderGUI_Character"
}