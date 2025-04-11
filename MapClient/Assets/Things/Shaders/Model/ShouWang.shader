Shader "ShouWang"
{
    Properties
    {
        [CustomGroup] _MapSetting("基础设置",float) = 1.0
    	[CustomHeader(_MapSetting)] _BaseMapTip("RGB-颜色  A:不透明度", Float) = 1
        [CustomTexture(_MapSetting)] [_MainTex]_BaseMap ("固有色贴图", 2D) = "white" {}
        [CustomObject(_MapSetting)] _BaseColor(" ", Color) = (1, 1, 1, 1)
    	
        [CustomGroup] _NPRSetting("PBR参数设置", float) = 1.0
        [CustomHeader(_NPRSetting)] _NPRLightMapTip("R-金属度 G-光滑度 B-ID A-高光强度遮罩", Float) = 1
        [CustomTexture(_NPRSetting)] _NPRLightMap ("_Mask图 ", 2D) = "gray" {} // MAPLINE = _NPRLightMap
        [CustomHeader(_NPRSetting)] _MaskMapTip("RG-法线 B-AO A-自发光", Float) = 1
        [CustomTexture(_NPRSetting, _MASKMAP)] _MaskMap ("_OD图", 2D) = "gray" {} // MAPLINE = _MaskMap
        [CustomObject(_NPRSetting)] _BumpStrength ("法线强度", Range(-2,2)) = 1
        [CustomObject(_NPRSetting)]_MetallicScale("金属度强度", Range(0, 1.0)) = 1.0
        [CustomObject(_NPRSetting)]_MetallicBias("金属度对比度", Range(-1.0, 1.0)) = 0.0
        [CustomObject(_NPRSetting)]_SmoothnessBias("光滑度对比度", Range(-1.0, 1.0)) = 0
    	[CustomObject(_NPRSetting)]_SmoothnessScales("光滑度缩放", Range(-1.0, 1.0)) = 0
        [CustomObject(_NPRSetting)] _AOIntensity ("AO强度", Range(0.0,1)) = 1
        
    	
    	[CustomGroup] _DiffuseSetting("阴影设置",float) = 1.0
    	[CustomKeywordEnum(_DiffuseSetting, _RAMPSHADING,_CELSHADING)] _DiffuseType ("漫反射类型", float) = 0
        [CustomToggle(_DiffuseSetting)] _UseHalfLambert ("使用HalfLambert（偏卡通）", float) = 1 // no key
    	[CustomHeader(_DiffuseSetting._RAMPSHADING)] _RampTip("Ramp阴影", Float) = 1
        [CustomHeader(_DiffuseSetting._RAMPSHADING)] _RampMapTip("Ramp图", float) = 1
        [CustomRampTexture(_DiffuseSetting._RAMPSHADING)] _RampMap ("过渡贴图", 2D) = "white" {}
        [CustomObject(_DiffuseSetting._RAMPSHADING)] _RampYOffset ("ID 偏移", Range(0, 1)) = 0
    	[CustomHeader(_DiffuseSetting._CELSHADING)] _DHDIFFUSECEL("二分阴影", float) = 1
    	[CustomObject(_DiffuseSetting._CELSHADING)] _HColor ("亮部颜色", Color) = (1, 1, 1, 1)
        [CustomObject(_DiffuseSetting._CELSHADING)] _SColor ("暗部颜色", Color) = (0.2, 0.2, 0.2, 1)
        [CustomObject(_DiffuseSetting._CELSHADING)] _RampThreshold ("阴-阈值", Range(0.01, 1)) = 0.5
        [CustomObject(_DiffuseSetting._CELSHADING)] _RampSmoothing ("阴-过渡羽化程度", Range(0.001, 1.0)) = 0.001
    	
        [CustomGroup] _MatCapSetting("MatCap设置", float) = 1
        [CustomToggle(_MatCapSetting, _MATCAP)] _UseMatCap ("开启MatCap", Float) = 0
        [CustomHeader(_MatCapSetting._MATCAP)] _MatCapHeader("提示：MatCap遮罩为金属度", float) = 1
        [CustomTexture(_MatCapSetting._MATCAP)] _MatCapMap ("MatCap", 2D) = "black" {}
        [CustomObject(_MatCapSetting._MATCAP)] _MatCapColor ("MatCap颜色", Color) = (1,1,1,1)
        [CustomObject(_MatCapSetting._MATCAP)] _MatcapIntensity ("MatCap强度", Range(0,8)) = 1

        [CustomGroup] _SpecularSetting("高光设置", float) = 1.0
    	//[CustomBlockBegin(_SpecularSetting, 0.4, 0.4, 0.4, 1, 0.9, 0.9, 0.9, 1)] _GGXBlockBegin("普通PBR高光", Float) = 1
        [CustomObject(_SpecularSetting)] _SpecularColor ("高光颜色", Color) = (1,1,1,1)
    	[CustomObject(_SpecularSetting)] _SpecularColorBlender ("颜色混合固有色", Range(0.0, 1)) = 0.8
        [CustomObject(_SpecularSetting)] _SpecularIntensity ("高光强度", Range(0,8)) = 1
        [CustomObject(_SpecularSetting)] _MetaIntensity ("金属高光强度叠加", Range(0,8)) = 0
    	//[CustomBlockEnd(_SpecularSetting)] _GGXBlockEnd("普通PBR高光", Float) = 1
    	
		//[CustomBlockBegin(_SpecularSetting, 0.4, 0.4, 0.4, 1, 0.9, 0.9, 0.9, 1)] _AnisotropyBlockBegin("各向异性PBR高光", Float) = 1
		//[CustomToggle(_SpecularSetting, _ANISOTROPY)] _SpecularAnisotropyToggle ("使用各向异性PBR高光", Float) = 1
		//[CustomObject(_SpecularSetting._ANISOTROPY)] _SpecularAnisotropyColor ("高光颜色", Color) = (1, 1, 1, 1)
		//[CustomObject(_SpecularSetting._ANISOTROPY)] _SpecularAnisotropyIntensity("高光强度", Range(0.0, 30)) = 1
		//[CustomObject(_SpecularSetting._ANISOTROPY)] _Anisotropy ("各向异性强度", Range(-1.0, 1.0)) = 0.0
		//[CustomObject(_SpecularSetting._ANISOTROPY)] _SpecularAnisotropyClamp("高光钳制", Range(0.0, 50)) = 5
		//[CustomBlockEnd(_SpecularSetting)] _AnisotropyBlockEnd("各向异性PBR高光", Float) = 1
        
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
        
	    [CustomGroup] _RimSetting("边缘光设置",float) = 1.0
        [CustomObject(_RimSetting)] _RimDirContribution("边缘光影响程度",Range(0,1)) =0
        [CustomEnum(_RimSetting,Add,0,Mul,1)] _RimColorBlendMode("颜色混合模式", float) = 0
        [CustomObject(_RimSetting)][HDR] _RimColor("边缘光颜色",Color) = (1,1,1,1)
        [CustomToggle(_RimSetting)] _RimMaskUseShadow ("边缘光使用投影遮罩", Float) = 0
        [CustomObject(_RimSetting)] _RimThreshold("边缘光阈值",Range(0,1)) = 0.2
        [CustomObject(_RimSetting)] _RimSmooth("边缘光过渡",Range(0.001,1)) = 0.01
        [CustomHeader(_RimSetting)] _DH10("自定义方向",Float) = 0
        [CustomToggle(_RimSetting)] _RimCustom("自定义方向", Float) = 1.0
        [CustomLightDir(_RimSetting)] _RimDir("边缘光方向",vector) =(0.5,0.5,0.5,1)
        [CustomHeader(_RimSetting)] _DH9("非自定义方向",Float) = 0
        [CustomObject(_RimSetting)] _LightDirOffset("光照方向偏移",Range(-1,1)) = -1
    	
        [CustomGroup] _EmissionSetting("自发光设置",float) = 1.0
        [CustomToggle(_EmissionSetting, _EMISSION)] _emission ("开启自发光", Float) = 0
        [CustomTexture(_EmissionSetting)] _EmissionMap ("自发光贴图", 2D) = "black" {}
        [CustomObject(_EmissionSetting)]_EmissionColor ("自发光颜色", Color) = (1,1,1,1)
        [CustomObject(_EmissionSetting)]_Emission_Instensity ("自发光强度", Range(0,10)) = 1
        
    	[CustomGroup] _ShadowSetting("投影设置",float) = 1.0
        [CustomToggleOff(_ShadowSetting ,_RECEIVE_MAIN_SHADOWS_OFF)] _ReceiveMainLightShadow1("接收主光投影", Float) = 1
	    [HideInInspector] [CustomObject(_ShadowSetting)] _CustomShadowDepthBias("投影朝深度偏移", Range(0.01,20)) = 1
	    [HideInInspector] [CustomObject(_ShadowSetting)] _CustomShadowNormalBias("投影朝法线偏移", Range(0.01,20)) = 1
        //[CustomToggle(_ShadowSetting,_RECEIVE_PEROBJECT_SHADOWS)] _ReceivePerObjectShadow("接收角色专用投影", Float) = 0
        [CustomObject(_ShadowSetting)] _ShadowIntensity("投影强度", Range(0, 1)) = 1
        [CustomObject(_ShadowSetting)] _CustomShadowBias("投影偏移", Range(0, 0.04)) = 0
    	
	    [CustomGroup] _OutLineSetting("描边设置",float) = 1.0
        [CustomKeywordEnum(_OutLineSetting, _Tangent, _VertexColor, _Normal, _UV2, _UV3, _UV4)] _OutlineType ("平滑法线来源 ", float) = 0
        [CustomToggle(_OutLineSetting,USEOUTLINE)] _UseOutline("开启描边", Float) = 0
        [CustomObject(_OutLineSetting)] _OutlineColor("描边颜色",Color) =(0,0,0,1)
        [CustomObject(_OutLineSetting)] _Outline_Width("描边宽度",Range(0,10)) =1
    	
        
        [CustomGroup] _StencilSetting("模板设置",float) = 1.0
        [CustomObject(_StencilSetting)] _StencilComp ("Stencil Comparison", Float) = 8
        [CustomObject(_StencilSetting)] _Stencil ("Stencil ID", Float) = 6      //模板值为6,作为角色默认值
        [CustomObject(_StencilSetting)] _StencilOp ("Stencil Operation", Float) = 2
        [CustomObject(_StencilSetting)] _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [CustomObject(_StencilSetting)] _StencilReadMask ("Stencil Read Mask", Float) = 255
    	
    	
    	[HideInInspector] _StoryLightDir ("_StoryLightDir", Vector) = (0, 0, 1, 0)

		[HideInInspector][HDR]_ProceduralColor ("Procedural Color", Color) = (1, 1, 1, 1)
        
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
        	
            Cull [_Cull]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Blend [_SrcBlend] [_DstBlend]

            HLSLPROGRAM

            #pragma vertex Vertex
            #pragma fragment Fragment
            
            //// -------------------------------------
            #pragma multi_compile_fragment _ _ALPHATEST_ON
            
            #pragma multi_compile_local _ _RECEIVE_MAIN_SHADOWS_OFF
            //#pragma multi_compile_local _ _RECEIVE_PEROBJECT_SHADOWS

            
			// -------------------------------------
            //ShaderFeature
            #pragma multi_compile _CELSHADING _RAMPSHADING//阴影类型
            #pragma multi_compile _ _EMISSION
            #pragma multi_compile _ _MATCAP
            //#pragma shader_feature_local _ _ANISOTROPY//各向异性高光
            #pragma multi_compile _ _GLOSSYREFLECTIONS_ON
            #pragma multi_compile _BAKE_ENV _CUSTOM_ENV_CUBE

            
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            //#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING // mix灯烘焙阴影需要
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fragment _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS
            //#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"

            
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY


            #include "../CGInclude/ShouWang_Input.hlsl"
            #include "../CGInclude/ShouWang_ForwardPass.hlsl"
            
            ENDHLSL
        }
    	
        Pass//ShadowCaster
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


            #include "../CGInclude/ShouWang_Input.hlsl"

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
            
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float2 texcoord     : TEXCOORD0;
                float3 color        : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
            };
            
            float4 GetShadowPositionHClip(Attributes input)
            {
                //风效
                #if defined (_WIND_ON)
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                float2 WindUV =  (_Time.yy + vertexInput.positionWS.xz) * _WindSpeed/25;
                input.positionOS.xyz += SAMPLE_TEXTURE2D_LOD(_NoiseMap, sampler_NoiseMap, WindUV,0)  * _WindStrength * input.color.g;
                #endif

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
                #endif

                return positionCS;
            }
            
            Varyings ShadowPassVertex(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }
            
            half4 ShadowPassFragmentBlend(Varyings input) : SV_TARGET
            {
                half alpha = SampleMainTex(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a * _BaseColor.a;

                #if defined(_ALPHATEST_ON)
					clip(alpha - _Cutoff);
                #elif _ALPHABLEND_ON
					float2 screenPos = input.positionCS.xy / (input.positionCS.w + 0.0001);
					transparencyClip(alpha, screenPos);
                #endif
                return 0;
            }
            ENDHLSL
        }
        Pass//DepthOnly
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

            #include "../CGInclude/ShouWang_Input.hlsl"
            struct Attributes
            {
                float4 position     : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 color        : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv           : TEXCOORD0;
                float4 positionCS   : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings DepthOnlyVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);

                //风效
                #if defined (_WIND_ON)
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.position.xyz);
                float2 WindUV =  (_Time.yy + vertexInput.positionWS.xz) * _WindSpeed/25;
                input.position.xyz += SAMPLE_TEXTURE2D_LOD(_NoiseMap, sampler_NoiseMap, WindUV,0)  * _WindStrength * input.color.g;
                #endif

                output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                output.positionCS = TransformObjectToHClip(input.position.xyz);
                return output;
            }

            half4 DepthOnlyFragment(Varyings input) : SV_TARGET
            {
                half alpha =SampleMainTex(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a*_BaseColor.a;
                #if defined(_ALPHATEST_ON)
                clip(alpha - _Cutoff);
                #endif
                return 0;
            }
            ENDHLSL
        }
	    Pass//OutLine
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
            #pragma shader_feature USEOUTLINEMAP
            #pragma shader_feature USEOUTLINE
            #pragma multi_compile _ _Tangent _VertexColor  _Normal  _UV2 _UV3 _UV4
            #pragma vertex OutlinePassVertNew
            #pragma fragment OutlinePassFragmentNew

            #include "../CGInclude/ShouWang_Input.hlsl"
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 texcoord     : TEXCOORD0;
                float3 normalOS     : NORMAL;
                float4 color : COLOR;
                float4 tangentOS : TANGENT;
                
                #if defined(_UV2)
                float4 texcoord2 : TEXCOORD1;
                #endif
                
                #if defined(_UV3)
                float4 texcoord3 : TEXCOORD2;
                #endif
                
                #if defined(_UV4)
                float4 texcoord4 : TEXCOORD3;
                #endif
		            
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv  : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            float3x3 GetTBNMatrix(Attributes input)
            {
                float3 normalOS = input.normalOS;
                float4 tangentOSOS = input.tangentOS;
                float3 binormal = cross(normalize(normalOS),
                    normalize(tangentOSOS.xyz)) * tangentOSOS.w;

                float3x3 objectToTangentMatrix = float3x3(tangentOSOS.xyz, binormal, normalOS);

                return objectToTangentMatrix;
            }

            float3x3 GetTBNMatrixInverseObject(Attributes input)
            {
                float3 normalOS = input.normalOS;
                float4 tangentOSOS = input.tangentOS;
                float3 binormalOS = cross(normalize(normalOS), normalize(tangentOSOS.xyz)) * tangentOSOS.w;

                float3 matRow1 = float3(tangentOSOS.x, binormalOS.x, normalOS.x);
                float3 matRow2 = float3(tangentOSOS.y, binormalOS.y, normalOS.y);
                float3 matRow3 = float3(tangentOSOS.z, binormalOS.z, normalOS.z);

                float3x3 tangentOSToObjectMatrix = float3x3(matRow1, matRow2, matRow3);

                return tangentOSToObjectMatrix;
            }

            float3 GetNormalOS(float3 normalTS, Attributes input)
            { 
                float3x3 objectToTangentMatrix = GetTBNMatrix(input);
                float3 normalOS = normalize(mul(normalTS, objectToTangentMatrix));
                return  normalOS;
            }
            
            float3 GetNormalOS2(float3 normalTS, Attributes input)
            {
                float3x3 TBNMatrixInverse = GetTBNMatrixInverseObject(input);

                float3 normalOS = mul(TBNMatrixInverse, normalTS);
                            
                return  normalOS;
            }
            
            ///
            ///https://zhuanlan.zhihu.com/p/109101851
            ///
            Varyings OutLinePassVertex(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

	            #ifdef COLORS_AS_NORMALS
                //Vertex Color for Normals
                float3 normalOS = (input.color.xyz*2) - 1;
	            #elif TANGENT_AS_NORMALS
                //Tangent for Normals
                float3 normalOS = input.tangentOS.xyz;
	            #elif UV2_AS_NORMALS
                //UV2 for Normals
                float3 n;
                //unpack uv2
                v.uv2.x = input.uv2.x * 255.0/16.0;
                n.x = floor(v.uv2.x) / 15.0;
                n.y = frac(v.uv2.x) * 16.0 / 15.0;
                //get z
                n.z = input.uv2.y;
                //transform
                n = n*2 - 1;
                float3 normalOS = n;
	            #else
                float3 normalOS = input.normalOS;
	            #endif

                //观察空间
                float4 positionCS = TransformObjectToHClip(input.positionOS.xyz);

                //float3 normalWS = TransformObjectToWorldNormal(normalOS);
                //float3 normalVS = TransformWorldToViewDir(normalWS);
                //NDC空间的法线
                float3 normalVS = mul((float3x3)UNITY_MATRIX_IT_MV, normalOS.xyz);
                float2 normalNDC = normalize(TransformWViewToHClip(normalVS.xyz)).xy;// * positionCS.w;//将法线变换到NDC空间

                float aspect = abs(_ScreenParams.y / _ScreenParams.x);//求得屏幕宽高比
                normalNDC.xy *= float2(aspect,1);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                half3 viewDirWS = GetCameraPositionWS() - positionWS;
                float distance = length(viewDirWS);
                float scale =  GetOutLineScale(distance);

                float2 Outline_Width = _Outline_Width * 0.002 * normalNDC.xy * scale;
                
                positionCS.xy += Outline_Width;

                positionCS.xy += 1;
                
                //UCTS_Outline Z-axis
                #if defined(UNITY_REVERSED_Z)
                    //v.2.0.4.2 (DX)
                    _Offset_Z = _Offset_Z * - 0.01;
                #else
                    //OpenGL
                    _Offset_Z = _Offset_Z * 0.01;
                #endif

                float4 _ClipCameraPos = mul(UNITY_MATRIX_VP, float4(GetCameraPositionWS(), 1));
                float  OffsetZ =  _Offset_Z * _ClipCameraPos.z;
                positionCS.z += OffsetZ;

                output.positionCS = positionCS;
                
                output.uv = input.texcoord;
                return output;
            }

            half4 OutlinePassFragment(Varyings input) : SV_Target
            {
                // half3 baseColor = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap, input.uv).xyz;
                // return half4(lerp(_OutlineColor.rgb,baseColor.rgb,_UseColorOrMap),1);
                return half4(_OutlineColor.rgb,1);
            }

            float GetOutlineWidth(Attributes input)
            {
	            // 随机宽度控制
                // float2 noiseUV = TRANSFORM_TEX(input.texcoord, _RandomWidthNoiseTex);
                // // float4 nosieWidth = tex2Dlod(_RandomWidthNoiseTex, float4(noiseUV, 0, 0));
                // half4 nosieWidth = SAMPLE_TEXTURE2D_LOD(_RandomWidthNoiseTex, sampler_RandomWidthNoiseTex, input.texcoord, 0);
                //
                // //将nosieWidth范围从 0到1 映射到 -1到1
                // nosieWidth = nosieWidth * 2 - 1;
				            // 	
                // half outlineWidth = _Outline_Width +  clamp(
                //         _Outline_Width * nosieWidth * _RandomWidthAmplify,
                // //宽度最多减少多少    1 - _RandomWidthMinRatio 表示宽度最多减少的百分比
                // -_Outline_Width * (1 - _RandomWidthMinRatio),
                // //宽度最多增加多少   _RandomWidthMaxRatio - 1  表示宽度最多增加的百分比
                // _Outline_Width * (_RandomWidthMaxRatio - 1));
                float outlineWidth = _Outline_Width;
                return outlineWidth;
            }

            Varyings OutlinePassVertNew (Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                #if defined(USEOUTLINE)
                    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                    float3 normal = input.normalOS.xyz;

                    //宏保留着  后面可能要增加存的语义
                    // #if _VertexColor
                        //通过自算逆矩阵的方式 可行
                        // normal = GetNormalOS2(v.color.xyz * 2 - 1, v);
                        //通过mul参数互换的方式 可行
                        normal = GetNormalOS(input.color.xyz * 2 - 1, input);
                    // #elif _UV2
                    // normal = input.texcoord2.xyz;
                    // #elif _UV3
                    // normal = input.texcoord3.xyz;
                    // #elif _UV4
                    // normal = input.texcoord4.xyz;
                    // #endif
                
                    normal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, normal));
                    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
                    
                    // float2 projNoraml = TransformViewToProjection(normal.xy);
                    // float2 projNoraml = ((float2x2)GetViewToHClipMatrix(), normal.xy);
                    // float4 projNoraml = ((float2x2)GetViewToHClipMatrix(), normal.xy);

                    float4 projNoraml = TransformWViewToHClip(normal);
				                
                    float outlineWidth = GetOutlineWidth(input);
                    outlineWidth *= input.color.a;
				                
                    #if CLOSE_FAR_SAME
                    // outlineWidth *= 1.5;
                    //float sameDegree = lerp(1, output.positionCS.w, _CloseFarSameDegree);
                    //output.positionCS.xy += sameDegree * projNoraml * outlineWidth * 0.01; 
                    output.positionCS.xy += projNoraml * outlineWidth * 0.01; 
                    #else
                    output.positionCS.xy +=  projNoraml.xy * outlineWidth * 0.01;
                    #endif
                #else
                    output.positionCS = 0;
                #endif
                return output;
            }

            half4 OutlinePassFragmentNew (Varyings input) : SV_Target
            {
                #if defined(USEOUTLINE)
                    half4 finalOutlineColor;
                    #if defined(USEOUTLINEMAP)
                        half4 outlineMapColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                        finalOutlineColor.rgb = outlineMapColor.rgb * _OutlineColor.rgb * _ProceduralColor.rgb;
                    #else
                        finalOutlineColor.rgb = _OutlineColor.rgb * _ProceduralColor.rgb;
                    #endif
                        finalOutlineColor.a = _ProceduralColor.a;
                        return finalOutlineColor;
                #else
                    return 0;
                #endif
            }
            ENDHLSL
        }
    }
	FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "CustomShaderEditor.CustomShaderGUI_Character"
}
