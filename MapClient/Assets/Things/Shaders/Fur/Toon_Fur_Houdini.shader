Shader "ShiYue/URP/Charactors/Toon_Fur_Houdini"
{
    Properties
    {
        [CustomHeader(_STYLIZED)] _STYLIZED("风格化", float) = 1
        [CustomGroup] _MapSetting("基本设置",float) = 1.0
    	[CustomHeader(_MapSetting)] _BaseMapTip("RGB-法线  A:透明度、对比度遮罩", Float) = 1
        [CustomTexture(_MapSetting)] [_MainTex]_BaseMap ("固有色贴图", 2D) = "white" {}
        [HideInInspector][CustomObject(_MapSetting)][Gamma]_Color(" ", Color) = (1, 1, 1, 1)
        [CustomHeader(_MapSetting)] _MaskMapTip1("RG-法线 B-AO A-高光类型遮罩", Float) = 1
        [CustomTexture(_MapSetting)] [NoScaleOffset]_MaskMap ("_OD图 ", 2D) = "gray" {} // MAPLINE = _MaskMap
    	[CustomHeader(_MapSetting)] _MaskMapTip2("只用到了OD图的  RG-法线", Float) = 1
        [CustomObject(_MapSetting)] _BumpScale("法线强度", Range(0, 1)) = 1
        
        
        [CustomGroup()] _FurBaseSetting("毛发基本设置",float) = 1.0
    	[CustomBlockBegin(_FurBaseSetting, 0.4, 0.4, 0.4, 1, 0.9, 0.9, 0.9, 1)] _FurDirBlockBegin("毛发朝向", Float) = 1
        [CustomHeader(_FurBaseSetting)] _FurFlowMapTip1("RG-毛发朝向 B-空 A-毛发长短", Float) = 1
        [CustomFurFlowmap(_FurBaseSetting)]_FurFlowMap("毛发遮罩图", 2D) = "gray"{}
        [CustomObject(_FurBaseSetting)]_FurFlowMapIntensity("毛发朝向强度",Range(0, 1)) = 0
    	[CustomObject(_FurBaseSetting)]_RootFurRange("毛发根部不受毛发朝向影响范围",Range(0, 1)) = 0
    	[CustomHeader(_FurBaseSetting)] _CurlyFurTip1("卷毛设置", Float) = 1
        [CustomObject(_FurBaseSetting)]_CurlyFurRange("卷毛范围",Range(0, 1)) = 0
        [CustomBlockEnd(_FurBaseSetting)] _FurDirBlockEnd("毛发朝向", Float) = 1
    	
    	[CustomBlockBegin(_FurBaseSetting, 0.4, 0.4, 0.4, 1, 0.9, 0.9, 0.9, 1)] _FurShapeBlockBegin("毛发形状", Float) = 1
        [CustomTexture(_FurBaseSetting)] _FurNoiseMap ("毛发Noise", 2D) = "gray"{}
        //[CustomTexture(_FurBaseSetting,_MASKMAP)] _FurMaskMap("Mask贴图",2D) = "white" {}
        //[CustomEnum(_FurBaseSetting,NONE,0,MAIN_A,1,NORMAL_B,2,MASK_R,3,MASK_G,4,MASK_B,5,MASK_A,6)]_FURMASK("毛发通道", float) = 0
        [CustomObject(_FurBaseSetting)] _FurColor ("毛发根部颜色", Color) = (1,1,1,1)
    	[CustomToggle(_FurBaseSetting)] _UseFurTipsColor ("使用毛发尖端颜色渐变", Float) = 0
    	[CustomObject(_FurBaseSetting)] _FurTipsColor ("毛发尖端颜色", Color) = (1,1,1,1)
    	[CustomObject(_FurBaseSetting)] _FurTipsColorRange("毛发尖端颜色渐变范围",Range(0, 1)) = 0.0
    	[CustomObject(_FurBaseSetting)] _FurTipsColorRangeSoftness("毛发尖端颜色渐变柔软度",Range(0, 1)) = 1.0
        [CustomObject(_FurBaseSetting)] _FurLength ("毛发长度", Range(0.0, 0.5)) = 0.05
        [CustomObject(_FurBaseSetting)]_FurDensity("毛发疏密",Range(0, 1)) = 0.5
        [CustomObject(_FurBaseSetting)]_FurContrast("毛发对比度",Range(-3, 3)) = 1
        [CustomObject(_FurBaseSetting)]_FurAlpha("毛发透明度",Range(0, 1)) = 0.2
    	[CustomBlockEnd(_FurBaseSetting)] _FurShapeBlockEnd("毛发形状", Float) = 1
		//[CustomObject(_FurBaseSetting)] _Tining ("毛发长度", Range(0,1)) = 1
		//[CustomObject(_FurBaseSetting)] _FurRadius ("毛发半径", Range(0, 5)) = 1
        
        
        [HideInInspector][CustomObject(_FurBaseSetting)] _FurShadowPow ("阴影强度", Range(0,1)) = 1
        [HideInInspector][CustomObject(_FurBaseSetting)] _FurShadowColor ("阴影颜色", Color) = (1, 1, 1, 1)
        [HideInInspector][CustomObject(_FurBaseSetting)] _FurAmbientIntensity ("皮毛环境光强度", Range(0, 2)) = 0.5
        [HideInInspector][CustomObject(_FurBaseSetting)] _Gravity("重力方向xyz 强度w", Vector) = (0, -1, 0, 0)
        
        
        [CustomGroup] _DiffSetting("体积感设置",float) = 1.0
        [CustomBlockBegin(_DiffSetting, 0.4, 0.4, 0.4, 1, 0.9, 0.9, 0.9, 1)] _DiffuseBlockBegin("阴影", Float) = 1
		//[CustomKeywordEnum(_DiffSetting, _DIFFUSECEL)] _DiffuseType ("漫反射类型", float) = 0
		//[CustomRampTexture(_DiffSetting._DIFFUSERAMP)] _RampMap ("过渡贴图", 2D) = "white" {}
		//[HideInInspector][CustomObject(_DiffSetting._DIFFUSERAMP)] _RampYOffset ("Ramp贴图Y轴偏移", Range(0,1)) = 0
		//[CustomToggle(_DiffSetting,_USE_DIFFUSERAMP_ID)] _USE_DIFFUSERAMP_ID("使用ID采样(关闭后可用Y轴偏移采样)", float) = 0
    	[CustomHeader(_DiffSetting)] _DiffuseTip("阴影范围", Float) = 1
    	[CustomObject(_DiffSetting)] _AnisotropyDiffuse("各向异性阴影强度", Range(0, 1)) = 0.0
        [CustomObject(_DiffSetting)] _RampThreshold ("阴影范围", Range(0.01,1)) = 0.75
        [CustomObject(_DiffSetting)] _RampSmoothing ("阴影过渡光滑值", Range(0.001,1)) = 0.1
    	[CustomHeader(_DiffSetting)] _DiffuseColorTip("阴影颜色", Float) = 1
        [CustomObject(_DiffSetting)] _HColor ("亮部颜色", Color) = (1,1,1,1)
        [CustomObject(_DiffSetting)] _SColor ("暗部颜色", Color) = (0.2,0.2,0.2,1)
        [CustomObject(_DiffSetting)] _DiffuseBlendAlbedo ("颜色混合固有色", Range(0, 1)) = 0.0
        [CustomObject(_DiffSetting)] _DiffuseBlendAO ("阴影混合AO强度", Range(0, 1)) = 0.0
        [CustomBlockEnd(_DiffSetting)] _DiffuseBlockEnd("阴影", Float) = 1
        
        [CustomBlockBegin(_DiffSetting, 0.4, 0.4, 0.4, 1, 0.9, 0.9, 0.9, 1)] _FurAOBlockBegin("AO", Float) = 1
    	[CustomToggle(_DiffSetting, _AODEEPEN)] _AoDeepen("AO加强", Float) = 0.0
        [CustomObject(_DiffSetting)] _FurAOColor ("毛发AO颜色", Color) = (0, 0, 0, 1)
        [CustomObject(_DiffSetting)] _FurAOIntensity ("毛发AO强度", Range(0, 2)) = 1.0
        [CustomObject(_DiffSetting)] _FurAORange ("毛发AO范围", Range(0.01, 5)) = 1.0
        [CustomObject(_DiffSetting)] _FurAOBlendAlbedo ("颜色混合固有色", Range(0, 1)) = 0.0
        [CustomBlockEnd(_DiffSetting)] _FurAOBlockEnd("AO", Float) = 1
        
        
        [CustomToggle(_DiffSetting,_PEROBJSHADOWMASK)] _PEROBJSHADOWMASK ("使用高清阴影(PerOjectShadow)", Float) = 0
        
        [CustomGroup] _FurSpecSetting("高光设置",float) = 1.0
    	[CustomObject(_FurSpecSetting)] _FurSpecularBlendLength ("高光亮度受毛发长短遮罩影响强度", Range(0.0, 1)) = 0.0
        [CustomObject(_FurSpecSetting)] _FurSpecularRootAOIntensity ("毛发根部高光遮蔽强度", Range(0.0, 1)) = 0.0
    	[CustomBlockBegin(_FurSpecSetting, 0.4, 0.4, 0.4, 1, 0.9, 0.9, 0.9, 1)] _PBRSpecularBlockBegin("PBR高光", Float) = 1
        [CustomObject(_FurSpecSetting)] _FurSpecularColor ("高光颜色", Color) = (1, 1, 1, 1)
        [CustomObject(_FurSpecSetting)] _FurSmoothness ("光滑度", Range(0.001, 1)) = 0.12
        [CustomObject(_FurSpecSetting)] _FurSpecularColorBlender ("颜色混合固有色", Range(0.0, 1)) = 0.8
        [CustomObject(_FurSpecSetting)] _FurSpecularBrightness ("高光亮度", Range(0.001, 10)) = 0.0

    	[CustomBlockEnd(_FurSpecSetting)] _PBRSpecularBlockEnd("PBR高光", Float) = 1
    	
    	[CustomBlockBegin(_FurSpecSetting, 0.4, 0.4, 0.4, 1, 0.9, 0.9, 0.9, 1)] _AnisotropySpecularBlockBegin("各向异性高光", Float) = 1
        [CustomObject(_FurSpecSetting)] _FurAnisotropySmoothness ("光滑度", Range(0.0, 1)) = 0.5
        [CustomObject(_FurSpecSetting)] _FurAnisotropyBrightness ("高光亮度", Range(0.001, 1)) = 0.0
        [CustomBlockEnd(_FurSpecSetting)] _AnisotropySpecularBlockEnd("各向异性高光", Float) = 1
    	
    	
		[CustomGroup] _EnvShadingSetting("环境光设置",float) = 1.0
        [CustomObject(_EnvShadingSetting)] _SHExposure("环境光强度", Range(0,5)) = 1
        
        
		//[CustomGroup] _FurSpecSetting("毛发高光设置",float) = 1.0
		//[CustomToggle(_FurSpecSetting, _FURBITANGENT)] _FurTangent ("是否副切线空间", Float) = 0
		//[CustomObject(_FurSpecSetting)] _FurSpecColor ("各向异性高光色", Color) = (0,0,0,1)
		//[CustomObject(_FurSpecSetting)] _FurSpecShininess ("光滑度", Range(0.001, 1)) = 0.5
		//[CustomObject(_FurSpecSetting)] _FurSpecOffset ("位置偏移", Range(-1,1)) = 0
		//[CustomObject(_FurSpecSetting)] _FurSepcIntensity("高光强度", Range(0,0.1)) = 1

        [CustomGroup] _FurRimLightSetting("毛发边缘光",float) = 1.0
        //[CustomToggle(_FurRimLightSetting,_FUR_RIM_ON)] _FurRimOn("开启毛发边缘光", Float) = 0
        [CustomObject(_FurRimLightSetting)] _SideLightColor("边缘光颜色", Color) = (0.1, 0.1, 0.1, 1)
        [CustomObject(_FurRimLightSetting)] _SideLightBlendAlbedo ("颜色混合固有色", Range(0, 1)) = 0.0
        [CustomObject(_FurRimLightSetting)] _SideLightScale("边缘光范围", Range(0, 8)) = 0.5
        [CustomObject(_FurRimLightSetting)] _SideLightPow("边缘光强度", Range(0, 8)) = 1
        
        
        [CustomGroup] _ShadowSetting("投影设置",float) = 1.0
        [CustomObject(_ShadowSetting)] _ShadowIntensity("投影强度", Range(0, 1)) = 1

        
        
        [CustomGroup] _EffectsSetting("特效设置",float) = 1.0
        [CustomTexture(_EffectsSetting)] _EffectsMaskTex("特效遮罩(R:弱点区域)",  2D)= "black" {}
        [CustomTexture(_EffectsSetting)] _DissloveTex("溶解贴图(_DissloveTex)",  2D)= "white" {}
        [CustomObject(_EffectsSetting)] _DissloveThreshold("溶解程度(_DissloveThreshold)", Range(0,1))= 0
        [CustomObject(_EffectsSetting)] _DissloveEdgeLength("溶解边缘宽度(_DissloveEdgeLength)", Range(0,0.2))= 0
        [CustomObject(_EffectsSetting)] [HDR]_DissloveEdgeColor("溶解边缘颜色(_DissloveEdgeColor)",Color)= (0,0,0,0)

        [CustomObject(_EffectsSetting)] [HDR]_FresnelColor("菲涅尔颜色(_FresnelColor)",Color)= (0,0,0,0)
        [CustomObject(_EffectsSetting)] _FresnelF0("菲涅尔系数(_FresnelF0)", Float)= 4
        [CustomEnum(_EffectsSetting,normal,0,smooth,1)] _FresneType("菲涅尔模式(_FresneType)", Float)= 0
        
		//[CustomToggle(_EffectsSetting,_RESIDENTEFFECT_ON)]_UseResidentEffect("使用常驻特效(消融)[UV3]",Float) = 0
		//[HideInInspector][CustomTexture(_EffectsSetting._RESIDENTEFFECT_ON)] _ResidentDisMaskTex("溶解遮罩(_ResidentDisMaskTex)",  2D)= "black" {}
		//[CustomObject(_EffectsSetting._RESIDENTEFFECT_ON)] _ResidentBlankingDis("消隐距离(_ResidentBlankingDis)",Range(0.01,1)) = 1
		//[CustomObject(_EffectsSetting._RESIDENTEFFECT_ON)] _ResidentBlankingRange("消隐宽度(_ResidentBlankingRange)",Range(0.01,1)) = 10
		//[CustomTexture(_EffectsSetting._RESIDENTEFFECT_ON)] _ResidentDisTex("溶解贴图(_ResidentDisTex)",  2D)= "white" {}
		//[CustomObject(_EffectsSetting._RESIDENTEFFECT_ON)] _ResidentDissloveThreshold("溶解程度(_ResidentDissloveThreshold)", Range(0,1))= 0
		//[CustomObject(_EffectsSetting._RESIDENTEFFECT_ON)] _ResidentDissloveEdgeLength("溶解边缘宽度(_ResidentDissloveEdgeLength)", Range(0,1))= 0
		//[CustomObject(_EffectsSetting._RESIDENTEFFECT_ON)] [HDR]_ResidentDissloveEdgeColor("溶解边缘颜色(_ResidentDissloveEdgeColor)",Color)= (0,0,0,0)
		//[CustomObject(_EffectsSetting._RESIDENTEFFECT_ON)] _ResidentDissloveSpeed ("溶解移动速度(_ResidentDissloveSpeed)" ,Vector) = (0,0,0,0)

        //[HideInInspector]_DitherTimer("DitherTimer",Range(0,1))=0
    	
    	[HideInInspector] [CustomObject(_ShadowSetting)] _CustomShadowDepthBias("投影朝深度偏移", Range(0.01,20)) = 1
	    [HideInInspector] [CustomObject(_ShadowSetting)] _CustomShadowNormalBias("投影朝法线偏移", Range(0.01,20)) = 1
        
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

        [HideInInspector] _RimDirContribution("_RimDirContribution",float) =0.0
        [HideInInspector] _LightDirOffset("_LightDirOffset",float) =0.0
        [HideInInspector] _RimCustom("_RimCustom",float) =0.0
        [HideInInspector] _Shininess("_Shininess",float) =0.0
        [HideInInspector] _AOIntensity("_AOIntensity",Range(0,1)) =0.0
        [HideInInspector] _RimDir("_RimDir",vector) =(0,0,0,0)
        [HideInInspector] _Is_Filter_LightColor("_Is_Filter_LightColor",float) = 0
        
        [HideInInspector][CustomGroup] _DEBUG("检查模式",float) = 1.0
        [HideInInspector][CustomToggle(_DEBUG, _DEBUG_ON)] _DEBUG_ON ("开启Debug模式", Float) = 0.0
        
        [HideInInspector]dark("dark",float) =0.0
        
        //[CustomGroup] _OtherSetting("Tonemapping设置",float) = 1.0
        //[CustomToggle(_OtherSetting,_USECUSTOMTONEMAP)] _UseCustomTonemap("自定义Tonemapping", Float) = 0
        //[CustomObject(_OtherSetting)] _CustomtonemapThreashold("阈值",Range(0.0,3)) = 0.75
        //[CustomHeader(_OtherSetting)] _C1("ConnectType:Metal 关联金属度贴图(只有金属部分自定义)",Int) = 1
        //[CustomHeader(_OtherSetting)] _C2("ConnectType:Skin 关联非皮肤部分(非皮肤部分自定义,皮肤ID需为0)",Int) = 1
        //[CustomEnum(_OtherSetting,Null,0,Metal,1,Skin,2)] _CustomConnect("ConnectType",Int) = 0
        [CustomGroup] _StencilSetting("模板设置",float) = 1.0
        [CustomObject(_StencilSetting)] _StencilComp ("Stencil Comparison", Float) = 8
        [CustomObject(_StencilSetting)] _Stencil ("Stencil ID", Float) = 6      //模板值为6,作为角色默认值
        [CustomObject(_StencilSetting)] _StencilOp ("Stencil Operation", Float) = 2
        [CustomObject(_StencilSetting)] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [CustomObject(_StencilSetting)] _StencilReadMask ("Stencil Read Mask", Float) = 255
    	
    	[HideInInspector] _StoryLightDir ("_StoryLightDir", Vector) = (0, 0, 1, 0)
    	
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"
        }
        //0 UniversalForward
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Stencil
            {
                Ref [_Stencil]
                Comp Always
                Pass Replace
            }
//                Cull [_Cull]
//                ZWrite [_ZWrite]
//                ZTest [_ZTest]
            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
        	Blend [_SrcBlend] [_DstBlend]
//            Blend SrcAlpha OneMinusSrcAlpha
        	

            HLSLPROGRAM
            
            // #pragma multi_compile _ _FUR_ON
            // #pragma multi_compile _ _FURBITANGENT

            #define _FUR_ON 1//用于区分外扩毛发层，和原本的模型层
            
            #pragma multi_compile_fragment _ _DISSLOVE_ON//[特效]溶解
            #pragma multi_compile_fragment _ _ALPHATEST_ON//[特效]传送门
            
            #pragma shader_feature_local _ _AODEEPEN//AO类型

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            //#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING // mix灯烘焙阴影需要
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS

            #pragma multi_compile_fog
            
            #pragma vertex vert_fur_Houdini
            #pragma fragment frag_fur
            
            #include "ToonFur_Input.hlsl"
            #include "ToonFur_ForwardPass.hlsl"
            ENDHLSL
        }
        //1 ShadowCaster
        Pass
    	{
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }
            Stencil
            {
                Ref [_Stencil]
                Comp Always
                Pass Replace
                //ReadMask [_StencilReadMask]
                //WriteMask [_StencilWriteMask]
            }
            ZWrite On
            ZTest LEqual
            Cull [_Cull]
        	
            HLSLPROGRAM
            // #pragma prefer_hlslcc gles
            // #pragma target 3.0

            #pragma vertex ShadowCasterVertex 
            #pragma fragment ShadowCasterFragmentBlend

            #pragma shader_feature _ _SHADOWTRANSPARENCY
            
            #pragma multi_compile_fragment _ _DISSLOVE_ON//[特效]溶解
            #pragma multi_compile_fragment _ _ALPHATEST_ON//[特效]传送门


            #include "ToonFur_Input.hlsl"
            #include "ToonFur_ForwardPass.hlsl"
            //#include "ShaderLibrary/CharacterShadowCasterPass.hlsl"//剔除ShaderLibrary引用文件，解耦出来独立毛发

            struct ShadowCasterAttributes
			{
			    float4 positionOS   : POSITION;
			    float3 normalOS     : NORMAL;
			    float2 texcoord     : TEXCOORD0;
			    float2 texcoord1    : TEXCOORD1;
			    float3 color        : COLOR;
			};
            
            struct ShadowCasterVaryings
            {
                float4 positionCS : SV_POSITION;
            	float3 positionWS : TEXCOORD0;
            	float4 uv12           : TEXCOORD1;
            	float4 screenPos : TEXCOORD3;
            };
            
            float4 GetShadowPositionHClip1(ShadowCasterAttributes input)
            {
            	float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
            	float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
            	float4 positionCS = TransformWorldToHClip(positionWS);
            	//float4 positionCS = TransformWorldToHClip(CustomApplyShadowBias(positionWS,normalWS,_LightDirection));
				//剔除ShaderLibrary引用文件，解耦出来独立毛发
            	
            #if UNITY_REVERSED_Z
            	positionCS.z = min(positionCS.z,positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #else
            	positionCS.z = max(positionCS.Z,positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #endif

            	return positionCS;
            }
            
            ShadowCasterVaryings ShadowCasterVertex(ShadowCasterAttributes input)
			{
			    ShadowCasterVaryings output;

			    output.uv12.xy = input.texcoord.xy;
			    output.uv12.zw = input.texcoord1.xy;
			    output.positionCS = GetShadowPositionHClip1(input);
			    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);

            	output.screenPos = ComputeScreenPos(output.positionCS);
            	
			    return output;
			}
            half4 ShadowCasterFragmentBlend(ShadowCasterVaryings input) : SV_TARGET
			{
				//Dither //剔除ShaderLibrary引用文件，解耦出来独立毛发
            	//DitherThreshold(input.screenPos, input.positionCS.xy, _DitherTimer);

			    half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv12.xy).a * _FurColor.a;
			    #if defined(_ALPHATEST_ON)
			        clip(alpha - _Cutoff);
			    #endif
				
			    #if _SHADOWTRANSPARENCY
			        float2 screenPos = input.positionCS.xy / (input.positionCS.w + 0.0001);
			        transparencyClip(alpha, screenPos);
			    #endif

				//剔除ShaderLibrary引用文件，解耦出来独立毛发
				//================特效接口================
				// DissloveData dissloveData;
				// dissloveData = (DissloveData)0;
				// dissloveData.DissloveThreshold = _DissloveThreshold;
				// dissloveData.DissloveEdgeLength = _DissloveEdgeLength;
				// dissloveData.DissloveEdgeColor = _DissloveEdgeColor;
				
				// FresnelData fresnelData;
				// fresnelData = (FresnelData)0;
				// fresnelData.FresnelF0 = _FresnelF0;
				// fresnelData.FresnelColor = _FresnelColor;
				
				// EffectInout_Fur(TEXTURE2D_ARGS(_EffectsMaskTex, sampler_EffectsMaskTex),0.0h,input.positionWS.xyz,0.0h,0.0h, input.uv12.xy, dissloveData, fresnelData);
            	//================特效接口================
				
			    return 1;
			}
            
            ENDHLSL
        }
        //2 DepthOnly
    	Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }
            Stencil
            {
                Ref [_Stencil]
                Comp Always
                Pass Replace
                //ReadMask [_StencilReadMask]
                //WriteMask [_StencilWriteMask]
            }
            ZWrite On
            ColorMask 0
            Cull [_Cull]

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            // #pragma prefer_hlslcc gles
            //#pragma exclude_renderers d3d11_9x
            // #pragma target 2.0 

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment
            
            
            // #pragma shader_feature _ALPHABLEND_ON
            
            #pragma multi_compile_fragment _ _DISSLOVE_ON//[特效]溶解
            #pragma multi_compile_fragment _ _ALPHATEST_ON//[特效]传送门
            

            #include "ToonFur_Input.hlsl"
            #include "ToonFur_ForwardPass.hlsl"
            //#include "ShaderLibrary/CharacterDepthOnlyPass.hlsl"//剔除ShaderLibrary引用文件，解耦出来独立毛发

            struct DepthOnlyA2v
			{
			    float4 positionOS     : POSITION;
			    float2 texcoord1     : TEXCOORD0;
			    float2 texcoord2     : TEXCOORD1;
			    float3 color        : COLOR;
			};

            struct DepthOnlyV2f
			{
			    
			    float4 positionCS   : SV_POSITION;
			    float3 positionWS   : TEXCOORD0;
            	float4 uv12           : TEXCOORD1;
			    float4 screenPos : TeXCOORD3;
			};
            

            DepthOnlyV2f DepthOnlyVertex(DepthOnlyA2v input)
			{
			    DepthOnlyV2f output = (DepthOnlyV2f)0;
            	
			    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
			    output.positionCS = TransformWorldToHClip(output.positionWS);
			    output.screenPos = ComputeScreenPos(output.positionCS);

            	output.uv12.xy = input.texcoord1.xy;
            	output.uv12.zw = input.texcoord2.xy;
			    return output;
			}

            half4 DepthOnlyFragment(DepthOnlyV2f input) : SV_TARGET
			{
				//Dither //剔除ShaderLibrary引用文件，解耦出来独立毛发
            	//DitherThreshold(input.screenPos, input.positionCS.xy, _DitherTimer);

			    half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv12.xy).a * _FurColor.a;
			    #if defined(_ALPHATEST_ON)
			        clip(alpha - _Cutoff);
			    #endif

				//剔除ShaderLibrary引用文件，解耦出来独立毛发
				//================特效接口================
				// DissloveData dissloveData;
				// dissloveData = (DissloveData)0;
				// dissloveData.DissloveThreshold = _DissloveThreshold;
				// dissloveData.DissloveEdgeLength = _DissloveEdgeLength;
				// dissloveData.DissloveEdgeColor = _DissloveEdgeColor;

				// FresnelData fresnelData;
				// fresnelData = (FresnelData)0;
				// fresnelData.FresnelF0 = _FresnelF0;
				// fresnelData.FresnelColor = _FresnelColor;
					
				//EffectInout_Fur(TEXTURE2D_ARGS(_EffectsMaskTex, sampler_EffectsMaskTex),0.0h,input.positionWS.xyz,0.0h,0.0h, input.uv12.xy, dissloveData, fresnelData);
            	//================特效接口================

			    return 0;
			}
            
            ENDHLSL
        }
        //3 DepthNormals
    	Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }
			Stencil
            {
                Ref [_Stencil]
                Comp Always
                Pass Replace
                //ReadMask [_StencilReadMask]
                //WriteMask [_StencilWriteMask]
            }
        	
            Cull [_Cull]
            ZWrite On
            Blend One Zero
        	
            HLSLPROGRAM

            #pragma vertex DepthNormalsPassVertex
            #pragma fragment DepthNormalsPassFragment

            
            #pragma multi_compile_fragment _ _DISSLOVE_ON//[特效]溶解
            #pragma multi_compile_fragment _ _ALPHATEST_ON//[特效]传送门
            

            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            
            #include "ToonFur_Input.hlsl"
            #include "ToonFur_ForwardPass.hlsl"
            
            float usemask;
            //bloom mask功能
            // 顶点输入结构
            struct DNAttributes
            {
	            float4 positionOS : POSITION;
	            float2 texcoord : TEXCOORD0;
	            float2 texcoord1 : TEXCOORD0;
            	float3 normal :NORMAL;
                #if _MASKMAP
		        half4 tangentOS : TANGENT;
                #endif
	            UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // 顶点着色器输出结构
            struct DNVaryings
            {
	            float4 uv : TEXCOORD0;
	            float4 positionCS : SV_POSITION;
	            float4 projPos : TEXCOORD2;
            	float3 normalWS :TEXCOORD3;
                #if _MASKMAP
		        float3 tangentWS  : TEXCOORD4;    // xyz: tangent, w: viewDir.y
		        float3 bitangentWS : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
                #endif
                float3 posWS:TEXCOORD6;
	            UNITY_VERTEX_INPUT_INSTANCE_ID
	            UNITY_VERTEX_OUTPUT_STEREO
            };
            DNVaryings DepthNormalsPassVertex(DNAttributes input)
            {
	            DNVaryings output;
	            output.uv.xy = input.texcoord;
            	output.uv.zw = input.texcoord1;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
	            output.positionCS = vertexInput.positionCS;
                output.projPos = ComputeScreenPos (output.positionCS);
                output.normalWS = mul((float3x3)unity_ObjectToWorld,input.normal);
            	output.posWS = TransformObjectToWorld(input.positionOS.xyz);
                #if _MASKMAP
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normal, input.tangentOS);
	            output.tangentWS = vertexNormalInput.tangentWS;
	            output.bitangentWS = vertexNormalInput.bitangentWS;
                #endif
	            return output;
            }

            void DepthNormalsPassFragment(
                DNVaryings input
                , out half4 outNormalWS : SV_Target
            #ifdef _WRITE_RENDERING_LAYERS
                , out float4 outRenderingLayers : SV_Target1
            #endif
            )
            {
            	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
				//Dither //剔除ShaderLibrary引用文件，解耦出来独立毛发
            	//DitherThreshold(input.projPos, input.positionCS.xy, _DitherTimer);

			    half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy).a * _FurColor.a;
			    #if defined(_ALPHATEST_ON)
			        clip(alpha - _Cutoff);
			    #endif
            	

            	half3 normal = input.normalWS;
                #if _MASKMAP
            	half4 maskMap = SampleTexture(input.uv,TEXTURE2D_ARGS(_MaskMap,sampler_MaskMap));
            	half4 tangentNormal = half4(MergeTexUnpackNormalRG(maskMap,_BumpStrength),1.0h);
            	normal = TransformTangentToWorld(normal, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
                #endif
                    
                outNormalWS = half4(normal,1);
            	#ifdef _WRITE_RENDERING_LAYERS
                uint renderingLayers = GetMeshRenderingLayer();
                outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
                #endif

				//================特效接口================
				// DissloveData dissloveData;
				// dissloveData = (DissloveData)0;
				// dissloveData.DissloveThreshold = _DissloveThreshold;
				// dissloveData.DissloveEdgeLength = _DissloveEdgeLength;
				// dissloveData.DissloveEdgeColor = _DissloveEdgeColor;
				
				// FresnelData fresnelData;
				// fresnelData = (FresnelData)0;
				// fresnelData.FresnelF0 = _FresnelF0;
				// fresnelData.FresnelColor = _FresnelColor;
				
				// EffectInout_Fur(TEXTURE2D_ARGS(_EffectsMaskTex, sampler_EffectsMaskTex),0.0h,input.posWS.xyz,0.0h,0.0h, input.uv.xy, dissloveData, fresnelData);
            	//================特效接口================
            }
            
        	ENDHLSL   
        }
        //5 RoleMask
    	Pass
    	{
            Name "RoleBloomMask"
            Tags
            {
                "LightMode" = "RoleBloomMask"
            }
            Cull [_Cull]
            ZWrite On
            Blend One Zero
            HLSLPROGRAM
            #include "ToonFur_Input.hlsl"
            #include "ToonFur_ForwardPass.hlsl"
            #pragma multi_compile _ _USETEXTURE
            #pragma vertex BloomMaskPassVertex
            #pragma fragment BloomMaskPassFragment
            float usemask;
            Varyings BloomMaskPassVertex(Attributes input)
            {
	            Varyings output;
	            output.uv.xy = input.texcoord0;
	            output.positionCS = TransformObjectToHClip(input.vertex);
	            return output;
            }
            half4 BloomMaskPassFragment(Varyings input): SV_Target
            {
                half RoleMask = 0;
                // #if _USETEXTURE
                // //OD图 b通道作为bloom遮罩
                // RoleMask = SAMPLE_TEXTURE2D(_SepcularMaskMap,sampler_SepcularMaskMap,input.uv).a;
                // #elif
                // RoleMask = 1;
                // #endif
                //注释，不知道有没有用
                //RoleMask = lerp(1,SAMPLE_TEXTURE2D(_SepcularMaskMap,sampler_SepcularMaskMap,input.uv).a,usemask);
                return 1;
            }
            ENDHLSL
        }
        //6 PlanarShadow
    	Pass
        {
            Name "PlanarShadow"
            Tags
            {
                "LightMode" = "PlanarShadow"
            }
            
//          Stencil
//          {
//              Ref 0
//              Comp equal
//              Pass incrWrap
//              Fail keep
//              ZFail keep
//          }
            Stencil
            {
                Ref 192
                Comp NotEqual
                Pass Replace
                Fail keep
                ZFail keep
            }

            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            //Blend  OneMinusSrcAlpha Zero 
            //关闭深度写入
            //ZWrite On
            ZWrite Off
            ZTest Lequal
            //深度稍微偏移防止阴影与地面穿插
            Offset -1,0

            HLSLPROGRAM
            #pragma vertex PlanarShadowVertex
            #pragma fragment PlanarShadowFragment
            
            #pragma multi_compile_fragment _ _DISSLOVE_ON//[特效]溶解
            #pragma multi_compile_fragment _ _ALPHATEST_ON//[特效]传送门

            #include "ToonFur_Input.hlsl"
            #include "ToonFur_ForwardPass.hlsl"
            
            float _GroundHeight;
            float _ShadowFallOff;
            float4 _ShadowColor;
            float4 _ShadowLightDir;
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv1 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            	float3 positionWS : TEXCOORD0;
            	float4 uv12 : TEXCOORD1;
            	float4 screenPos : TEXCOORD3;
            };

            float3 ShadowProjectPos(float3 positionWS)
            {
                float3 shadowPos;

                float3 worldPos = positionWS;
                worldPos = GetAbsolutePositionWS(worldPos);

                //灯光方向
                Light mainLight = GetMainLight();
                float3 lightDir =  _ShadowLightDir.xyz;
                shadowPos.y = min(worldPos .y , _GroundHeight);
                shadowPos.xz = worldPos .xz - lightDir.xz * max(0 , worldPos .y - _GroundHeight) / lightDir.y; 
            	
                return shadowPos;
            }
            
            v2f PlanarShadowVertex(appdata v)
            {
                v2f o;

            	
            	o.positionWS = TransformObjectToWorld(v.vertex.xyz);
            	float3 shadowPos = ShadowProjectPos(o.positionWS);
            	
                o.vertex = TransformWorldToHClip(GetCameraRelativePositionWS(shadowPos));
                float4x4 worldMatrix = UNITY_MATRIX_M;//GetRawUnityObjectToWorld();
                float3 center = float3(worldMatrix[0].w , _GroundHeight , worldMatrix[2].w);
                float falloff = 1-saturate(distance(shadowPos , center) * _ShadowFallOff);
                o.color.rgba =_ShadowColor;
                o.color.a *= falloff;

            	o.uv12.xy = v.uv1.xy;
            	o.uv12.zw = v.uv2.xy;

            	o.screenPos = ComputeScreenPos(o.vertex);
            	
                return o;
            }

            half4 PlanarShadowFragment(v2f i) : SV_Target
			{
				//Dither //剔除ShaderLibrary引用文件，解耦出来独立毛发
            	//DitherThreshold(i.screenPos, i.vertex.xy, _DitherTimer);

			    half alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv12.xy).a * _FurColor.a;
			    #if defined(_ALPHATEST_ON)
			        clip(alpha - _Cutoff);
			    #endif

				//剔除ShaderLibrary引用文件，解耦出来独立毛发
				//================特效接口================
				// DissloveData dissloveData;
				// dissloveData = (DissloveData)0;
				// dissloveData.DissloveThreshold = _DissloveThreshold;
				// dissloveData.DissloveEdgeLength = _DissloveEdgeLength;
				// dissloveData.DissloveEdgeColor = _DissloveEdgeColor;
				
				// FresnelData fresnelData;
				// fresnelData = (FresnelData)0;
				// fresnelData.FresnelF0 = _FresnelF0;
				// fresnelData.FresnelColor = _FresnelColor;
				
				// EffectInout_Fur(TEXTURE2D_ARGS(_EffectsMaskTex, sampler_EffectsMaskTex),0.0h,i.positionWS.xyz,0.0h,0.0h, i.uv12.xy, dissloveData, fresnelData);
            	//================特效接口================
            	
                return i.color;
            }
            
            ENDHLSL
        	}
        //7
        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForwardReflection"
            }

            //https://docs.unity.cn/cn/current/Manual/SL-Stencil.html
            Stencil
            {
                Ref [_Stencil]                
                Comp Always
                Pass Replace
                //ReadMask [_StencilReadMask]
                //WriteMask [_StencilWriteMask]
            }
            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Blend [_SrcBlend] [_DstBlend]
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 3.0

            #pragma vertex Vertex
            #pragma fragment Fragment
            
            #pragma shader_feature_local _ _GGX _ANISOTROPY _PHONG
            // #pragma shader_feature_local _DIFFUSECEL
            #pragma shader_feature_local _EMISSION
            #pragma shader_feature_local _GLOSSYREFLECTIONS_ON
            #pragma shader_feature_local _USECUSTOMTONEMAP
            #pragma shader_feature_local _SCENE_ENV _CUSTOM_ENV_CUBE
            #pragma shader_feature_local _PEROBJSHADOWMASK
            // #pragma shader_feature_local _ _USE_DIFFUSERAMP_ID

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _PEROBJECTSHADOW
            #pragma multi_compile_fragment _ _DISSLOVE_ON
            #pragma multi_compile_fragment _ _WEAKNESS_ON

            //2024.9.29 暂时注释所有角色Shader的AlphaTest Keyword，避免美术材质因误开AlphaTest导致的效果问题。※角色传送门特效会失效
             #pragma shader_feature_local_fragment _ALPHATEST_ON
            
            #include "ToonFur_Input.hlsl"
            #include "ToonFur_ForwardPass.hlsl"
            // half lerpB;
            // half lerpA;
            // half ReflectionHeight;
            // Varyings VertexOutLerp(Attributes input)
            // {
            //    return Vertex(input);
            // }
            //
            // void ToonStylizedFragmentOutLerp(Varyings input,out half4 outColor : SV_Target
            // #ifdef _WRITE_RENDERING_LAYERS
            // , out float4 outRenderingLayers : SV_Target1
            // #endif
            // )
            // {
            //     lerpB = max(0,lerpB);
            //     
            //     ToonStylizedFragment(input,outColor
            //         #ifdef _WRITE_RENDERING_LAYERS
            //         , outRenderingLayers
            //         #endif
            //     );
            //
            //     half lerpline = max(0,lerpB*(input.positionWS.y-ReflectionHeight+lerpA));
            //     
            //     //half templerp = (smoothstep(input.positionWS.y,ReflectionHeight+lerpA,input.normalWS.y));
            //     
            //     outColor = lerp(outColor,half4(1,1,1,1),lerpline);
            //     #ifdef _WRITE_RENDERING_LAYERS
            //         uint renderingLayers = GetMeshRenderingLayer();
            //         outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
            //     #endif
            // }
            //
            ENDHLSL
        }

    	
	    //8Fur
        Pass
        {
            Name "HoudiniFurRenderLayer"
            Tags
            {
                "LightMode" = "HoudiniFurRendererLayer"
            }

            Stencil
            {
                Ref [_Stencil]
                Comp Always
                Pass Replace
            }
//                Cull [_Cull]
//                ZWrite [_ZWrite]
//                ZTest [_ZTest]
            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
        	Blend [_SrcBlend] [_DstBlend]
//            Blend SrcAlpha OneMinusSrcAlpha
        	

            HLSLPROGRAM
            
            // #pragma multi_compile _ _FUR_ON
            // #pragma multi_compile _ _FURBITANGENT

            #define _FUR_ON 1//用于区分外扩毛发层，和原本的模型层
            
            #pragma multi_compile_fragment _ _DISSLOVE_ON//[特效]溶解
            #pragma multi_compile_fragment _ _ALPHATEST_ON//[特效]传送门
            
            #pragma shader_feature_local _ _AODEEPEN//AO类型

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            //#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING // mix灯烘焙阴影需要
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS

            #pragma multi_compile_fog
            
            #pragma vertex vert_fur_Houdini
            #pragma fragment frag_fur
            
            #include "ToonFur_Input.hlsl"
            #include "ToonFur_ForwardPass.hlsl"
            ENDHLSL
        }
    }
    //FallBack "Hidden/ShiYue/FallbackError"
    CustomEditor "CustomShaderEditor.CustomShaderGUI_Character"
}