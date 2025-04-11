
Shader "ShiYue/Terrain/TerrainDiffuse" {
    Properties {
        [HDR] _Color ("Color", color) = (1, 1, 1, 1)
        [NoScaleOffset]_MainMap0 ("BaseMap1", 2D) = "white" { }
        [NoScaleOffset]_MainMap1 ("BaseMap2", 2D) = "white" { }
        [NoScaleOffset]_MainMap2 ("BaseMap3", 2D) = "white" { }
        [NoScaleOffset]_MainMap3 ("BaseMap4", 2D) = "white" { }
        [NoScaleOffset]_NormalMask0 ("Normal&Mask Map1", 2D) = "white" { }
        [NoScaleOffset]_NormalMask1 ("Normal&Mask Map2", 2D) = "white" { }
        [NoScaleOffset]_NormalMask2 ("Normal&Mask Map3", 2D) = "white" { }
        [NoScaleOffset]_NormalMask3 ("Normal&Mask Map4", 2D) = "white" { }
        [NoScaleOffset]_Control ("Control", 2D) = "white" { }

        _NormalScale ("NormalScale", Vector) = (1, 1, 1, 1)
        _UVScale ("UV Scale", Vector) = (1, 1, 1, 1)
        _Weight ("Weight", Vector) = (0, 0, 0, 0)
        
        _Roughness ("粗糙度", Range(0, 1)) = 0
        _CloudMap ("云阴影", 2D) = "black"{}
        _CloudMove ("云流动速度", Vector) = (0,0,0,0)
        
    }

    CGINCLUDE
    #define HALF_MIN 6.103515625e-5

    float4 TerrainHeightBlend(float4 depth, float4 weight, float4 control) {
        float4 blend;

        blend.r = depth.r * control.r;
        blend.g = depth.g * control.g;
        blend.b = depth.b * control.b;
        blend.a = depth.a * control.a;

        float ma = max(blend.r, max(blend.g, max(blend.b, blend.a)));
        blend = max(blend - ma + weight, HALF_MIN) * control;
        return blend / (blend.r + blend.g + blend.b + blend.a);
    }
    #include "UnityCG.cginc"
    #include "../../Lit/SceneLightingDefine.hlsl"
    #include "../../Lit/Builtin/Lighting.cginc"
    #include "AutoLight.cginc"
    ENDCG

    SubShader {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry+499" }

        Pass {

            CGPROGRAM
            #include "../../Fog/ModelComputeFogLibrary.cginc"

            #pragma multi_compile_fwdbase
            //#pragma multi_compile __ USE_GLOBAL_SCENE_FADE
            #pragma skip_variants VERTEXLIGHT_ON DYNAMICLIGHTMAP_ON DIRLIGHTMAP_COMBINED SHADOWS_SOFT FOG_EXP FOG_EXP2
            #pragma multi_compile _ _NORMALMAP
            #pragma multi_compile _ _HEIGHTBLEND
            #pragma shader_feature _ SHADING_BAKER
            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainMap0;
            sampler2D _MainMap1;
            sampler2D _MainMap2;
            sampler2D _MainMap3;
            sampler2D _NormalMask0;
            sampler2D _NormalMask1;
            sampler2D _NormalMask2;
            sampler2D _NormalMask3;
            sampler2D _Control;
            
            float4 _RunTimeLightDir;
            half4 _RunTimeLightColor;
            half4 _NormalScale;
            half4 _UVScale;
            half4 _Weight;
            half4 _AmbientColor;
            
            float _Roughness;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
                float2 lmUV : TEXCOORD1;// lightmap uv

            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS(4)
                float2 lmUV : TEXCOORD5;
            };

            float GGXDistribution(float roughness, float NdotH)
            {
            	float roughness2 = roughness * roughness;
            	float NdotH2 = NdotH * NdotH;
            
            	float denomTerm = NdotH2 * (roughness2 - 1) + 1;
            				
            	float nom = roughness2;
            	float denom = UNITY_PI * denomTerm * denomTerm;
            
            	return nom * rcp(denom);
            }

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord.xy;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW(o);
                o.lmUV = v.lmUV * unity_LightmapST.xy + unity_LightmapST.zw;

                UNITY_TRANSFER_FOG(o,o.pos);
                
                #if defined(SHADING_BAKER)
                o.pos = float4(v.lmUV.xy * 2 - 1,1,1);
                o.pos.y = -o.pos.y;
                #endif

                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir  = normalize(_WorldSpaceCameraPos - worldPos);
                fixed3 halfDir  = normalize(lightDir + viewDir);

                half4 lay0 = tex2D(_MainMap0, i.uv * _UVScale.x);
                half4 lay1 = tex2D(_MainMap1, i.uv * _UVScale.y);
                half4 lay2 = tex2D(_MainMap2, i.uv * _UVScale.z);
                half4 lay3 = tex2D(_MainMap3, i.uv * _UVScale.w);

                half4 control = tex2D(_Control, i.uv);
                //用1-rgb来代表第四个通道，即红绿蓝黑，防止A通道被压缩的风险
                //control = half4(control.rgb, 1 - saturate(control.r + control.g + control.b));
                #ifdef _HEIGHTBLEND
                    control = TerrainHeightBlend(float4(lay0.a, lay1.a, lay2.a, lay3.a), _Weight, control);
                #endif

                fixed roughness = _Roughness;
                
                fixed3 bump = fixed3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z);
                #if _NORMALMAP
                    half4 bump0 = tex2D(_NormalMask0, i.uv * _UVScale.x) ;
                    half4 bump1 = tex2D(_NormalMask1, i.uv * _UVScale.y) ;
                    half4 bump2 = tex2D(_NormalMask2, i.uv * _UVScale.z) ;
                    half4 bump3 = tex2D(_NormalMask3, i.uv * _UVScale.w) ;

                    half3 bumpxyz0 = UnpackNormalWithScale(bump0, _NormalScale.x);
                    half3 bumpxyz1 = UnpackNormalWithScale(bump1, _NormalScale.y);
                    half3 bumpxyz2 = UnpackNormalWithScale(bump2, _NormalScale.z);
                    half3 bumpxyz3 = UnpackNormalWithScale(bump3, _NormalScale.w);

                    bump = bumpxyz0 * control.r + bumpxyz1 * control.g + bumpxyz2 * control.b + bumpxyz3 * control.a;
                    roughness *= bump.b;
                
                    bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                #endif

                fixed3 albedo = (lay0.rgb * control.r + lay1.rgb * control.g + lay2.rgb * control.b + lay3.rgb * control.a) * _Color.rgb;
                half atten = SHADOW_ATTENUATION(i);
                half4 shadowmask;
                half bakedAtten = UnitySampleBakedOcclusion(i.lmUV.xy, worldPos, shadowmask);

                fixed3 indirect = float3(0.0, 0.0, 0.0);
                #ifdef LIGHTMAP_ON
                    half4 lightmap = SampleLightmap(shadowmask, i.lmUV);
                    fixed3 lmColor = DecodeLightmap(lightmap);
                    indirect += lmColor;
                #else
                    indirect += ShadeSH9(half4(bump, 1));
                #endif
                indirect = lerp(indirect, _AmbientColor.rgb, _AmbientColor.a);

                // half atten = SHADOW_ATTENUATION(i);
                // half bakedAtten = UnitySampleBakedOcclusion(i.lmUV.xy, worldPos);

                //混合实时阴影和shadowMask
                float zDist = dot(_WorldSpaceCameraPos - worldPos, UNITY_MATRIX_V[2].xyz);
                float fadeDist = UnityComputeShadowFadeDistance(worldPos, zDist);
                atten = UnityMixRealtimeAndBakedShadows(atten, bakedAtten, UnityComputeShadowFade(fadeDist));

            #if LIGHTMAP_ON
                fixed3 diffuse = _RunTimeLightColor.rgb * max(0, dot(bump, _RunTimeLightDir.xyz)) * atten;
                fixed3 specular = GGXDistribution(roughness, saturate(dot(bump, halfDir)));
                fixed3 color = (diffuse  + specular + indirect) * albedo;
            #else
                fixed3 diffuse = _LightColor0.rgb * max(0, dot(bump, lightDir)) * atten;
                fixed3 specular = GGXDistribution(roughness, saturate(dot(bump, halfDir))) * _LightColor0.rgb * max(0, dot(bump, lightDir));
                fixed3 color = (diffuse + specular + indirect) * albedo;
            #endif
                ComputeModelFog(i.pos.z, worldPos.y, color);
                ComputeCloudShadow(worldPos, color);
                return fixed4(color, 1.0);
            }

            ENDCG

        }

        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            Blend One One

            CGPROGRAM
            #include "../../Fog/ModelComputeFogLibrary.cginc"

            #pragma multi_compile_fwdadd
            // Use the line below to add shadows for point and spot lights
            //			#pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile __ USE_GLOBAL_SCENE_FADE
            #pragma skip_variants VERTEXLIGHT_ON DYNAMICLIGHTMAP_ON DIRLIGHTMAP_COMBINED SHADOWS_SOFT FOG_EXP FOG_EXP2
            #pragma shader_feature _ _NORMALMAP
            #pragma shader_feature _ _HEIGHTBLEND
            #pragma shader_feature _ SHADING_BAKER
            #pragma vertex vert
            #pragma fragment frag

            #define HALF_MIN 6.103515625e-5

            sampler2D _MainMap0;
            sampler2D _MainMap1;
            sampler2D _MainMap2;
            sampler2D _MainMap3;
            sampler2D _NormalMask0;
            sampler2D _NormalMask1;
            sampler2D _NormalMask2;
            sampler2D _NormalMask3;
            sampler2D _Control;

            half4 _NormalScale;
            half4 _UVScale;
            half4 _Weight;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
                #if defined(SHADING_BAKER)
                float4 lmUV : TEXCOORD1;
                #endif
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord.xy ;

                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW(o);
                #if defined(SHADING_BAKER)
                o.pos = float4(v.lmUV.xy * 2 - 1,1,1);
                o.pos.y = -o.pos.y;
                #endif
                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                half4 lay0 = tex2D(_MainMap0, i.uv * _UVScale.x);
                half4 lay1 = tex2D(_MainMap1, i.uv * _UVScale.y);
                half4 lay2 = tex2D(_MainMap2, i.uv * _UVScale.z);
                half4 lay3 = tex2D(_MainMap3, i.uv * _UVScale.w);

                half4 control = tex2D(_Control, i.uv);
                //用1-rgb来代表第四个通道，即红绿蓝黑，防止A通道被压缩的风险
                //control = half4(control.rgb, 1 - saturate(control.r + control.g + control.b));
                #ifdef _HEIGHTBLEND
                    control = TerrainHeightBlend(float4(lay0.a, lay1.a, lay2.a, lay3.a), _Weight, control);
                #endif

                fixed3 bump = fixed3(i.TtoW0.z, i.TtoW1.z, i.TtoW2.z);
                #ifdef _NORMALMAP
                    half4 bump0 = tex2D(_NormalMask0, i.uv * _UVScale.x) ;
                    half4 bump1 = tex2D(_NormalMask1, i.uv * _UVScale.y) ;
                    half4 bump2 = tex2D(_NormalMask2, i.uv * _UVScale.z) ;
                    half4 bump3 = tex2D(_NormalMask3, i.uv * _UVScale.w) ;

                    half3 bumpxyz0 = UnpackNormalWithScale(bump0, _NormalScale.x);
                    half3 bumpxyz1 = UnpackNormalWithScale(bump1, _NormalScale.y);
                    half3 bumpxyz2 = UnpackNormalWithScale(bump2, _NormalScale.z);
                    half3 bumpxyz3 = UnpackNormalWithScale(bump3, _NormalScale.w);

                    bump = bumpxyz0 * control.r + bumpxyz1 * control.g + bumpxyz2 * control.b + bumpxyz3 * control.a;
                    bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
                #endif

                fixed3 albedo = (lay0.rgb * control.r + lay1.rgb * control.g + lay2.rgb * control.b + lay3.rgb * control.a) * _Color.rgb;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));

                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);
                half3 color = diffuse * atten;
                //ComputeModelFog(i.pos.z, worldPos.y, color);
                return fixed4(color, 1.0);
            }

            ENDCG

        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On ZTest LEqual Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #pragma shader_feature _ SHADING_BAKER
            #include "UnityCG.cginc"
            struct appdata_base1 {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                float2 lmUV : TEXCOORD1;// lightmap uv
            };

            struct v2f {
                V2F_SHADOW_CASTER;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert( appdata_base1 v )
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                #if defined(SHADING_BAKER)
                o.pos = float4(v.lmUV.xy * 2 - 1,1,1);
                o.pos.y = -o.pos.y;
                #endif
                return o;
            }

            float4 frag( v2f i ) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }

        Pass {
            Name "Meta"
            Tags { "LightMode" = "Meta" }
            Cull Off

            CGPROGRAM

            #pragma vertex vert_meta
            #pragma fragment frag_meta

            #include "Lighting.cginc"
            #include "UnityMetaPass.cginc"

            #define HALF_MIN 6.103515625e-5

            sampler2D _MainMap0;
            sampler2D _MainMap1;
            sampler2D _MainMap2;
            sampler2D _MainMap3;
            sampler2D _NormalMask0;
            sampler2D _NormalMask1;
            sampler2D _NormalMask2;
            sampler2D _NormalMask3;
            sampler2D _Control;

            half4 _NormalScale;
            half4 _UVScale;
            half4 _Weight;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
                float2 lmUV : TEXCOORD1;// lightmap uv
                float2 dlmUV : TEXCOORD2;// dynamic lightmap uv

            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert_meta(a2v v) {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityMetaVertexPosition(v.vertex, v.lmUV.xy, v.dlmUV.xy, unity_LightmapST, unity_DynamicLightmapST);
                o.uv = v.texcoord.xy;
                return o;
            }

            fixed4 frag_meta(v2f IN) : SV_Target {
                UnityMetaInput metaIN;
                UNITY_INITIALIZE_OUTPUT(UnityMetaInput, metaIN);

                half4 lay0 = tex2D(_MainMap0, IN.uv * _UVScale.x);
                half4 lay1 = tex2D(_MainMap1, IN.uv * _UVScale.y);
                half4 lay2 = tex2D(_MainMap2, IN.uv * _UVScale.z);
                half4 lay3 = tex2D(_MainMap3, IN.uv * _UVScale.w);

                half4 control = tex2D(_Control, IN.uv);
                //用1-rgb来代表第四个通道，即红绿蓝黑，防止A通道被压缩的风险
                //control = half4(control.rgb, 1 - saturate(control.r + control.g + control.b));
                #ifdef _HEIGHTBLEND
                    control = TerrainHeightBlend(float4(lay0.a, lay1.a, lay2.a, lay3.a), _Weight, control);
                #endif

                metaIN.Albedo = (lay0.rgb * control.r + lay1.rgb * control.g + lay2.rgb * control.b + lay3.rgb * control.a) * _Color.rgb;
                metaIN.Emission = 0;
                return UnityMetaFragment(metaIN);
            }

            ENDCG

        }
    }
    //FallBack "Diffuse"
}
