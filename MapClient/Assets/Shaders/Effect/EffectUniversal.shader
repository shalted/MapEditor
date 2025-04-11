//石器 v1.0 2023.7.21
Shader "XianXia/Effect/EffectUniversal"
{
    Properties
    {
        //基础设置
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendModeSrc("混合模式Src",Int) = 5
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendModeDst("混合模式Dst",Int) = 10
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("剔除模式",Int) = 0
        // [Enum(Off,0,On,1)]_ZWrite("深度写入",float) = 0
[Enum(UnityEngine.Rendering.CompareFunction)]_ZTest("深度测试",float) = 2
        [HideInInspector]_BlendTemp("BlendTemp",float) = 0
        [Toggle] _UseUV2("是否使用UV2",float) = 0
        //主纹理
        [HDR]_MainColor ("主纹理颜色", Color) = (1,1,1,1)
        _MainTex ("主纹理贴图", 2D) = "white" {}
        _MainTex_PannerSpeedU("MainTex_PannerSpeedU",float) = 0
        _MainTex_PannerSpeedV("MainTex_PannerSpeedV",float) = 0
        [Enum(A,0,R,1)]_MainTexChannel("通道选择",Int) = 0
        [Toggle]_MainCustom("是否主纹理自定义曲线",Int) = 0

        [Toggle(_MainLight_ON)]_MainLightON("是否使用主纹理光照",Int) = 0
		_TexValue("亮度", Range(0, 3.0)) = 1
		_TexSaturation("饱和度", Range(0, 3.0)) = 1
		_TexContrast("对比度", Range(0, 3.0)) = 1

		[Space(10)]
		[HDR]_AmbientLight("环境补光", Color) = (0.4, 0.4, 0.4, 1)
		[HDR]_LightColor1("灯光颜色", Color) = (0.7, 0.7, 0.7, 1)
		_LightWorldDir("灯光方向xyz", Vector) = (1, 0, 0, 0)



        //副贴图
        [Toggle(_Sub_ON)]_Sub_ON("是否使用副纹理",Int) = 0
        [HDR]_SubColor ("副纹理颜色", Color) = (1,1,1,1)
        _SubTex ("副纹理贴图", 2D) = "black" {}
        [Enum(Lerp,0,Multiply,1)] _SubBlend("混合模式",float) = 0
        [Enum(Alpha,0,R,1)]_SubLerp("副纹理插值",Int) = 1
        [Toggle]_SubUV2("SubUV2",float) = 0
        _SubTex_PannerSpeedU("SubTex_PannerSpeedU",float) = 0
        _SubTex_PannerSpeedV("SubTex_PannerSpeedV",float) = 0

        //边缘光
        [Toggle(_Fresnel_ON)] _Fresnel("是否使用菲涅尔",float) = 0
        [HDR]_FresnelColor ("边缘光颜色",Color) = (0,0,0,0)
        _FresnelPower("边缘光宽度",float) = 5
        [Toggle]_OneMinusFresnel("反向菲涅尔",int) = 0
        //遮罩
        [Toggle(_MASK_ON)]_Mask_ON("Mask_ON",int) = 0
        _MaskTex("MaskTex",2D) = "white"{}
        [Toggle]_MaskUV2("MaskUV2",float) = 0
        [Enum(Alpha,0,R,1)]_MaskTexAlpha("MaskTexAlpha",Int) = 1
        _MaskTex_PannerSpeedU("Mask_PannerSpeedU",float) = 0
        _MaskTex_PannerSpeedV("Mask_PannerSpeedV",float) = 0
        [Toggle]_MaskCustom("是否使用遮罩自定义曲线",Int) = 0
        //扰动
        [Toggle(_NOISE_ON)]_NOISE_ON("Noise_On",int) = 0
        _NoiseTex("NoiseTex",2D) = "white"{}
        [Toggle]_NoiseUV2("NoiseUV2",float) = 0
        _NoiseIntensity("NoiseIntensity",float) = 0.01
        _NoiseTex_PannerSpeedU("NoiseTex_PannerSpeedU",float) = 0
        _NoiseTex_PannerSpeedV("NoiseTex_PannerSpeedV",float) = 0
        [Toggle]_NoiseCustom("是否使用扰动自定义曲线",Int) = 0
        //溶解
        [Toggle(_DISSOLVE_SOFT)]_DissolveMode("DissolveMode",int) = 0
        _DissolveTex ("Dissolve_Tex", 2D) = "white" {}
        [Toggle]_DissolveUV2("DissolveUV2",float) = 0
        [Enum(Alpha,0,R,1)]_DissolveTexAlpha("DissolveTexAlpha",Int) = 1
        _Dissolve_Amount ("Dissolve Amount", Range(0, 1)) = 0
        _DissolveTex_PannerSpeedU("DissolveTex_PannerSpeedU",float) = 0
        _DissolveTex_PannerSpeedV("DissolveTex_PannerSpeedV",float) = 0
        [HDR]_Dissolve_color ("Dissolve Color", Color) = (0.5,0.5,0.5,1)
        _OutlineIntensity ("Outline Intensity", Range(0,0.5) ) = 0.1
        _BlendIntensity ("Blend Intensity", Range(0,0.5) ) = 0.1
        [Toggle]_DissolveCustom("是否使用溶解自定义曲线",Int) = 0

		[Space(30)] _Stencil ("Stencil ID", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil Comparison", Float) = 4
		[HideInInspector][HDR]_ProceduralColor ("Procedural Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags
        {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        Pass
        {
            // Tags {"LightMode"="ForwardBase"} //关闭光照
            Stencil {
				Ref [_Stencil]
				Comp [_StencilComp]
			}
            Cull  [_CullMode]
            Blend [_BlendModeSrc] [_BlendModeDst]
            ZWrite Off
                   ZTest [_ZTest]


            CGPROGRAM
            #pragma multi_compile_local_fragment     _ _MASK_ON   //遮罩宏
            #pragma multi_compile_local_fragment     _ _NOISE_ON  //扰动宏
            #pragma multi_compile_local_fragment     _ _DISSOLVE_SOFT   //溶解宏
            #pragma multi_compile_local_fragment     _ _Sub_ON //副纹理宏
            #pragma multi_compile_local  _ _Fresnel_ON  //边缘光宏
            #pragma multi_compile_local_fragment    _ _MainLight_ON  //模拟光照宏 

            //shader_feature_local
            //multi_compile_local
            //multi_compile_local_fragment


			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            uniform sampler2D _MainTex;
            uniform sampler2D _MaskTex;
            uniform sampler2D _NoiseTex;
            uniform sampler2D _DissolveTex;
            uniform sampler2D _SubTex;
            uniform half _UseUV2;



            //副纹理
            uniform half4 _SubColor;
            uniform half4 _SubTex_ST;
            uniform half _SubLerp;
            uniform half _SubTex_PannerSpeedU;
            uniform half _SubTex_PannerSpeedV;
            uniform half _SubUV2;
            uniform half _SubBlend;

            //主纹理 
            uniform half4 _MainTex_ST;
            uniform half4 _MainColor;
            uniform half _MainTex_PannerSpeedU;
            uniform half _MainTex_PannerSpeedV;
            uniform half _MainCustom;
            uniform half _MainTexChannel;

            uniform half _TexValue;
            uniform half _TexSaturation;
            uniform half _TexContrast;
            uniform half4 _AmbientLight;
            uniform half4 _LightColor1;
            uniform half4 _LightWorldDir;
 

            //边缘光
            uniform half4 _FresnelColor;
            uniform half _FresnelPower;
            uniform half _OneMinusFresnel;
            //遮罩
            uniform half4 _MaskTex_ST;
            uniform half _MaskTex_PannerSpeedU;
            uniform half _MaskTex_PannerSpeedV;
            uniform int _MaskTexAlpha;
            uniform half _MaskCustom;
            uniform half _MaskUV2;

            //扰动
            uniform half _NoiseIntensity;
            uniform half4 _NoiseTex_ST;
            uniform half _NoiseTex_PannerSpeedU;
            uniform half _NoiseTex_PannerSpeedV;
            uniform half _NoiseCustom;
            uniform half _NoiseUV2;

            //溶解
            uniform int _DissolveMode;
            uniform half4 _DissolveTex_ST;
            uniform int _DissolveTexAlpha;
            uniform half _OutlineIntensity;
            uniform half _DissolveTex_PannerSpeedU;
            uniform half _DissolveTex_PannerSpeedV;
            uniform half _Dissolve_Amount;
            uniform half4 _Dissolve_color;
            uniform half _BlendIntensity;
            uniform half _DissolveUV2;
            uniform half _DissolveCustom;

			fixed4 _ProceduralColor;




            struct appdata
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 vertexColor : COLOR;
                float3 vertexNormal : NORMAL;
                float4 customData1:TEXCOORD1;
                float4 customData2:TEXCOORD2;
                float2 uv2: TEXCOORD3;
                
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 customData1:TEXCOORD1;
                float4 customData2:TEXCOORD2;

                #ifdef _Fresnel_ON
                float3 worldPos : TEXCOORD3;
                #endif

                float4 vertexColor : COLOR;
                float3 worldNormal : NORMAL;

                float2 uiWorldPos : TEXCOORD4;



            };



			v2f vert ( appdata v )
            {

                v2f o;
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.customData1 = v.customData1;
                o.customData2 = v.customData2;

                o.uv = float4(v.uv,v.uv2);




                o.vertexColor = v.vertexColor;
                o.uiWorldPos = mul(unity_ObjectToWorld, v.positionOS).xy;

                // float3 positionWS = mul(unity_ObjectToWorld,v.positionOS);
                // float4 positionCS = UnityObjectToClipPos(float4(v.positionOS, 1));
                float4 wp = mul(unity_ObjectToWorld, float4(v.positionOS, 1));
                float4 positionCS = mul(UNITY_MATRIX_VP, wp);
                o.pos = positionCS;

                #ifdef _Fresnel_ON
                {
                    o.worldNormal = UnityObjectToWorldNormal(v.vertexNormal);
                    o.worldPos = wp.xyz;
                }
                #endif
                return o;
            }




            fixed4 frag (v2f i ) : SV_Target
            {
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);


                float time = fmod(_Time.y,2e5);




                float2 uv = lerp(i.uv.xy,i.uv.zw,_UseUV2);
                float2 mainuv = uv;
                float2 dissolveUV = lerp(i.uv.xy,i.uv.zw,_DissolveUV2);
                dissolveUV = dissolveUV *_DissolveTex_ST.xy + _DissolveTex_ST.zw;


                mainuv += time * float2(_MainTex_PannerSpeedU,_MainTex_PannerSpeedV) *  (1- _MainCustom);
                mainuv += i.customData1.xy * _MainCustom ;


                //扰动
                #ifdef _NOISE_ON
                {
                    float2 noiseuv = lerp(i.uv.xy,i.uv.zw,_NoiseUV2);
                    noiseuv = noiseuv * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
                    noiseuv += time * float2(_NoiseTex_PannerSpeedU,_NoiseTex_PannerSpeedV);
                    half4 NoiseTex = tex2D(_NoiseTex,noiseuv) ;
                    NoiseTex = (NoiseTex * 2 - 1 ) * lerp(_NoiseIntensity,i.customData2.x,_NoiseCustom);
                    mainuv += NoiseTex.xy;
                    dissolveUV += NoiseTex.xy;
                }
                #endif

                //主纹理


                float2 colMainTex_UV = mainuv * _MainTex_ST.xy + _MainTex_ST.zw;
                half4 colMainTex = tex2D(_MainTex,colMainTex_UV);
                colMainTex.a = lerp(colMainTex.a,colMainTex.r,_MainTexChannel);



                //光照
                 #ifdef _MainLight_ON
                {
                half lim = dot(i.worldNormal,_LightWorldDir) ;
                float4 lightcolor = lerp(_AmbientLight,_LightColor1,lim);
                colMainTex *= lightcolor ;
                half grey = dot(colMainTex.rgb,unity_ColorSpaceLuminance.rgb);
                colMainTex = lerp(grey,colMainTex  * _TexValue, _TexSaturation );
                colMainTex = lerp(float4(0.5, 0.5, 0.5,1), colMainTex, _TexContrast);
                colMainTex.a = 1;
                }
                #endif
                


                half3 col = colMainTex.rgb * _MainColor.rgb;
                half alpha = saturate(colMainTex.a * _MainColor.a);
                half4 finalColor = half4(col,alpha);

                #ifdef _Sub_ON
                {
                    float2 Subuv = lerp(i.uv.xy,i.uv.zw,_SubUV2);
                    Subuv = Subuv * _SubTex_ST.xy + _SubTex_ST.zw;
                    Subuv += time * float2(_SubTex_PannerSpeedU,_SubTex_PannerSpeedV);

                    float2 colSub_uv = Subuv;
                    half4 colSubTex = tex2D(_SubTex,colSub_uv);
                    half3 subcol = colSubTex.rgb * _SubColor.rgb;
                    half sublerp = lerp(colSubTex.a,colSubTex.r,_SubLerp);

                    half3 subMul = finalColor.rgb * subcol;
                    half3 subBlendLerp = lerp(finalColor.rgb, subcol * finalColor.a,sublerp);
                    finalColor.rgb = lerp(subBlendLerp, subMul,_SubBlend);
                }
                #endif

                #ifdef _Fresnel_ON
                {
                    //边缘光 19math
                    float3 worldPos = i.worldPos;
                    float3 worldViewDir= normalize(_WorldSpaceCameraPos.xyz - worldPos);
                    float3 worldNormal = i.worldNormal;
                    half ndotv = dot(worldNormal,worldViewDir);
                    half fresnel = saturate(pow(max(1.0 - ndotv,0.0001),_FresnelPower)); 
                    half OneMinusFresnel = saturate(1 - fresnel);
                    finalColor.xyz += fresnel * _FresnelColor.xyz * (1 - _OneMinusFresnel);
                    finalColor.xyz = lerp(finalColor.xyz,finalColor.xyz * OneMinusFresnel,_OneMinusFresnel);
                    //finalColor.w *= fresnel;
                    finalColor.w = lerp(saturate(finalColor.w + fresnel),saturate(finalColor.w + OneMinusFresnel),_OneMinusFresnel );
                }
                #endif


                #ifdef _DISSOLVE_SOFT
                {


                    
                    dissolveUV  +=  time * float2(_DissolveTex_PannerSpeedU,_DissolveTex_PannerSpeedV);

                    half DissolveAmount = _Dissolve_Amount + i.customData2.y * _DissolveCustom;
                    DissolveAmount *= 1.05 + _OutlineIntensity;
                    half4 colDissovleTex = tex2D(_DissolveTex,dissolveUV);


                    half tongdao  = lerp (colDissovleTex.a,colDissovleTex.r,_DissolveTexAlpha);
                    _BlendIntensity = _BlendIntensity + 0.0001;
                    half slope = 1 / (_BlendIntensity);
                    half range = _BlendIntensity + lerp(0, 1 - _BlendIntensity - _OutlineIntensity,tongdao) - DissolveAmount;
                    half alphaRight = saturate((range + _OutlineIntensity) * slope);
                    half alphaLeft = saturate(range * slope);
                    half edgeAlpha = 1 - alphaLeft;

                    half3 emissive = alphaLeft * i.vertexColor.rgb  * finalColor.rgb;


                #if(_BlendTemp ==0)
                    half3 finalColor_rgb = emissive + edgeAlpha * _Dissolve_color.rgb ; // BLEND
                    #else
                     half3 finalColor_rgb = emissive + edgeAlpha * _Dissolve_color.rgb  *finalColor.r ; // ADD
                #endif

                    
                    finalColor = half4 (finalColor_rgb,saturate(alphaRight * finalColor.a *_Dissolve_color.a));

                }
                #endif

                //遮罩
                #ifdef _MASK_ON
                    {
                        float2 uv_mask = lerp(i.uv.xy,i.uv.zw,_MaskUV2);
                        uv_mask = uv_mask * _MaskTex_ST.xy + _MaskTex_ST.zw;
                        uv_mask += time * float2(_MaskTex_PannerSpeedU,_MaskTex_PannerSpeedV)*  (1- _MaskCustom) ;
                        uv_mask += i.customData1.zw * _MaskCustom ;

                        float2 colMask_uv = uv_mask;
                        half4 maskTex = tex2D(_MaskTex,colMask_uv);
                        half maskChannel = lerp(maskTex.a,maskTex.r,_MaskTexAlpha);
                        finalColor.a *= maskChannel;
                    }
                #endif

                finalColor *= i.vertexColor;

                #ifdef UNITY_UI_ALPHACLIP
                {
                    clip (finalColor.a - 0.001h);
                }

                #endif

                #if(_BlendTemp ==0)
                    finalColor.a = finalColor.a; // BLEND
                    #else
                    finalColor.a*= finalColor.r; // ADD
                #endif

                return half4(finalColor.rgb, finalColor.a) * _ProceduralColor;
            }
            ENDCG
        }
    }
    CustomEditor "EffectUniversal_GUI"
}
