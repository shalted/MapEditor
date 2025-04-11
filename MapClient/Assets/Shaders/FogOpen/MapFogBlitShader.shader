Shader "Hidden/MapFogBlitShader"
{
    Properties
    {
        _BlitTexture ("Blit Texture", 2D) = "white" {}
        
        // 当前角色的屏幕坐标位置
        _CharaViewNowCharaPos("_CharaViewNowCharaPos", Vector) = (0,0,0,0)
        // 角色数量
        _CharaViewCharaNum("_CharaViewCharaNum", Int) = 0
        // 最大支持5个角色的位置
        _CharaViewCharaPos0("_CharaViewCharaPos0", Vector)= (0,0,0,0)
        _CharaViewCharaPos1("_CharaViewCharaPos1", Vector)= (0,0,0,0)
        _CharaViewCharaPos2("_CharaViewCharaPos2", Vector)= (0,0,0,0)
        _CharaViewCharaPos3("_CharaViewCharaPos3", Vector)= (0,0,0,0)
        _CharaViewCharaPos4("_CharaViewCharaPos4", Vector)= (0,0,0,0)
        // 最大支持5个角色的范围
        _CharaViewCharaRange0("_CharaViewCharaRange0", Float)= 0
        _CharaViewCharaRange1("_CharaViewCharaRange1", Float)= 0
        _CharaViewCharaRange2("_CharaViewCharaRange2", Float)= 0
        _CharaViewCharaRange3("_CharaViewCharaRange3", Float)= 0
        _CharaViewCharaRange4("_CharaViewCharaRange4", Float)= 0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100

        Pass
        {
            Name "MapFogBlit"
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Fragment
            #pragma multi_compile_fragment _ _LINEAR_TO_SRGB_CONVERSION
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            // Core.hlsl for XR dependencies
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/DebuggingFullscreen.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            SAMPLER(sampler_BlitTexture);

            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = input.texcoord;

                half4 col = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_BlitTexture, uv);

                #ifdef _LINEAR_TO_SRGB_CONVERSION
                col = LinearToSRGB(col);
                #endif

                #if defined(DEBUG_DISPLAY)
                half4 debugColor = 0;

                if(CanDebugOverrideOutputColor(col, uv, debugColor))
                {
                    return debugColor;
                }
                #endif

                return col;
            }
            ENDHLSL
        }

        Pass
        {
            Name "MapFogCharaViewBlit"
            Blend One Zero
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert2
            #pragma fragment Fragment
            #pragma multi_compile_fragment _ _LINEAR_TO_SRGB_CONVERSION
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            // Core.hlsl for XR dependencies
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/DebuggingFullscreen.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            TEXTURE2D(_CharaViewBlitCharaViewRT);
            SAMPLER(sampler_CharaViewBlitCharaViewRT);

            // 开启角色视野的时候，角色的屏幕坐标位置
            float2 _CharaViewOriginCharaPos;
            uint _CharaViewCharaNum;
            float2 _CharaViewCharaPos0;
            float2 _CharaViewCharaPos1;
            float2 _CharaViewCharaPos2;
            float2 _CharaViewCharaPos3;
            float2 _CharaViewCharaPos4;
            float _CharaViewCharaRange0;
            float _CharaViewCharaRange1;
            float _CharaViewCharaRange2;
            float _CharaViewCharaRange3;
            float _CharaViewCharaRange4;

            Varyings Vert2(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            #if SHADER_API_GLES
                float4 pos = input.positionOS;
                float2 uv  = input.uv;
            #else
                float4 pos = GetFullScreenTriangleVertexPosition(input.vertexID);
                float2 uv  = GetFullScreenTriangleTexCoord(input.vertexID);
            #endif

                output.positionCS = pos;
                output.texcoord   = uv;
                return output;
            }
            
            // 锁比例的距离计算
            float LockPropotionDistance(float2 pos1, float2 pos2, float percent)
            {
                return sqrt(pow(pos1.x - pos2.x, 2) + pow((pos1.y - pos2.y) * percent, 2));
            }

            void SetCharaView()
            {
                
            }
            
            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = input.texcoord;

                // rt精度
                float _LimitValue = 0.6f;
                
                // 这个是画布上的颜色
                float4 canvasCol = SAMPLE_TEXTURE2D_X(_CharaViewBlitCharaViewRT, sampler_CharaViewBlitCharaViewRT, uv);
                float canvasValue = canvasCol.r;
                
                // 笔刷的颜色强度，角色的视野，刷颜色地方是白色
                float viewBrushValue = 0.0f;
                float2 charaViewPosList[5] = {_CharaViewCharaPos0, _CharaViewCharaPos1, _CharaViewCharaPos2, _CharaViewCharaPos3, _CharaViewCharaPos4};
                float charaViewRangeList[5] = {_CharaViewCharaRange0, _CharaViewCharaRange1, _CharaViewCharaRange2, _CharaViewCharaRange3, _CharaViewCharaRange4};
                float tMaxWidthHeight = max(_ScreenParams.x, _ScreenParams.y);
                for(uint i = 0; i < _CharaViewCharaNum; i++)
                {
                    // 角色位置
                    float2 charaViewPos = charaViewPosList[i].xy - _CharaViewOriginCharaPos.xy;
                    
                    // 角色的移动位置，需要做换算,在屏幕rt中移动一定的位置，由于记录路径的RT宽或者高有放大，所以移动的0-1的uv坐标需要做相应的缩小
                    charaViewPos.x = charaViewPos.x * _ScreenParams.x / tMaxWidthHeight;
                    charaViewPos.y = charaViewPos.y * _ScreenParams.y / tMaxWidthHeight;
                    // 乘以精度
                    charaViewPos.xy *= _LimitValue;
                    
                    float2 charaViewUV = float2(0.5f, 0.5f) + charaViewPos;
                    // 角色范围
                    float charaRange = charaViewRangeList[i] * _LimitValue;
                    
                    // 视野圈
                    float distance = LockPropotionDistance(uv, charaViewUV, 1.0f);
                    // 视野圈过渡区
                    float viewWidth = 0.01f;
                    
                    // 圈内为0，圈外为1
                    float distanceValue = smoothstep(charaRange - viewWidth , charaRange + viewWidth, distance);
                    
                    // 圈内为白色1，圈外为保留自身颜色
                    viewBrushValue = lerp(1.0f, viewBrushValue, distanceValue);

                    // 采用渐变强度
                    float softViewBrushValue = saturate(viewBrushValue * 0.1f);

                    // 如果叠加渐变强度后，画布上的颜色深于笔刷强度，就取渐变笔刷强度
                    if(canvasValue + softViewBrushValue > viewBrushValue)
                    {
                        softViewBrushValue = saturate(viewBrushValue - canvasValue);
                    }

                    // 执行叠加
                    canvasValue = canvasValue + softViewBrushValue;
                }
                
                // 返回混合颜色
                float4 resCol = float4(canvasValue, canvasValue, canvasValue, 1.0f);
                
                // 直接返回反向后的笔刷强度
                return resCol;
            }
            ENDHLSL
        }

        Pass
        {
            Name "MapFogFinalOutCharaViewBlit"
            Blend One Zero
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex Vert2
            #pragma fragment Fragment
            #pragma multi_compile_fragment _ _LINEAR_TO_SRGB_CONVERSION
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            // Core.hlsl for XR dependencies
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/DebuggingFullscreen.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            
            SAMPLER(sampler_BlitTexture);
            TEXTURE2D(_CharaViewBlitCharaViewRT);
            SAMPLER(sampler_CharaViewBlitCharaViewRT);

            // 开启角色视野的时候，角色的屏幕坐标位置
            float2 _CharaViewOriginCharaPos;
            
            Varyings Vert2(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

            #if SHADER_API_GLES
                float4 pos = input.positionOS;
                float2 uv  = input.uv;
            #else
                float4 pos = GetFullScreenTriangleVertexPosition(input.vertexID);
                float2 uv  = GetFullScreenTriangleTexCoord(input.vertexID);
            #endif

                output.positionCS = pos;
                output.texcoord   = uv;
                return output;
            }
            
            half4 Fragment(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = input.texcoord;

                // 角色视野精度
                float _LimitValue = 0.6f;
                
                // 这个是迷雾的颜色
                float4 fogCol = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_BlitTexture, uv);
                float fogColValue = fogCol.r;

                // 这个是角色视野的颜色
                float2 tFragmentPos = uv - _CharaViewOriginCharaPos;
                float tMaxWidthHeight = max(_ScreenParams.x, _ScreenParams.y);
                // 角色的移动位置，需要做换算,在屏幕rt中移动一定的位置，由于记录路径的RT宽或者高有放大，所以移动的0-1的uv坐标需要做相应的缩小
                tFragmentPos.x = tFragmentPos.x * _ScreenParams.x / tMaxWidthHeight;
                tFragmentPos.y = tFragmentPos.y * _ScreenParams.y / tMaxWidthHeight;

                // 乘以精度
                tFragmentPos.xy *= _LimitValue;
                
                float2 charaUV = tFragmentPos + float2(0.5f, 0.5f);
                
                float4 charaViewCol = SAMPLE_TEXTURE2D_X(_CharaViewBlitCharaViewRT, sampler_CharaViewBlitCharaViewRT, charaUV);
                float charaViewValue = charaViewCol.r;

                // 迷雾扣掉角色视野
                fogColValue = fogColValue + charaViewValue;
                
                // 返回混合颜色
                float4 resCol = float4(fogColValue, fogColValue, fogColValue, 1.0f);
                
                // 直接返回反向后的笔刷强度
                return resCol;
            }
            ENDHLSL
        }
    }
}
