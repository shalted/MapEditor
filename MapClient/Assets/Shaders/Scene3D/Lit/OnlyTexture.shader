Shader "XianXia/Scene3D/Lit/OnlyTexture"
{
    Properties
    {
        [Enum(Off,0,On,1)]_ZWrite("深度写入",float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendModeSrc("自身混合因子",Int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_BlendModeDst("目标混合因子",Int) = 0
        [Toggle(AlphaClip)]_Clip("是否开启全透", int) = 0
        _MainTex ("Texture", 2D) = "white" {}
        _HDRCode("HDR",Float) = 1
        _CloudMap ("云阴影", 2D) = "black"{}
        _CloudMove ("云流动速度", Vector) = (0,0,0,0)
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
            #pragma multi_compile_fragment _ AlphaClip
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
            half4 DecodeRGBM(half4 color)
		    {
			    return half4(color.rgb / _HDRCode, color.a);
		    }
            v2f vert (appdata v)
            {
                v2f o;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityWorldToClipPos(o.worldPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);
                col.a = i.color.r * col.a;
                #if defined(AlphaClip)
                clip(col.a - 0.001);
                #endif
                
                col = DecodeRGBM(col);
                
                ComputeModelFog(i.pos.z, i.worldPos.y,col.rgb);
                ComputeCloudShadow(i.worldPos, col.rgb);
                return col;
            }
            ENDCG
        }
    }
}
