Shader "BackOutline_High"
{
    Properties
    {
    	[CustomGroup] _BaseSetting("基础设置", Float) = 1.0
        [CustomTexture(_BaseSetting)][NoScaleOffset] _MainTex("RGB:颜色  A:透贴", 2D) = "white" {}
    	[CustomObject(_BaseSetting)][HDR] _BaseColor("主颜色 A通道透明拉条", Color) = (1, 1, 1, 1)
        [CustomTexture(_BaseSetting)][NoScaleOffset] _NormalMap("法线贴图", 2D) = "bump" {}
        [CustomObject(_BaseSetting)] _NormalIntensity("法线强度", Range(0, 2)) = 1
    	
	    [CustomToggle(_BaseSetting,GAME_GREY)] _Grey("是否灰度", Float) = 0
        
    	[CustomGroup] _MapSetting("遮罩图设置", Float) = 1.0 
        [CustomHeader(_MapSetting)] _LightMapTip("R:RampID  G:高光强度  B:硬阴影  A:自发光", Float) = 1
        [CustomTexture(_MapSetting)][NoScaleOffset] _LightMap("Light Map", 2D) = "white" {}
        //[CustomObject(_MapSetting)] _InnerOutlineColor("内描边颜色", Color) = (0, 0, 0, 1)
        //[CustomObject(_MapSetting)] _InnerOutlineColorAlbedoWeight("内描边混合固有色权重", Range(0, 1)) = 0.5
    	[CustomObject(_MapSetting)] _HardShadowColor("硬阴影颜色", Color) = (0, 0, 0, 1)
        [CustomObject(_MapSetting)] _HardShadowColorAlbedoWeight("硬阴影混合固有色权重", Range(0, 1)) = 0.5
        //[CustomHeader(_MapSetting)] _MaskTip("R:自发光  GBA:空", Float) = 1
        //[CustomTexture(_MapSetting)][NoScaleOffset] _MaskMap("Mask Map", 2D) = "white" {}
        
    	
    	[CustomGroup] _DiffuseSetting("阴影设置", Float) = 1.0
        [CustomTexture(_DiffuseSetting)] _RampMap("Ramp图", 2D) = "white" {} 
        [CustomHeader(_DiffuseSetting)] _RampMapTip("ID通道：LightMap_R", Float) = 1 
        [CustomObject(_DiffuseSetting)] _RampYOffset("ID 偏移", Range(0, 1)) = 0 
    	
    	
    	[CustomGroup] _SpecularSetting("高光设置", Float) = 1.0
    	[CustomObject(_SpecularSetting)][HDR] _SpecularColor ("高光颜色", Color) = (1, 1, 1, 1)
	    [CustomObject(_SpecularSetting)] _SpecularIntensity ("高光强度", Range(0, 8)) = 1
        [CustomObject(_SpecularSetting)] _MetaIntensity ("金属高光强度叠加", Range(0, 8)) = 0
	    [CustomObject(_SpecularSetting)] _SpecularToonSize("高光大小", Range(0, 1)) = 0.1
        [CustomObject(_SpecularSetting)] _SpecularToonSmoothness("高光边缘柔软度", Range(0.001, 1)) = 0.05
        [CustomObject(_SpecularSetting)] _SpecularAlbedoWeight("高光混合固有色权重", Range(0, 1)) = 0
    	
    	
    	[CustomGroup] _EmissionSetting("自发光设置", Float) = 1.0
        [CustomObject(_EmissionSetting)][HDR] _EmissionColor("自发光颜色", Color) = (1, 1, 1, 1)
        [CustomObject(_EmissionSetting)]_EmissionColorBlendAlbedo("自发光混合固有色权重", Range(0, 1)) = 0.5
        [CustomObject(_EmissionSetting)]_EmissionColorBrightness("自发光亮度", Range(0, 10)) = 0


		[CustomGroup] _MatcapSetting("Matcap设置", Float) = 1.0
		[CustomTexture(_MatcapSetting)]_MatcapTex("Matcap反射", 2D) = "black" {}
        [CustomTexture(_MatcapSetting)]_MatcapMask("Matcap遮罩", 2D) = "white" {}	
        [CustomObject(_MatcapSetting)][HDR] _MatcapColor("Matcap颜色", Color) = (1, 1, 1, 1)
        [CustomObject(_MatcapSetting)]_MatcapIntensity("Matcap强度", Range(0, 1)) = 0.5

        
    	[CustomGroup] _RimSetting("边缘光设置",float) = 1.0
    	[CustomToggle(_RimSetting,_USERIM)] _useRim("使用边缘光", Float) = 0
	    [CustomLightDir(_RimSetting._USERIM)] _RimLightDir("边缘光方向",vector) =(0.5, 0.5, 0.5, 1)
        [CustomObject(_RimSetting._USERIM)] _RimThreshold("边缘光范围", Range(0, 1)) = 0.5
        [CustomObject(_RimSetting._USERIM)] _RimSoftness("边缘光过渡柔软度", Range(0.01, 1)) = 0.5
        [CustomToggle(_RimSetting)]_AddRamp("默认替换模式，更换为叠加模式",float) = 0 
        [CustomObject(_RimSetting._USERIM)] _RimColorBlend("边缘光混合固有色权重", Range(0, 1)) = 0
        [CustomObject(_RimSetting)][HDR]_FresnelColor("内层边缘光颜色", Color) = (0,0,0,0)
        [CustomObject(_RimSetting)]_RimLightEffect("内层边缘光光照影响", Range( 0 , 1)) = 0
        
	    [CustomGroup] _OutlineSetting("描边设置", Float) = 1.0
    	[CustomKeywordEnum(_OutlineSetting,VERTEXNORMAL,VERTEXCOLOR,SMOOTHNORMALUV2,SMOOTHNORMALUV3)] _NormalSelect("描边模式选择", Float) = 0
	    
    	[CustomBlockBegin(_OutlineSetting, 0.4, 0.4, 0.4, 1, 0.9, 0.9, 0.9, 1)] _OutlineColorBlockBegin("描边颜色项", Float) = 1
		[CustomObject(_OutlineSetting)] _OutlineColor("描边颜色", Color) = (0, 0, 0, 1)
    	[CustomToggle(_OutlineSetting, _DyeColor)]_DyeColorOn("彩色描边开关，id在顶点色R通道", float) = 0
    	[CustomTexture(_OutlineSetting._DyeColor)] _DeyTex("颜色贴图", 2D) = "black"{}
    	[CustomToggle(_OutlineSetting._DyeColor)] _OutlineUseRampID("用RampID精度更高，保持灰度和顶点色R通道一样即可", float) = 0
        [CustomBlockEnd(_OutlineSetting)] _OutlineColorBlockEnd("描边颜色项", Float) = 1
    	
    	[CustomBlockBegin(_OutlineSetting, 0.4, 0.4, 0.4, 1, 0.9, 0.9, 0.9, 1)] _OutlineSettingBlockBegin("描边参数项", Float) = 1
	    [CustomObject(_OutlineSetting)] _OutlineWidth("描边宽度，默认顶点色A通道为遮罩", Range(0, 10)) = 1
    	[CustomToggle(_OutlineSetting)]_NoiseItensity("裁切噪声开关", float) = 0
    	[CustomTexture(_OutlineSetting)]_Noise("裁切噪声图 Offest流动", 2D) = "white" {}
	    //正面剔除
	    //[CustomObject(_OutlineSetting)]_Threshold("噪声裁切阈值", Range( 0 , 1)) = 0
	    //背面剔除
	    [CustomObject(_OutlineSetting)]_FresnelStength("水墨描边层数", Range( 1 , 10)) = 0
		[CustomObject(_OutlineSetting)]_FresnelPower("水墨描边范围", Range( 0.01 , 10)) = 0
		[CustomObject(_OutlineSetting)]_AlpahTreshold("水墨描边阈值", Range( 0 , 1)) = 0
	    [CustomObject(_OutlineSetting)]_LightEffect("光照影响", Range( 0 , 1)) = 0
    	[CustomBlockEnd(_OutlineSetting)] _OutlineSettingBlockEnd("主贴图AO降色控制", Float) = 1
    	
		[CustomObject(_OutlineSetting)]_ScaleDepth("深度偏移整体",Range(-1,1)) = 0
	    [CustomObject(_OutlineSetting)]_Offset_Factor ("深度偏移内描边", Float ) = 100
		[CustomObject(_OutlineSetting)]_Scale ("程序控制skinmesh缩放影响（美术勿动）", float) = 1

		[HideInInspector][HDR]_ProceduralColor ("Procedural Color", Color) = (1, 1, 1, 1)
        
	    //渲染设置
        [HideInInspector] _Surface("_surface", Float) = 0.0
        [HideInInspector] _AlphaClip("_alphaclip", Float) = 0.0
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _Cull ("__cull", Float) = 2   //[Enum(Cull Off,0, Cull Front,1, Cull Back,2)]
        [HideInInspector] _Cutoff("裁剪精度", Range(0.0, 1.0)) = 0.5
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
        [HideInInspector] _ZTest ("__zt", Float) = 4.0
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
		[HideInInspector] _StencilID("ID",Float) = 0.0
		[HideInInspector] _StencilCom("Com",Float) = 0.0
		[HideInInspector] _StencilPass("Pass",Float) = 0.0
    }
    SubShader
    {
	Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        
        HLSLINCLUDE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            TEXTURE2D(_LightMap); SAMPLER(sampler_LightMap);
            TEXTURE2D(_MaskMap); SAMPLER(sampler_MaskMap);
            TEXTURE2D(_RampMap); SAMPLER(sampler_RampMap);
			TEXTURE2D(_Noise); SAMPLER(sampler_Noise);
			TEXTURE2D(_DeyTex);SAMPLER(sampler_DeyTex);
        	TEXTURE2D(_MatcapTex);	SAMPLER(sampler_MatcapTex);
			TEXTURE2D(_MatcapMask);	SAMPLER(sampler_MatcapMask);
            CBUFFER_START(UnityPerMaterial)

			half4 _BaseColor,//基础设置
			_InnerOutlineColor, _HardShadowColor, //遮罩图设置
			_SpecularColor, //高光设置
			_EmissionColor,//自发光设置
			_RimLightDir, _RimColor, _FresnelColor,//边缘光设置
			_OutlineColor,//描边设置
			_MatcapMask_ST,_MatcapColor,//matcap
			_ProceduralColor;

			float4 _Noise_ST;

			float _OutlineWidth, _ScaleDepth;//描边设置
        
			half
			_NormalIntensity,//基础设置
			_InnerOutlineColorAlbedoWeight, _HardShadowColorAlbedoWeight,//遮罩图设置
			_RampYOffset,//阴影设置
			_SpecularIntensity, _MetaIntensity, _SpecularToonSize, _SpecularToonSmoothness, _SpecularAlbedoWeight,//高光设置
			_EmissionColorBlendAlbedo, _EmissionColorBrightness,//自发光设置
			_useRim, _RimColorBlend, _RimThreshold, _RimSoftness,//边缘光设置
			_FresnelSmooth, _MainFrresnel, _FresnelScale, _RimLightEffect, _AddRamp, //替换边缘光
			_FresnelStength, _FresnelPower, _AlpahTreshold, _NoiseItensity, _LightEffect, //描边设置
			_MatcapIntensity,//matcap
			_Scale, _OutlineSpeed, _Threshold, _OutlineUseRampID; //描边设置
        
            CBUFFER_END
	
			#define unity_ColorSpaceLuminance half4(0.0396819152, 0.458021790, 0.00609653955, 1.0)
        
        ENDHLSL

        Pass
        {
            Name "Character_Cartoon_Color"
            Tags
            {
            	"RenderType" = "Opaque"
            	"Queue" = "Geometry"
                "LightMode" = "UniversalForward"
            }
        	
        	Blend[_SrcBlend][_DstBlend]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
            Cull[_Cull]
            
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma target 3.0

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _USERIM
            #pragma multi_compile_local __ GAME_GREY

            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            

            struct a2v
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                half3 normalOS      : NORMAL;
                half4 tangentOS     : TANGENT;
                // half4 color         : COLOR;//RGB:平滑法线  A:描边宽度
            };

            struct v2f
            {
                float4 positionCS                   : SV_POSITION;
                float2 uv                           : TEXCOORD0;
                float4 positionWS                   : TEXCOORD1;//w: fogCoord
                half4 tangentWS                     : TEXCOORD2;//w: viewDirWS.x
                half4 biTangentWS                   : TEXCOORD3;//w: viewDirWS.y
                half4 normalWS                      : TEXCOORD4;//w: viewDirWS.z
                
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord              : TEXCOORD5;
                #endif
            };
            

            v2f vert(a2v i)
            {
                v2f o = (v2f)0;

                VertexPositionInputs vertexInput = GetVertexPositionInputs(i.positionOS.xyz);
                o.positionCS = vertexInput.positionCS;
                o.positionWS.xyz = vertexInput.positionWS;
                o.positionWS.w = ComputeFogFactor(vertexInput.positionCS.z);

                o.uv.xy = i.uv;
                o.normalWS.xyz = normalize(mul(i.normalOS, (half3x3)GetWorldToObjectMatrix()));
                

                half sign = i.tangentOS.w * GetOddNegativeScale();
                o.tangentWS.xyz = normalize(mul((half3x3)GetObjectToWorldMatrix(), i.tangentOS.xyz));
                o.biTangentWS.xyz = normalize(cross(o.normalWS.xyz, o.tangentWS.xyz) * sign);

                
                half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                o.tangentWS.w = viewDirWS.x;
                o.biTangentWS.w = viewDirWS.y;
                o.normalWS.w = viewDirWS.z;
                

                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    o.shadowCoord = GetShadowCoord(vertexInput);
                #endif
                
                return o;
            }

            half LinearStep(half minValue, half maxValue, half In)
            {
                return saturate((In-minValue) / (maxValue - minValue));
            }

            half4 frag (v2f i) : SV_Target
            {
            	//================基础数据计算==================
                half4 albedoInnerOutline = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);

                half3 albedo = albedoInnerOutline.xyz * _BaseColor.rgb;
            	
            	half alpha = albedoInnerOutline.w;
            	//half innerOutline = albedoInnerOutline.w;
            	//innerOutline = LinearToSRGB(innerOutline);

            	
            	//==============遮罩图==============
			    half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv.xy);// R:RampID  G:高光大小  B:硬阴影  A:高光强度
			    half4 maskMap = SAMPLE_TEXTURE2D(_MaskMap, sampler_MaskMap, i.uv.xy);// R:自发光  GBA:空

            	half rampID = lightMap.r;
            	half specularIntensity = lightMap.g;
            	half hardShadow = lightMap.b;
            	half emissionMask = lightMap.a;
            	
            	
            	//================法线计算==================
                half4 normal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv.xy);
                half3 normalTS = UnpackNormalScale(normal, _NormalIntensity);
                
                half3 normalWS = TransformTangentToWorld(normalTS, half3x3(i.tangentWS.xyz, i.biTangentWS.xyz, i.normalWS.xyz));
                normalWS = normalize(normalWS);
            	// half3 normalWS = normalize(i.normalWS.xyz);

            	
            	//================光源数据准备==================
                float3 positionWS = i.positionWS.xyz;
                float4 shadowCoord = 0;
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    shadowCoord = i.shadowCoord;
                #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                    shadowCoord = TransformWorldToShadowCoord(positionWS);
                #else
                    shadowCoord = float4(0, 0, 0, 0);
                #endif
            	
                Light mainLight = GetMainLight(shadowCoord);


            	//================向量数据计算==================
                half3 viewDirWS = normalize(half3(i.tangentWS.w, i.biTangentWS.w, i.normalWS.w));
                half3 halfDir = normalize(mainLight.direction + viewDirWS);


                half NdotL = dot(normalWS, mainLight.direction);
                half halfLambert = NdotL * 0.5 + 0.5;
            	NdotL = max(0, NdotL);
            	half NdotV = max(0, dot(normalWS, viewDirWS));
                half NdotH = max(0, dot(normalWS, halfDir));

            	
            	//================阴影计算==================
            	half radiance = NdotL;
            	radiance *= mainLight.shadowAttenuation * mainLight.distanceAttenuation;

            	half2 rampUV = half2(radiance, rampID + _RampYOffset);
			    half3 diffuseColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampUV).rgb;

			    diffuseColor *= albedo;
            	

            	//================硬阴影计算==================
            	half3 hardShadowColor = lerp(_HardShadowColor.rgb, _HardShadowColor.rgb * albedo, _HardShadowColorAlbedoWeight);
				hardShadowColor = lerp(hardShadowColor, 1, hardShadow);
				
				radiance *= hardShadow;
				diffuseColor *= hardShadowColor;

            	
            	//================高光计算==================
            	half specularToonSize = 1 * _SpecularToonSize;
            	half specSize = 1 - (specularToonSize * specularToonSize * specularToonSize * specularToonSize);
		        NdotH = (NdotH - specSize * specSize) / (1 - specSize);
		        half specSmoothness = _SpecularToonSmoothness;
            	
		        half specularTerm = LinearStep(0, specSmoothness, NdotH);
            	specularTerm *= _SpecularIntensity;
            	specularTerm *= specularIntensity;

            	half3 specularColor = lerp(specularTerm.xxx, albedo * specularTerm, _SpecularAlbedoWeight);
            	specularColor *= _SpecularColor.rgb;
            	specularColor *= radiance;


            	//================内描边计算==================
            	//half3 innerLineColor = lerp(_InnerOutlineColor.rgb, _InnerOutlineColor.rgb * albedo, _InnerOutlineColorAlbedoWeight);
				//innerLineColor = lerp(innerLineColor, 1, innerOutline);
            	

            	//================自发光计算==================
            	half3 emission = emissionMask * lerp(_EmissionColor.rgb, albedo * _EmissionColor.rgb, _EmissionColorBlendAlbedo) * _EmissionColorBrightness;

            	
                half3 finalColor = diffuseColor + specularColor;
            	finalColor *= mainLight.color.rgb;
            	//finalColor *= innerLineColor;
            	finalColor += emission;
            	//finalColor += rimColor;


				//================matcap计算==================
				float2 uv_MatcapMask = i.uv.xy * _MatcapMask_ST.xy + _MatcapMask_ST.zw;
				half4 matcapColor = SAMPLE_TEXTURE2D( _MatcapTex,sampler_MatcapTex, (mul( UNITY_MATRIX_V, half4( i.normalWS.xyz , 0.0 ) ).xyz*0.5 + 0.5).xy );
				finalColor.rgb += ( matcapColor * SAMPLE_TEXTURE2D( _MatcapMask,sampler_MatcapMask, uv_MatcapMask ).r * _MatcapIntensity ).rgb * _MatcapColor.rgb;


            	//================边缘光计算==================
            	half rimHalfLambert = dot(-_RimLightDir.xyz, normalWS) * 0.5 + 0.5;
                half RimTerm  = smoothstep(_RimThreshold, _RimThreshold + _RimSoftness, 1 - NdotV);
			    half rimMask = smoothstep(_RimThreshold, _RimThreshold + _RimSoftness, 1 - rimHalfLambert);
				float LightAffect = lerp( 1.0 , rimMask , _RimLightEffect);
            	half3 FresnelColor = _FresnelColor.xyz * lerp(half3(1, 1, 1), albedo.rgb, _RimColorBlend);
				finalColor = lerp( finalColor , lerp( FresnelColor, finalColor + FresnelColor , _AddRamp), ( RimTerm * LightAffect * _useRim));

            	finalColor = MixFog(finalColor, i.positionWS.w);

            	#ifdef GAME_GREY
				finalColor.rgb = dot(finalColor.rgb, unity_ColorSpaceLuminance.rgb);
                #endif
            	
                return half4(finalColor * _ProceduralColor.rgb, alpha * _ProceduralColor.a * _BaseColor.a);
            }
            ENDHLSL
        }

	    Pass
        {
            Name "Ouline"
	        Tags
            {
	            "LightMode" = "SRPDefaultUnlit"
            }
	        Blend[_SrcBlend][_DstBlend]
            ZWrite [_ZWrite]
            ZTest [_ZTest]
	        //正面剔除
    		//Cull Front
    		//背面剔除
    		Cull Back
            Offset [_Offset_Factor],[_Offset_Units]

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastes
            #pragma multi_compile_instancing
            #pragma multi_compile_local_fragment _ _DyeColor

            //自定义预处理或宏
			#pragma multi_compile_local_vertex VERTEXNORMAL VERTEXCOLOR SMOOTHNORMALUV2 SMOOTHNORMALUV3

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            
			float3 OctahedronToUnitVector1_g10( float2 oct )
			{
				    float3  unitVec = float3(oct.x, oct.y, 1.0f - abs(oct.x) -  abs(oct.y));
				    float t = max( -unitVec.z, 0.0f );
				    unitVec.x += unitVec.x >= 0.0f ? -t : t;
				    unitVec.y += unitVec.y >= 0.0f ? -t : t;
				    return normalize(unitVec);
			}
            
            struct appdata
            {
                float4 vertex	 : POSITION;
				half4 color		 : COLOR;
            	float3 normal	 : NORMAL;
            	float4 tangent	 : TANGENT;
            	float4 uv		 : TEXCOORD0;
				float4 uv1		 : TEXCOORD1;
				float4 uv2		 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex		: SV_POSITION;
            	half4 color			: COLOR;
            	float2 uv			: TEXCOORD0;
				float4 worldPos		: TEXCOORD1;
				float4 worldNormal  : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            v2f vert ( appdata v  )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
            	
				float3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
				float3 worldNormal = TransformObjectToWorldNormal(v.normal);
				float3 worldBitangent = cross( worldNormal, worldTangent ) * v.tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3x3 tangentToWorldFast = float3x3(worldTangent.x,worldBitangent.x,worldNormal.x,worldTangent.y,worldBitangent.y,worldNormal.y,worldTangent.z,worldBitangent.z,worldNormal.z);
				
            	//UV1转平滑法线
            	float3 localOctahedronToUnitVector1 = OctahedronToUnitVector1_g10( v.uv1.xy );
            	float3 tangentTobjectDir1 = normalize( mul( GetWorldToObjectMatrix(), float4( mul( tangentToWorldFast, localOctahedronToUnitVector1 ), 0 ) ).xyz );

            	//UV2转平滑法线
				float3 localOctahedronToUnitVector2 = OctahedronToUnitVector1_g10( v.uv2.xy );
				float3 tangentTobjectDir2 = normalize( mul( GetWorldToObjectMatrix(), float4( mul( tangentToWorldFast, localOctahedronToUnitVector2 ), 0 ) ).xyz );

            	#if defined(VERTEXNORMAL)
				float4 staticSwitch28_g10 = float4( v.normal , 0.0 );
				#elif defined(VERTEXCOLOR)
				float4 staticSwitch28_g10 = v.color;
				#elif defined(SMOOTHNORMALUV2)
				float4 staticSwitch28_g10 = float4( tangentTobjectDir1 , 0.0 );
				#elif defined(SMOOTHNORMALUV3)
				float4 staticSwitch28_g10 = float4( tangentTobjectDir2 , 0.0 );
				#else
				float4 staticSwitch28_g10 = float4( v.normal , 0.0 );
				#endif
				
				float3 worldPos = TransformObjectToWorld( (v.vertex).xyz );
				o.worldPos.xyz = worldPos;
				o.worldNormal.xyz = worldNormal;
				//setting value to unused interpolator channels and avoid initialization warnings
				o.worldPos.w = 0;
				o.worldNormal.w = 0;
            	
				//自定义算法板块
				v.vertex.xyz += ( staticSwitch28_g10 * 0.01 * _OutlineWidth * v.color.a * _Scale).rgb;
				o.vertex = TransformObjectToHClip(v.vertex.xyz);

            	//背面剔除
            	#ifdef UNITY_REVERSED_Z //DX
            	half Posw = o.vertex.w / (o.vertex.w - _ScaleDepth * 0.01 );
                Posw = Posw * (o.vertex.z - _ScaleDepth * 0.01 );
                o.vertex.z = Posw;
            	#else //OpenGL
            	half Posw = o.vertex.w / (o.vertex.w + _ScaleDepth * 0.01 );
                Posw = Posw * (o.vertex.z + _ScaleDepth * 0.01 );
                o.vertex.z = Posw;
            	#endif
            	
				o.color = v.color;
            	o.uv = v.uv.xy;
				return o;
			}

			half4 frag ( v2f i  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( i );
				half4 col;
				
				//.....................................背面剔除.......................................
                half4 albedoInnerOutline = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
            	half alpha = albedoInnerOutline.w;
				
				float3 worldViewDir = normalize( _WorldSpaceCameraPos.xyz - i.worldPos.xyz );
				float3 worldNormal = normalize( i.worldNormal.xyz );
				
				float NdotV = dot( worldNormal, worldViewDir );
				NdotV = 0.0 + 1.0 * saturate( pow( saturate(1.0 - NdotV), _FresnelPower ) );
				
				float NdotL = dot( worldNormal , _MainLightPosition.xyz ) * 0.5 + 0.5;
				NdotL = lerp( 1.0 , NdotL , _LightEffect);
				
				float Noise = lerp( 1.0 , SAMPLE_TEXTURE2D( _Noise, sampler_Noise, i.uv.xy * _Noise_ST.xy + _Noise_ST.zw * _TimeParameters.x).r , _NoiseItensity);
				
				clip( frac( NdotV * _FresnelStength ) * Noise * NdotL  - _AlpahTreshold );
				//...................................................................................

				
				//..........................................正面剔除...........................................
				float NoiseClip = clamp( lerp( 1.0 , SAMPLE_TEXTURE2D( _Noise, sampler_Noise, i.uv.xy * _Noise_ST.xy + _Noise_ST.zw * _TimeParameters.x).r , _NoiseItensity) , 0.0 , 1.0);
				//clip( NoiseClip - _Threshold);
				//............................................................................................

				
				//颜色需要染色
				#if _DyeColor
				    float index = 0.25;
					half4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, i.uv.xy);
					half ID = lerp(i.color.r, lightMap.g, _OutlineUseRampID);
				    float idx =clamp(round(ID * 10),0,9);
				    float idy;
				    if ( idx > 6)
				    {
				        idy = 3;
				    }
				    else if( idx <= 6 && idx >3)
				        {
				        idy = 2; 
				        }
				    else if( idx <= 3)
				    {
				        idy = 1;
				    }
				    idx = ceil( (idx-0.1) % 3 );
				    half4 DyeColor = SAMPLE_TEXTURE2D(_DeyTex,sampler_DeyTex,float2(idx * index, idy * index));
				    col.xyz = DyeColor;//存输出顶点色
			    #else
					col.xyz = _OutlineColor.rgb;
			    #endif
				
				col.xyz *= _ProceduralColor.rgb * _BaseColor.rgb * _BaseColor.a;
				col.w = alpha * _ProceduralColor.a * _BaseColor.a;
				return col;
			}
            ENDHLSL
        }
    	
		Pass
        {
	        Name "Character_Cartoon_ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 3.0
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			float3 _LightDirection;
			float4 _ShadowBias;

			struct appdata
			{
			    float3 positionOS : POSITION;
			    half3 normalOS : NORMAL;
			    float2 uv : TEXCOORD0;
			};

			struct v2f
			{
			    float2 uv : TEXCOORD0;
			    float4 positionCS : SV_POSITION;
			};

			float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
			{
			    float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
			    float scale = invNdotL * _ShadowBias.y;

			    positionWS = lightDirection * _ShadowBias.xxx + positionWS;
			    positionWS = normalWS * scale.xxx + positionWS;
			    return positionWS;
			}

			float4 GetShadowPositionHClip(appdata input)
			{
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

			v2f vert(appdata v)
			{
			    v2f o;
			    o.positionCS = GetShadowPositionHClip(v);
			    o.uv = v.uv;

			    return o;
			}

			half4 frag(v2f i) : SV_TARGET
			{
			    half alpha = 0;

			    return 0;
			}
            ENDHLSL
        }
    }
	FallBack "Hidden/Universal Render Pipeline/FallbackError" 
    CustomEditor "CustomShaderEditor.CustomShaderGUI" 
}
