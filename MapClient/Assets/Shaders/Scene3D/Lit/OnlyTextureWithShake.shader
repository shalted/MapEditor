Shader "XianXia/Scene3D/Lit/OnlyTextureWithShake"
{
    Properties
    {
        [Enum(Off,0,On,1)]_ZWrite("深度写入",float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendModeSrc("自身混合因子",Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendModeDst("目标混合因子",Int) = 0
        _MainTex ("Texture", 2D) = "white" {}
        _HDRCode("HDR",Float) = 1
        _CloudMap ("云阴影", 2D) = "black"{}
        _CloudMove ("云流动速度", Vector) = (0,0,0,0)
        
        [Header(Wind)]
        [NoScaleOffset] _WindMap ("Wind map", 2D) = "black" { }
        _WindSpeed ("Speed", Range(0.0, 10.0)) = 3.0
        _WindDirection ("Direction", vector) = (1, 0, 0, 0)
        [Toggle]_WindControl ("Move Control", Float) = 0
        _WindGustStrength ("Gusting strength", Range(0.0, 2)) = 0.5
        _WindGustFreq ("Gusting frequency", Range(0.0, 10.0)) = 2
        _WindBack ("回摆", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Blend [_BlendModeSrc] [_BlendModeDst]
            ZWrite [_ZWrite]
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "../Fog/ModelComputeFogLibrary.cginc"
            #include "../SYPackages/Grass/Libraries/Wind.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 color : COLOR0;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
                float4 pos : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _HDRCode;

            half4 _WindDirection;
            half _WindSpeed;
            half _WindGustStrength;
            half _WindGustFreq;
            half _grassHeight;
            half _WindControl;
            
            void CalcuWordPos(in appdata vi, out float4 posWS, float weight)
            {
                float3 wPos = mul(unity_ObjectToWorld, vi.vertex).xyz;
                WindSettings wind = PopulateWindSettings(0, _WindSpeed, _WindDirection, weight, _WindGustStrength, _WindGustFreq);
                float3 windVec = GetSimpleWindHeight(wPos, wind, weight);  
                posWS.xyzw = float4(windVec,1);
            }
            
            half4 DecodeRGBM(half4 color)
		    {
			    return half4(color.rgb / _HDRCode,1- color.a);
		    }
            v2f vert (appdata v)
            {
                v2f o;
                CalcuWordPos(v, o.worldPos, v.color.r);
                // o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityWorldToClipPos(o.worldPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                col = DecodeRGBM(col);
                col.a = i.color.r * col.a;

                ComputeModelFog(i.pos.z, i.worldPos.y,col.rgb);
                ComputeCloudShadow(i.worldPos, col.rgb);
                return col;
            }
            ENDCG
        }
    }
}
