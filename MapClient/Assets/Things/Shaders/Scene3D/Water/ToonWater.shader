Shader "XianXia/Scene3D/ToonWater"
{
    Properties
    {
        [NoScaleOffset]_NoiseTex ("扰动贴图", 2D) = "white" {}

        _DeepColor("深水颜色", Color) = (0, 0.5, 1, 0.8)
        _ShallowColor("浅水颜色", Color) = (0, 0.5, 0.5, 0)
        _MaxDepthDistance("深浅的分界", Float) = 1
        _EdgeSoftDepth("边缘软过渡深度", Range(0.01, 0.9)) = 0.2
        _FlowSpeed("水流速度", Range(0, 10.0)) = 1
        [Space(20)]
        _SpecColor ("高光颜色", Color) = (1, 1, 1, 1)
        _SpecStrength("高光强度", Range(0.01, 2.0)) = 0.5
        _NormalNoiseSpeed ("法线 扰动速度", Vector) = (1, 1, 0, 0)
        _NormalNoiseStrength("法线 扰动强度", Vector) = (1, 1, 0, 0)
        _NormalNoiseTiling("法线 扰动Tiling", Vector) = (1, 1, 0, 0)
        _NormalScale("法线 缩放", Range(0, 4)) = 1
        _NormalTex ("法线贴图", 2D) = "bump" {}

        [Toggle(USE_REFLECTION)]
        [Space(20)]
		_UseReflection("是否开启水面倒影", Float) = 0
        [HideInInspector]_ScreenReflectionTex("_ScreenReflectionTex", 2D) = "white" {}
        _ReflectionAlpha("水面倒影 强度", Range(0.01, 1)) = 0.3
        _ReflectionNoiseTiling("水面倒影 扰动缩放", Float) = 20
        _ReflectionNoiseParams("水面倒影 扰动(xy强度，zw速度)", Vector) = (0.5, 0.5, -1, 1)

        [Toggle(USE_WAVE)]
        [Space(20)]
		_UseWave("是否开启浪花", Float) = 0
        _WaveStart("浪花 开始位置", Range(0, 1.0)) = 0.6
        _WaveFadeIn("浪花 淡入范围", Range(0.01, 1.0)) = 0.1
        _WaveFadeoutStartDepth("浪花 淡出开始深度", Range(0.01, 5)) = 1
        _WaveFadeoutArea("浪花 淡出深度范围", Range(0, 2)) = 0.2
        _WaveSpeed("浪花 流动速度", Range(0, 10.0)) = 1
        _WaveTex ("浪花贴图", 2D) = "white" {}

        _WaveNoiseSpeed ("浪花 扰动速度", Range (-10, 10)) = 1
        _WaveNoiseStrength("浪花 扰动强度", Range(0, 1)) = 0.1
        _WaveNoiseTiling("浪花 扰动Tiling", Vector) = (1, 1, 0, 0)

        [Toggle(DEBUG_WAVE_MASK)]
        _UseDebugWaveMask("调试浪花遮罩", Float) = 0
        _WaveMaskSpeedR("浪花 遮罩速度 通道R", Vector) = (0, 1, 0, 0)
        _WaveMaskSpeedG("浪花 遮罩速度 通道G", Vector) = (0, 1, 0, 0)
        _WaveMaskTex ("浪花 遮罩(RG)", 2D) = "black" {}
    }
    SubShader
    {
        Tags {"RenderType" = "Transparent" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_local __ USE_WAVE USE_REFLECTION
            #pragma shader_feature_local DEBUG_WAVE_MASK
            #include "../../CGInclude/GameCGDefines.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                half4 color : COLOR;
            };
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                half4 color : COLOR;
                float4 screenPos : TEXCOORD1;
                float4 uvParams : TEXCOORD2;
                float4 waveMaskUV : TEXCOORD3;
                half3 viewDirTS : TEXCOORD4;
                float4 noiseUVs : TEXCOORD5;
                #ifdef USE_REFLECTION
                float2 refNoiseUV : TEXCOORD6;
                float3 refViewPos : TEXCOORD7;
                #endif
            };
            uniform sampler2D _CameraDepthTexture;

            half4 _DeepColor, _ShallowColor;
            half _MaxDepthDistance;
            half _EdgeSoftDepth;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            sampler2D _NoiseTex;
            //float4 _NoiseTex_ST;
            half _FlowSpeed;

            half4 _SpecColor;
            half _SpecStrength;
            half2 _NormalNoiseSpeed;
            half2 _NormalNoiseStrength;
            half2 _NormalNoiseTiling;
            half _NormalScale;

            sampler2D _ScreenReflectionTex;
            half _ReflectionAlpha;
            half _ReflectionNoiseTiling;
            half4 _ReflectionNoiseParams;

            sampler2D _WaveTex;
            float4 _WaveTex_ST;
            sampler2D _WaveMaskTex;
            float4 _WaveMaskTex_ST;
            half _WaveStart;
            half _WaveFadeIn;
            half _WaveFadeoutStartDepth;
            half _WaveFadeoutArea;
            half _WaveSpeed;
            half _WaveNoiseStrength;
            half _WaveNoiseSpeed;
            half2 _WaveNoiseTiling;
            half2 _WaveMaskSpeedR;
            half2 _WaveMaskSpeedG;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeNonStereoScreenPos(o.vertex);
                o.uv = v.uv;
                o.color = v.color;
                TANGENT_SPACE_ROTATION;
                o.viewDirTS = mul(rotation, ObjSpaceViewDir(v.vertex));
                o.viewDirTS = SafeNormalize(o.viewDirTS);

                float2 baseAnimV = float2(0, _Time.x * -1);
                o.uvParams.xy = TRANSFORM_TEX(v.uv, _NormalTex) + baseAnimV * _FlowSpeed;
                o.uvParams.zw = TRANSFORM_TEX(v.uv, _WaveTex) + baseAnimV * _WaveSpeed;
                o.noiseUVs.xy = v.uv * _NormalNoiseTiling + _Time.x * _NormalNoiseSpeed.xy;
                o.noiseUVs.zw = v.uv * _WaveNoiseTiling + baseAnimV * _WaveNoiseSpeed;
                float2 maskBaseUV = TRANSFORM_TEX(v.uv, _WaveMaskTex);
                o.waveMaskUV.xy = maskBaseUV + _Time.x * _WaveMaskSpeedR.xy;
                o.waveMaskUV.zw = maskBaseUV + _Time.x * _WaveMaskSpeedG.xy;

                #ifdef USE_REFLECTION
                o.refNoiseUV = v.vertex.xz * _ReflectionNoiseTiling * 0.01 + _Time.x * _ReflectionNoiseParams.zw;
                o.refViewPos = UnityObjectToViewPos(v.vertex);
                #endif
                return o;
            }
            half4 frag (v2f i) : SV_Target
            {
				float depth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r;
				float depthDistance = LinearEyeDepth(depth) - i.screenPos.w;
				float depthDistance01 = saturate(depthDistance / _MaxDepthDistance);
				half4 color = lerp(_ShallowColor, _DeepColor, depthDistance01);
                color.a *= smoothstep(0, _EdgeSoftDepth, depthDistance01);
                //return color;

                half2 normalNoiseStrength = tex2D(_NoiseTex, i.noiseUVs.xy).rg * _NormalNoiseStrength;
                half4 packedNormalTex = tex2D(_NormalTex, i.uvParams.xy + normalNoiseStrength);
                half3 normalDirTS = normalize(UnpackNormalWithScale(packedNormalTex, _NormalScale));
                half3 viewDirTS = normalize(i.viewDirTS);
                float dotVN = max(0.0001, dot(viewDirTS, normalDirTS));
                float vdn = saturate(pow(dotVN, _SpecStrength));
                color.rgb += lerp(_SpecColor.rgb, 0, vdn);
                //return color;

                #ifdef USE_REFLECTION
                half2 refNoiseTex = tex2D(_NoiseTex, i.refNoiseUV).rg - 0.5;
                i.refViewPos.xy += refNoiseTex * _ReflectionNoiseParams.xy * 0.1;
                float4 refClipPos = UnityViewToClipPos(i.refViewPos);
                float4 refScreenPos = ComputeNonStereoScreenPos(refClipPos);
                half4 reflectTex = tex2Dproj(_ScreenReflectionTex, UNITY_PROJ_COORD(refScreenPos));
                half refAlpha = saturate(reflectTex.a * _ReflectionAlpha);
                color.rgb = reflectTex.rgb * refAlpha + color.rgb * (1 - refAlpha);
                #endif

                #ifdef USE_WAVE
                half noiseStrength = tex2D(_NoiseTex, i.noiseUVs.zw).r * _WaveNoiseStrength;
                half2 offsetNoise = half2(0, noiseStrength);
                half waveMaskTexR = tex2D(_WaveMaskTex, i.waveMaskUV.xy + offsetNoise).r;
                half waveMaskTexG = tex2D(_WaveMaskTex, i.waveMaskUV.zw + offsetNoise).g;
                half waveMaskTex = waveMaskTexR + waveMaskTexG;
                half waveMask = smoothstep(_WaveStart, _WaveStart + _WaveFadeIn, i.uv.y);
                waveMask = saturate(waveMask - waveMaskTex);
                half waveFadeoutEndDepth = _WaveFadeoutStartDepth - _WaveFadeoutArea;
                waveMask *= smoothstep(waveFadeoutEndDepth, _WaveFadeoutStartDepth, depthDistance);
                #ifdef DEBUG_WAVE_MASK
                return half4(waveMask.rrr, 1);
                #endif
                half4 waveTex = tex2D(_WaveTex, i.uvParams.zw + offsetNoise);
                waveTex.rgb *= _GameUnitColor;
                half waveAlpha = waveTex.a * waveMask;
                color.rgb = waveTex.rgb * waveAlpha + (1 - waveAlpha) * color.rgb;
                color.a += waveAlpha;
                #endif

                color *= i.color;
                return color;
            }
            ENDCG
        }
    }
}