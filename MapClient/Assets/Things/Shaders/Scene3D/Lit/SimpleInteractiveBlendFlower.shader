Shader "ShiYue/Grass/SimpleInteractiveBlendFlower" {
    Properties {
//        _MainTex ("Base (RGB)", 2D) = "white" { }
//        [HDR]_Color ("Color", Color) = (1,1,1,1)
        [Header(Base)]
		_MainTexValue("亮度", Range(0, 3.0)) = 1
		_MainTexSaturation("饱和度", Range(0, 2.0)) = 1
		_MainTexContrast("对比度", Range(0, 2.0)) = 1
        _MainTex("主贴图", 2D) = "white" {}
        [HDR]_Color("主贴图颜色", Color) = (1, 1, 1, 1)
        _SmoothnessScale("光滑度缩放", Range(0, 1.0)) = 0.7
		_MetallicScale("金属度缩放", Range(0, 2.0)) = 0
		_AmbientOcclusionStrength("环境光遮蔽强度", Range(0, 1)) = 0
		_AmbientSpecularScale("环境高光反射强度", Range(0, 2.0)) = 0.5
        
        [Header(Wind)]
        [NoScaleOffset] _WindMap ("Wind map", 2D) = "black" { }
        _WindSpeed ("Speed", Range(0.0, 10.0)) = 3.0
        _WindDirection ("Direction", vector) = (1, 0, 0, 0)
        [Toggle]_WindControl ("Move Control", Float) = 0
        _WindGustStrength ("Gusting strength", Range(0.0, 2)) = 0.5
        _WindGustFreq ("Gusting frequency", Range(0.0, 10.0)) = 2
        _WindBack ("回摆", Range(0, 1)) = 0
        _CloudMap ("云阴影", 2D) = "black"{}
        _CloudMove ("云流动速度", Vector) = (0,0,0,0)
        

//        [Header(Bend)]
//        _BendPushStrength ("Push Strength", Range(0.0, 1.0)) = 1.0
//        _BendFlattenStrength ("Flatten Strength", Range(0.0, 1.0)) = 1.0
//        _PerspectiveCorrection ("Perspective Correction", Range(0.0, 1.0)) = 0.0

        [HideInInspector]_grassHeight ("_grassHeight", Float) = 1
    }

    
    CGINCLUDE
        #define UNITY_SETUP_BRDF_INPUT MetallicSetup
        #include "SceneLightingDefine.hlsl"
    ENDCG
    
    SubShader 
    {
        Tags { "Queue" = "Geometry" "RenderType"="Opaque" "PerformanceChecks"="False" }
        Cull Off

        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            
            CGPROGRAM
            #pragma target 3.0
            // #pragma multi_compile __ USE_GLOBAL_SCENE_FADE
            #pragma multi_compile_fwdbase
            #pragma skip_variants VERTEXLIGHT_ON DYNAMICLIGHTMAP_ON DIRLIGHTMAP_COMBINED SHADOWS_SOFT FOG_EXP FOG_EXP2 LIGHTMAP_SHADOW_MIXING
            #pragma shader_feature _ SHADING_BAKER

            #pragma vertex vertBase
            #pragma fragment fragBase

            #include "UnityCg.cginc"
            #include "AutoLight.cginc"
            #include "UnityShadowLibrary.cginc"
            #include "../SYPackages/Grass/Libraries/Input.hlsl"
            #include "../SYPackages/Grass/Libraries/Wind.hlsl"
            #include "Builtin/UnityStandardCore.cginc"

        
            #pragma multi_compile_instancing
        
            half4 _WindDirection;
            half _WindSpeed;
            half _WindGustStrength;
            half _WindGustFreq;
            half _grassHeight;
            half _WindControl;
            
        
        
            void CalcuWordPos(in VertexInput vi, out float4 posWS, out float3 normalWS)
            {
                float3 wPos = mul(unity_ObjectToWorld, vi.vertex).xyz;
                WindSettings wind = PopulateWindSettings(0, _WindSpeed, _WindDirection, vi.uv0.y, _WindGustStrength, _WindGustFreq);
                normalWS = UnityObjectToWorldNormal(vi.normal);
                GetSimpleWindWithNormal(wPos, vi.vertex.xyz,normalWS, vi.color,wind, vi.uv0.y, _WindControl);
                posWS.xyzw = float4(wPos,1);
            }
            
            VertexOutputForwardBase vertBase (VertexInput v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                VertexOutputForwardBase o;
                UNITY_INITIALIZE_OUTPUT(VertexOutputForwardBase, o);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                // TRANSFER_COMBINE_DC_ID(o, v);

                TRANSFORM_WAVE_VERTEX(v.vertex, v.color);
                // float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
        		//偏移顶点坐标
                float4 posWorld = 0;
                float3 normalWorld = 0;
        		CalcuWordPos(v, posWorld, normalWorld);
                #if UNITY_REQUIRE_FRAG_WORLDPOS
                #if UNITY_PACK_WORLDPOS_WITH_TANGENT
                o.tangentToWorldAndPackedData[0].w = posWorld.x;
                o.tangentToWorldAndPackedData[1].w = posWorld.y;
                o.tangentToWorldAndPackedData[2].w = posWorld.z;
                #else
                o.posWorld = posWorld.xyz;
                #endif
                #endif
                o.pos = UnityWorldToClipPos(posWorld);

                o.tex = TexCoords(v);
                o.color = v.color;
                o.eyeVec.xyz = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
                #ifdef _TANGENT_TO_WORLD
                float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

                float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
                o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
                o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
                o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
                #else
                o.tangentToWorldAndPackedData[0].xyz = 0;
                o.tangentToWorldAndPackedData[1].xyz = 0;
                o.tangentToWorldAndPackedData[2].xyz = normalWorld;
                #endif

                //We need this for shadow receving
                UNITY_TRANSFER_LIGHTING(o, v.uv1);

                o.ambientOrLightmapUV = VertexGIForward(v, posWorld, normalWorld);

                #ifdef _PARALLAXMAP
                TANGENT_SPACE_ROTATION;
                half3 viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
                o.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
                o.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
                o.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
                #endif


                #if defined(SHADING_BAKER)
                o.pos = float4(v.uv1.xy * 2 - 1,1,1);
                o.pos.y = -o.pos.y;
                #endif
                return o;
            }
            half4 fragBase (VertexOutputForwardBase i) : SV_Target { return fragForwardBaseInternalWithoutMask(i); }
            // #include "Builtin/UnityStandardCoreForward.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            ZWrite Off
            ZTest LEqual

            CGPROGRAM
            #pragma target 3.0
            #pragma multi_compile_fwdadd
            #pragma skip_variants DIRECTIONAL_COOKIE POINT_COOKIE SHADOWS_SOFT FOG_EXP FOG_EXP2 LIGHTMAP_SHADOW_MIXING
            #pragma shader_feature _ SHADING_BAKER
            #include "UnityCg.cginc"
            #include "AutoLight.cginc"
            #include "UnityShadowLibrary.cginc"
            #include "../SYPackages/Grass/Libraries/Input.hlsl"
            #include "../SYPackages/Grass/Libraries/Wind.hlsl"
            #include "Builtin/UnityStandardCore.cginc"

        
            #pragma multi_compile_instancing
        
            half4 _WindDirection;
            half _WindSpeed;
            half _WindGustStrength;
            half _WindGustFreq;
            half _grassHeight;
            half _WindControl;
        
        
            void CalcuWordPos(in VertexInput vi, out float4 posWS, out float3 normalWS)
            {
                float3 wPos = mul(unity_ObjectToWorld, vi.vertex).xyz;
                WindSettings wind = PopulateWindSettings(0, _WindSpeed, _WindDirection, vi.uv0.y, _WindGustStrength, _WindGustFreq);
                normalWS = UnityObjectToWorldNormal(vi.normal);
                GetSimpleWindWithNormal(wPos, vi.vertex.xyz,normalWS, vi.color,wind, vi.uv0.y, _WindControl);
                posWS.xyzw = float4(wPos,1);
            }
            #pragma vertex vertAdd
            #pragma fragment fragAdd
            VertexOutputForwardAdd vertAdd (VertexInput v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                VertexOutputForwardAdd o;
                UNITY_INITIALIZE_OUTPUT(VertexOutputForwardAdd, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                // TRANSFER_COMBINE_DC_ID(o, v);

                TRANSFORM_WAVE_VERTEX(v.vertex, v.color);
                float4 posWorld = 0;
                float3 normalWorld = UnityObjectToWorldNormal(v.normal);
                CalcuWordPos(v,posWorld, normalWorld);
                o.pos = UnityWorldToClipPos(posWorld);

                o.tex = TexCoords(v);
                o.color = v.color;
                o.eyeVec.xyz = NormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
                o.posWorld = posWorld.xyz;
                #ifdef _TANGENT_TO_WORLD
                    float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);

                    float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
                    o.tangentToWorldAndLightDir[0].xyz = tangentToWorld[0];
                    o.tangentToWorldAndLightDir[1].xyz = tangentToWorld[1];
                    o.tangentToWorldAndLightDir[2].xyz = tangentToWorld[2];
                #else
                    o.tangentToWorldAndLightDir[0].xyz = 0;
                    o.tangentToWorldAndLightDir[1].xyz = 0;
                    o.tangentToWorldAndLightDir[2].xyz = normalWorld;
                #endif
                //We need this for shadow receiving and lighting
                UNITY_TRANSFER_LIGHTING(o, v.uv1);

                float3 lightDir = _WorldSpaceLightPos0.xyz - posWorld.xyz * _WorldSpaceLightPos0.w;
                #ifndef USING_DIRECTIONAL_LIGHT
                    lightDir = NormalizePerVertexNormal(lightDir);
                #endif
                o.tangentToWorldAndLightDir[0].w = lightDir.x;
                o.tangentToWorldAndLightDir[1].w = lightDir.y;
                o.tangentToWorldAndLightDir[2].w = lightDir.z;

                #ifdef _PARALLAXMAP
                    TANGENT_SPACE_ROTATION;
                    o.viewDirForParallax = mul (rotation, ObjSpaceViewDir(v.vertex));
                #endif

                #if defined(SHADING_BAKER)
                o.pos = float4(v.uv1.xy * 2 - 1,1,1);
                o.pos.y = -o.pos.y;
                #endif
                return o;
            }
            half4 fragAdd (VertexOutputForwardAdd i) : SV_Target { return fragForwardAddInternalWithoutMask(i); }
            ENDCG
        }
        // ------------------------------------------------------------------
        //  Shadow rendering pass
        // 保留深度用以烘焙
        Pass {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual

            CGPROGRAM
            
            #pragma target 3.0
            #pragma exclude_renderers gles gles3 glcore metal vulkan
            #pragma multi_compile_shadowcaster
            #pragma shader_feature _ SHADING_BAKER

            //#pragma multi_compile_instancing
            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster
            #include "Builtin/UnityStandardShadow.cginc"

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
    }
    Fallback "Unlit"
    //FallBack "Hidden/Universal Render Pipeline/FallbackError"
}