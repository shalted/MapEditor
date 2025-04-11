Shader "ShiYue/Grass/SimpleInteractiveBlendGrass" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" { }

        [Header(Color)]
        _TopColor ("Top Color", Color) = (0.5, 0.5, 0.5, 1)
        _TopWeight ("UseTerrainOrTopColor", Range(0, 1)) = 0.8
        _BottomColor ("Bottom Color", Color) = (0.2, 0.5, 0.15, 1)
        _BottomWeight ("UseTerrainOrBottomColor", Range(0, 1)) = 0.4
        [HDR]_EmissionColor ("自发光颜色",Color) = (0,0,0,0)
        _DiffuseNormalShift ("漫反射法线偏移", Range(0, 1)) = 0


        [Header(Wind)]
        [NoScaleOffset] _WindMap ("Wind map", 2D) = "black" { }
        _WindSpeed ("Speed", Range(0.0, 10.0)) = 3.0
        _WindDirection ("Direction", vector) = (1, 0, 0, 0)
        _WindGustStrength ("Gusting strength", Range(0.0, 2)) = 0.5
        _WindGustFreq ("Gusting frequency", Range(0.0, 10.0)) = 2
        _WindBack ("回摆", Range(0, 1)) = 0

        [Header(Cloud)]
        _CloudGustTint ("Cloud Color Tint", Color) = (1, 1, 1, 1)

        [Header(Bend)]
        _BendPushStrength ("Push Strength", Range(0.0, 1.0)) = 1.0
        _BendFlattenStrength ("Flatten Strength", Range(0.0, 1.0)) = 1.0
        _PerspectiveCorrection ("Perspective Correction", Range(0.0, 1.0)) = 0.0

        [HideInInspector]_grassHeight ("_grassHeight", Float) = 1
        _CloudMap ("云阴影", 2D) = "black"{}
        _CloudMove ("云流动速度", Vector) = (0,0,0,0)
    }

    SubShader {
        Tags { "RenderType" = "Opaque" "IgnoreProjector" = "True" }
        Pass {
            Name "ForwardLit"
            Tags { "LightMode" = "ForwardBase" }
            Cull Off

            CGPROGRAM

            #pragma target 3.0
            #pragma prefer_hlslcc gles
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma multi_compile _ _BEND_ON
            
            //#pragma multi_compile_fwdbase

            #include "UnityCg.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityShadowLibrary.cginc"
            #include "Libraries/Input.hlsl"
            #include "Libraries/Common.hlsl"
            #include "Libraries/Wind.hlsl"
            #include "Libraries/Bending.hlsl"
            #include "../../../Scene3D/Fog/ModelComputeFogLibrary.cginc"
            sampler2D _MainTex;//主贴图用于吸色遮罩     
            //sampler2D _BendMap;
            half4 _MainTex_ST;
            half4 _TopColor;
            half _TopWeight;
            half3 _EmissionColor;

            half _DiffuseNormalShift;
            half _SpecularNormalShift;

            half4 _BottomColor;
            half _BottomWeight;

            half4 _WindDirection;
            half _WindSpeed;
            half _WindGustStrength;
            half _WindGustFreq;

            half _BendPushStrength;
            half _BendFlattenStrength;
            half _PerspectiveCorrection;
            half _grassHeight;

            float3 _MainLightPosWS;
            half3 _MainLightColor;


            //float4 _BendData;
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(half4, _giColor)
            UNITY_DEFINE_INSTANCED_PROP(half4, _tNormal)
            //UNITY_DEFINE_INSTANCED_PROP(half, _bakedShadow)
            //UNITY_DEFINE_INSTANCED_PROP(float4, _BendData)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert(a2v v)
            {
                v2f o = (v2f)0;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o); // necessary only if you want to access instanced properties in the fragment Shader.
               
                half4 bakedGI = UNITY_ACCESS_INSTANCED_PROP(Props, _giColor);
                //half mask = UNITY_ACCESS_INSTANCED_PROP(Props, _bakedShadow);

                VertexOutput data = GetVertexData(v, _grassHeight);

                float3 wPos = data.positionWS; 
                float3 pivotWS = data.pivotWS;

                WindSettings wind = PopulateWindSettings(0, _WindSpeed, _WindDirection, AO_MASK, _WindGustStrength, _WindGustFreq);
                //float4 windVec = GetWindOffset(wPos, pivotWS, wind);
                float3 windVec = GetSimpleWind(wPos, wind, v.uv.y);  
                wPos.xyz = windVec.xyz;
                
                #ifdef _BEND_ON
                    BendSettings bending = PopulateBendSettings(BEND_MASK, _BendPushStrength, _BendFlattenStrength, _PerspectiveCorrection);              
                    //float4 bendVec = GetBendOffset(wPos, pivotWS);
                    float4 bendVec = GetSimpleBendOffset(wPos, pivotWS, v.uv.y);	                              
                    wPos.xyz = lerp(windVec.xyz, bendVec.xyz, bendVec.a);
                #endif

                o.normalWS = data.normalWS;
                o.pos = UnityWorldToClipPos(wPos);
                v.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.positionWS = data.positionWS;


                //计算阴影空间中的shadowCoord
                //需要提取阴影宏中的方法自己计算，给坐标w补上1
                //TRANSFER_SHADOW(o);
                o._ShadowCoord = mul(unity_WorldToShadow[0], float4(wPos, 1));
                o._ShadowCoord = max(0.0001h,o._ShadowCoord);

                half3 weight = tex2Dlod(_MainTex, float4(v.uv,0,0));
                half4 bottomCol = lerp(data.color, _BottomColor, _BottomWeight);
                half4 topCol = lerp(data.color, _TopColor, _TopWeight);
                half3 albedo = lerp(bottomCol, topCol, weight.r).rgb + lerp(0,_EmissionColor,weight.g);
                o.color = albedo;

                //#ifdef LIGHTMAP_ON
                    //bakedGI.rgb = DecodeLightmap(bakedGI);
                // #if defined(UNITY_COLORSPACE_GAMMA)
                //     half4 decodeInstructions = half4(5,1,0,0);
                // #else
                //     half4 decodeInstructions = half4(34,2.2,0,0);
                // #endif
                //
                // #if defined(UNITY_LIGHTMAP_DLDR_ENCODING)
                //     bakedGI.rgb = DecodeLightmapDoubleLDR(bakedGI, decodeInstructions);
                // #elif defined(UNITY_LIGHTMAP_RGBM_ENCODING)
                //     bakedGI.rgb = DecodeLightmapRGBM(bakedGI, decodeInstructions);
                // #endif
                //#endif

                //o.vertexSH = half4(bakedGI.rgb,data.color.a);
                return o;
            }

            half4 frag(v2f v) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID (v);
                //return half4(v.color,1);
                // half4 normal = UNITY_ACCESS_INSTANCED_PROP(Props, _tNormal);
                // normal = normal*2-1;
                // //return half4(normal.xyz,1);
                // half3 DiffuseNormal = lerp(normal.xyz, v.normalWS, _DiffuseNormalShift);
                // half3 worldLight = normalize(_MainLightPosWS.xyz);
                // half shadow = SHADOW_ATTENUATION(v) * v.vertexSH.a;
                // half3 diffuse = 1  * 1*1; 

                //return half4(diffuse,1);
                half3 color = v.color;
                ComputeModelFog( v.pos.z, v.positionWS.y, color);
                ComputeCloudShadow(v.positionWS, color.rgb);
                return half4(color, 1.0h);
            }
            ENDCG

        }

        //Pass {
        //    Tags { "LightMode" = "ForwardAdd" }
        //    Blend One One
        //    Cull Off
        //    CGPROGRAM

        //    #pragma multi_compile_fwdadd
        //    // Use the line below to add shadows for point and spot lights
        //    //			#pragma multi_compile_fwdadd_fullshadows
            
        //    #pragma vertex vert
        //    #pragma fragment frag
            
        //    #include "Lighting.cginc"
        //    #include "AutoLight.cginc"
        //    #include "Libraries/Input.hlsl"
        //    #include "Libraries/Common.hlsl"
        //    #include "Libraries/Wind.hlsl"
        //    #include "Libraries/Bending.hlsl"

        //    sampler2D _MainTex;
        //    float4 _MainTex_ST;
        //    half4 _TopColor;
        //    half _TopWeight;
        //    half _DiffuseNormalShift;

        //    half4 _BottomColor;
        //    half _BottomWeight;

        //    float4 _WindDirection;
        //    float _WindSpeed;
        //    float _WindGustStrength;
        //    float _WindGustFreq;

        //    float4 _CloudGustTint;

        //    float _BendPushStrength;
        //    float _BendFlattenStrength;
        //    float _PerspectiveCorrection;
        //    float _grassHeight;
            
        //    v2f vert(a2v v) {
        //        v2f o = (v2f)0;

        //        UNITY_SETUP_INSTANCE_ID(v);
        //        UNITY_TRANSFER_INSTANCE_ID(v, o); // necessary only if you want to access instanced properties in the fragment Shader.

        //        VertexOutput data = GetVertexData(v, _grassHeight);

        //        float3 wPos = data.positionWS;
        //        float3 pivotWS = data.pivotWS;
                
        //        WindSettings wind = PopulateWindSettings(0, _WindSpeed, _WindDirection, AO_MASK, _WindGustStrength, _WindGustFreq);
        //        BendSettings bending = PopulateBendSettings(BEND_MASK, _BendPushStrength, _BendFlattenStrength, _PerspectiveCorrection);
                
        //        float4 windVec = GetWindOffset(wPos, pivotWS, wind);
        //        float4 bendVec = GetBendOffset(wPos, pivotWS, bending);
                
        //        wPos.xyz = windVec;//lerp(windVec.xyz, bendVec.xyz, bendVec.a);
                
        //        o.normalWS = data.normalWS;
        //        o.pos = UnityWorldToClipPos(wPos);
        //        o.color = data.color;
        //        o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
        //        o.positionOS = data.positionOS;
        //        o.positionWS = wPos;
                
        //        return o;
        //    }
            
        //    fixed4 frag(v2f i, half facing : VFACE) : SV_Target {
        //        float3 worldPos = i.positionWS;
        //        fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                
        //        half weight = tex2D(_MainTex, i.uv).r;
        //        half4 bottomCol = lerp(i.color, _BottomColor, _BottomWeight);
        //        half4 topCol = lerp(i.color, _TopColor, _TopWeight);
        //        half3 albedo = lerp(bottomCol, topCol, weight).rgb;

        //        i.normalWS *= facing;
        //        float3 DiffuseNormal = lerp(float3(0, 1, 0), i.normalWS, _DiffuseNormalShift);
        //        fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(DiffuseNormal, lightDir));
                
        //        UNITY_LIGHT_ATTENUATION(atten, i, worldPos);
        //        return fixed4(diffuse * atten, 1.0);
        //    }
            
        //    ENDCG

        //}

        //Pass
        //{
        //    Name "ShadowCaster"
        //    Tags { "LightMode" = "ShadowCaster" }

        //    ZWrite On ZTest LEqual Cull Off

        //    CGPROGRAM
        //    #pragma vertex vert
        //    #pragma fragment frag
        //    #pragma target 3.0
        //    #pragma multi_compile_shadowcaster
        //    #include "UnityCG.cginc"

        //    struct v2f {
        //        V2F_SHADOW_CASTER;
        //        UNITY_VERTEX_OUTPUT_STEREO
        //    };

        //    v2f vert( appdata_base v )
        //    {
        //        v2f o;
        //        UNITY_SETUP_INSTANCE_ID(v);
        //        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        //        TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
        //        return o;
        //    }

        //    float4 frag( v2f i ) : SV_Target
        //    {
        //        SHADOW_CASTER_FRAGMENT(i)
        //    }
        //    ENDCG
        //}
    }
    Fallback "Unlit"
    //FallBack "Hidden/Universal Render Pipeline/FallbackError"

}