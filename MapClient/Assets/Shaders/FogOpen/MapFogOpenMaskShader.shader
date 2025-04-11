// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "UI/MapFogOpenMask"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        
        // 角色视野圈
        _FogOpenPlayerScreenPos ("FogOpenPlayerScreenPos", Vector) = (0,0,0,0)
        _FogOpenPlayerIntensity ("FogOpenPlayerIntensity", Float) = 0

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend One OneMinusSrcAlpha
        ColorMask [_ColorMask]

        Pass
        {
            Name "MapFogOpenMask"
            Tags
            {
                "LightMode" = "MapFogOpenMask" 
            }
        CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"
            
            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP
            #pragma multi_compile _ _FOGOPENPLAYERVIEW
            #pragma multi_compile _ _FOGOPENAllCHARAVIEW

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                float4  mask : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
            float _UIMaskSoftnessX;
            float _UIMaskSoftnessY;
            int _UIVertexColorAlwaysGammaSpace;

            // 角色视野圈
            float2 _FogOpenPlayerScreenPos;
            float _FogOpenPlayerIntensity;
            float2 _CharaViewRTWidthHeight;

            sampler2D _CharaViewBlitCharaViewRT;
            // 开启角色视野的时候，角色的屏幕坐标位置
            float2 _CharaViewOriginCharaPos;
            
            // 锁比例的距离计算
            float LockPropotionDistance(float2 pos1, float2 pos2, float percent)
            {
                return sqrt(pow(pos1.x - pos2.x, 2) + pow((pos1.y - pos2.y) * percent, 2));
            }
            
            v2f vert(appdata_t v)
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                float4 vPosition = UnityObjectToClipPos(v.vertex);
                OUT.worldPosition = v.vertex;
                OUT.vertex = vPosition;

                float2 pixelSize = vPosition.w;
                pixelSize /= float2(1, 1) * abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));

                float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
                float2 maskUV = (v.vertex.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
                OUT.texcoord = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
                OUT.mask = float4(v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_UIMaskSoftnessX, _UIMaskSoftnessY) + abs(pixelSize.xy)));


                if (_UIVertexColorAlwaysGammaSpace)
                {
                    if(!IsGammaSpace())
                    {
                        v.color.rgb = UIGammaToLinear(v.color.rgb);
                    }
                }

                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                // 角色视野精度
                float _LimitValue = 0.6f;
                
                //Round up the alpha color coming from the interpolator (to 1.0/256.0 steps)
                //The incoming alpha could have numerical instability, which makes it very sensible to
                //HDR color transparency blend, when it blends with the world's texture.
                const half alphaPrecision = half(0xff);
                const half invAlphaPrecision = half(1.0/alphaPrecision);
                IN.color.a = round(IN.color.a * alphaPrecision)*invAlphaPrecision;

                half4 originColor = tex2D(_MainTex, IN.texcoord);
                // 反向
                originColor.rgb = saturate(half3(1,1,1) - originColor.rgb);

                // 计算合并颜色，sprite乘以color
                half4 color = IN.color * (originColor + _TextureSampleAdd);
                
                #ifdef UNITY_UI_CLIP_RECT
                half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(IN.mask.xy)) * IN.mask.zw);
                color.a *= m.x * m.y;
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                // 获取屏幕坐标
                float2 ScreenUV = IN.vertex.xy / _CharaViewRTWidthHeight.xy;

                #ifdef _FOGOPENAllCHARAVIEW
                    // 这个是角色视野的颜色
                    float2 tFragmentPos = ScreenUV - _CharaViewOriginCharaPos;
                    float tMaxWidthHeight = max(_ScreenParams.x, _ScreenParams.y);
                    // 角色的移动位置，需要做换算,在屏幕rt中移动一定的位置，由于记录路径的RT宽或者高有放大，所以移动的0-1的uv坐标需要做相应的缩小
                    tFragmentPos.x = tFragmentPos.x * _ScreenParams.x / tMaxWidthHeight;
                    tFragmentPos.y = tFragmentPos.y * _ScreenParams.y / tMaxWidthHeight;
                    
                    // 乘以精度
                    tFragmentPos.xy *= _LimitValue;

                    // 获取角色在自己锚点上的RT的UV坐标
                    float2 charaUV = tFragmentPos + float2(0.5f, 0.5f);
                    float4 charaViewCol = tex2D(_CharaViewBlitCharaViewRT, charaUV);
                
                    // 视野内圈是1，视野外圈是0
                    // 方块内部a = 1, 方块外面a = 0
                    // 视野的开关，不能影响方块的边缘，也就是越是方块 a = 0的地方，就越不能影响了
                    float charaViewValue = charaViewCol.r;
                    // 关灯alpha，在IN.Color.a = 0 的时候，需要依靠视野圈柔化方块边缘
                    float closeLightAlpha = lerp(color.a, 1.0f, originColor.a * charaViewValue);
                    // 开灯alpha，在IN.Color.a = 1 的时候，不依靠视野圈柔化方块边缘，因为方块自身的Image边缘有柔化，所以视野圈不要影响到方块边缘柔化部分
                    float openLightAlpha = color.a;
                    if(originColor.a > 0.94f)
                    {
                         openLightAlpha = lerp(color.a, 1.0f, originColor.a * charaViewValue);
                    }
                    // Image透明度角色开灯光灯程度
                    #ifdef _FOGOPENPLAYERVIEW
                        float openLightValue = max(IN.color.a, _FogOpenPlayerIntensity);
                    #else
                        float openLightValue = IN.color.a;
                    #endif
                    color.a = lerp(closeLightAlpha, openLightAlpha, openLightValue);
                #endif
                
                #ifdef _FOGOPENPLAYERVIEW
                    float distance = LockPropotionDistance(ScreenUV, _FogOpenPlayerScreenPos.xy, _ScreenParams.y / _ScreenParams.x);
                    float viewWidth = 0.1f;
                    // 内圈是0，外圈是1
                    float distanceValue = smoothstep(_FogOpenPlayerIntensity - viewWidth , _FogOpenPlayerIntensity + viewWidth, distance);
                    // 内圈是1，外圈是0
                    distanceValue = saturate(1.0f - distanceValue);
                    // color.a = lerp(color.a, 1.0f, originColor.a * distanceValue);
                    color.a = lerp(color.a, 1.0f, min(originColor.a , distanceValue));
                #endif
                
                // 最终叠加计算
                color.rgb *= color.a;
                
                return color;
            }
        ENDCG
        }
    }
}
