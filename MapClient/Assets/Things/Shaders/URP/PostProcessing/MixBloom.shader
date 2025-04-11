Shader "ShiYue/PostProcessing/MixBloom"
{
    Properties
    {
        [PerRendererData]_MainTex ("Texture", 2D) = "white" { }
    	
    	_BloomThreshold("Threshold",Float)=1
    	_BloomIntensity("Intensity",Float)=1
    	_BloomMixRatio("Mixing",Vector)=(0.3,0.3,0.26,0.15)
    	_BloomClampMax("ClampMax",Float)=20
    	_TexelRadius("Radius",Float)=20

    }
    HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    	#include "Assets/Things/Shaders/URP/PostProcessing/Common.hlsl"

       #pragma multi_compile _ _CUSTOMRATIO_ON
       #pragma multi_compile _ _ALPHAMASK_ON
        #define ThresholdKnee 0.5

        TEXTURE2D(_MainTex);
    	SAMPLER(sampler_MainTex);

        TEXTURE2D(_BloomBuffterTex0);
    	SAMPLER(sampler_BloomBuffterTex0);
    
        TEXTURE2D(_BloomBuffterTex1);
    	SAMPLER(sampler_BloomBuffterTex1);
    
        TEXTURE2D(_BloomBuffterTex2);
    	SAMPLER(sampler_BloomBuffterTex2);

		TEXTURE2D(_RoleBloomMaskTexture);
    	SAMPLER(sampler_RoleBloomMaskTexture);
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_TexelSize;
        half4 _BloomMixRatio;
        half _BloomThreshold;
        half _BloomIntensity;
        half _BloomClampMax;
		half _BackGroudBloomIntensity;
        half _TexelRadius;

        CBUFFER_END

    
        half4 EncodeHDR(half3 color)
        {
        #if _USE_RGBM
            half4 outColor = EncodeRGBM(color);
        #else
            half4 outColor = half4(color, 1.0);
        #endif

        #if UNITY_COLORSPACE_GAMMA
            return half4(sqrt(outColor.xyz), outColor.w); // linear to γ
        #else
            return outColor;
        #endif
        }

        half3 DecodeHDR(half4 color)
        {
        #if UNITY_COLORSPACE_GAMMA
            color.xyz *= color.xyz; // γ to linear
        #endif

        #if _USE_RGBM
            return DecodeRGBM(color);
        #else
            return color.xyz;
        #endif
        }

    	inline float Brightness(float3 c) {
			return max(c.r, max(c.g, c.b));
		}
    
	    struct Attribute
		{
		    float4 positionOS       : POSITION;
		    float2 uv               : TEXCOORD0;
		    UNITY_VERTEX_INPUT_INSTANCE_ID
		};
    
		struct Varying
		{
		    float4 positionCS : SV_POSITION;
		    float2 texcoord   : TEXCOORD0;
		    UNITY_VERTEX_OUTPUT_STEREO
		};
    
	    Varying FullscreenVert(Attribute input)
		{
		    Varying output;
		    UNITY_SETUP_INSTANCE_ID(input);
		    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

		#if _USE_DRAW_PROCEDURAL
		    output.positionCS = GetQuadVertexPosition(input.vertexID);
		    output.positionCS.xy = output.positionCS.xy * float2(2.0f, -2.0f) + float2(-1.0f, 1.0f); //convert to -1..1
		    output.uv = GetQuadTexCoord(input.vertexID) * _ScaleBias.xy + _ScaleBias.zw;
		#else
		    output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
		    output.texcoord = input.uv;
		#endif

		    return output;
		}
    
        half4 FragExtract(Varying input): SV_Target
        {
        	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);
        	
			half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
        	color.a = Brightness(color.rgb);
		    color.rgb = max(color.rgb - _BloomThreshold.xxx, 0);
        	//#if _ALPHAMASK_ON
        	//half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
        	//half mask =max(SAMPLE_TEXTURE2D(_RoleBloomMaskTexture, sampler_RoleBloomMaskTexture, uv).r,_BackGroudBloomIntensity);
        	//color = min(_BloomClampMax, color)*mask;
			//#else
        	//half3 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).rgb;
        	//color = min(_BloomClampMax, color);
        	//#endif
        	//
            //half brightness = Max3(color.r, color.g, color.b);
            //half softness = clamp(brightness - _BloomThreshold + ThresholdKnee, 0.0, 2.0 * ThresholdKnee);
            //softness = (softness * softness) / (4.0 * ThresholdKnee + 1e-4);
        	//half multiplier = max(brightness - _BloomThreshold, softness) / max(brightness, 1e-4);  //saturate(brightness - _BloomThreshold);//
            //color *= multiplier;
        	
            // Clamp colors to positive once in prefilter. Encode can have a sqrt, and sqrt(-x) == NaN. Up/Downsample passes would then spread the NaN.
            //color = max(color, 0);
        	return EncodeHDR(color.rgb);
        }

        half4 FragBlurH(Varying input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float texelSize = _MainTex_TexelSize.x*_TexelRadius;
            float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);

            // 9-tap gaussian blur on the downsampled source
            half3 c0 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(texelSize * 4.0, 0.0)));
            half3 c1 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(texelSize * 3.0, 0.0)));
            half3 c2 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(texelSize * 2.0, 0.0)));
            half3 c3 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(texelSize * 1.0, 0.0)));
            half3 c4 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv                               ));
            half3 c5 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(texelSize * 1.0, 0.0)));
            half3 c6 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(texelSize * 2.0, 0.0)));
            half3 c7 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(texelSize * 3.0, 0.0)));
            half3 c8 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(texelSize * 4.0, 0.0)));

            // half3 color = c0 * 0.01621622 + c1 * 0.05405405 + c2 * 0.12162162 + c3 * 0.19459459
            //             + c4 * 0.22702703
            //             + c5 * 0.19459459 + c6 * 0.12162162 + c7 * 0.05405405 + c8 * 0.01621622;

        	half w0=0.01621622/(1.0+Luminance(c0));
        	half w1=0.05405405/(1.0+Luminance(c1));
        	half w2=0.12162162/(1.0+Luminance(c2));
        	half w3=0.19459459/(1.0+Luminance(c3));
        	half w4=0.22702703/(1.0+Luminance(c4));
         	half w5=0.19459459/(1.0+Luminance(c5));
        	half w6=0.12162162/(1.0+Luminance(c6));
        	half w7=0.05405405/(1.0+Luminance(c7));
        	half w8=0.01621622/(1.0+Luminance(c8));
        	
        	half3 color=(c0*w0+c1*w1+c2*w2+c3*w3+c4*w4+c5*w5+c6*w6+c7*w7+c8*w8)/(w0+w1+w2+w3+w4+w5+w6+w7+w8);

            return EncodeHDR(color);
        }

        half4 FragBlurV(Varying input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float texelSize = _MainTex_TexelSize.y*_TexelRadius;
            float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);

            // 9-tap gaussian blur on the downsampled source
            half3 c0 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(0.0,texelSize * 4.0)));
            half3 c1 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(0.0,texelSize * 3.0)));
            half3 c2 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(0.0,texelSize * 2.0)));
            half3 c3 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(0.0,texelSize * 1.0)));
            half3 c4 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv                              ));
            half3 c5 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(0.0,texelSize * 1.0)));
            half3 c6 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(0.0,texelSize * 2.0)));
            half3 c7 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(0.0,texelSize * 3.0)));
            half3 c8 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(0.0,texelSize * 4.0)));

            // half3 color = c0 * 0.01621622 + c1 * 0.05405405 + c2 * 0.12162162 + c3 * 0.19459459
            //             + c4 * 0.22702703
            //             + c5 * 0.19459459 + c6 * 0.12162162 + c7 * 0.05405405 + c8 * 0.01621622;

        	half w0=0.01621622/(1.0+Luminance(c0));
        	half w1=0.05405405/(1.0+Luminance(c1));
        	half w2=0.12162162/(1.0+Luminance(c2));
        	half w3=0.19459459/(1.0+Luminance(c3));
        	half w4=0.22702703/(1.0+Luminance(c4));
         	half w5=0.19459459/(1.0+Luminance(c5));
        	half w6=0.12162162/(1.0+Luminance(c6));
        	half w7=0.05405405/(1.0+Luminance(c7));
        	half w8=0.01621622/(1.0+Luminance(c8));
        	
        	half3 color=(c0*w0+c1*w1+c2*w2+c3*w3+c4*w4+c5*w5+c6*w6+c7*w7+c8*w8)/(w0+w1+w2+w3+w4+w5+w6+w7+w8);

            return EncodeHDR(color);
        }

        half4 FragBloom(Varying input) : SV_Target
        {
        	UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);

            half3 c0 = DecodeHDR(SAMPLE_TEXTURE2D_X(_BloomBuffterTex0, sampler_BloomBuffterTex0, uv));
        	half3 c1 = DecodeHDR(SAMPLE_TEXTURE2D_X(_BloomBuffterTex1, sampler_BloomBuffterTex1, uv));
        	half3 c2 = DecodeHDR(SAMPLE_TEXTURE2D_X(_BloomBuffterTex2, sampler_BloomBuffterTex2, uv));
            half3 c3 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv));

            
        	half3 color = 0;
        	#if _CUSTOMRATIO_ON
                    color =c0*_BloomMixRatio.x+c1*_BloomMixRatio.y+c2*_BloomMixRatio.z+c3*_BloomMixRatio.w;        	
        	#else
        	        color =c0*0.2+c1*0.55+c2*0.15+c3*0.3;
        	#endif
        	
        	return EncodeHDR(color);
        }

         half4 FragBlurG(Varying input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float2 texelSize = _MainTex_TexelSize.xy*_TexelRadius;
            float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);

            // 9-tap gaussian blur on the downsampled source
            half3 c0 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv));
            half3 c1 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + texelSize*float2(0,1)));
            half3 c2 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + texelSize*float2(1,0)));
            half3 c3 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + texelSize*float2(0,-1)));
            half3 c4 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + texelSize*float2(-1,0)));
            half3 c5 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + texelSize*float2(1,1)));
            half3 c6 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + texelSize*float2(-1,-1)));
            half3 c7 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + texelSize*float2(-1,1)));
            half3 c8 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + texelSize*float2(1,-1)));

            half3 color = c0 * 0.25 + c1 * 0.125 + c2 * 0.125 + c3 * 0.125+ c4 * 0.125
                        + c5 * 0.0625 + c6 * 0.0625 + c7 * 0.0625 + c8 * 0.0625;

            return EncodeHDR(color);
        }

        half4 FragBlurHLow(Varying input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float texelSize = _MainTex_TexelSize.x*_TexelRadius;
            float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);


            // Optimized bilinear 5-tap gaussian on the same-sized source (9-tap equivalent)
            half3 c0 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(texelSize * 3.23076923,0.0)));
            half3 c1 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(texelSize * 1.38461538,0.0)));
            half3 c2 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv                                     ));
            half3 c3 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(texelSize * 1.38461538,0.0)));
            half3 c4 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(texelSize * 3.23076923,0.0)));

            //https://zhuanlan.zhihu.com/p/525500877
        	float w0=0.07027027/(1.0+Luminance(c0));
        	float w1=0.31621622/(1.0+Luminance(c1));
        	float w2=0.22702703/(1.0+Luminance(c2));
        	float w3=0.31621622/(1.0+Luminance(c3));
        	float w4=0.07027027/(1.0+Luminance(c4));

        	half3 color = c0 * w0 + c1 * w1+ c2 * w2
            + c3 * w3 + c4 * w4;

        	color/=(w0+w1+w2+w3+w4);
        	
            // half3 color = c0 * 0.07027027 + c1 * 0.31621622
            //             + c2 * 0.22702703
            //             + c3 * 0.31621622 + c4 * 0.07027027;

            return EncodeHDR(color);
        }
    
        half4 FragBlurVLow(Varying input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            float texelSize = _MainTex_TexelSize.y*_TexelRadius;
            float2 uv = UnityStereoTransformScreenSpaceTex(input.texcoord);

            // Optimized bilinear 5-tap gaussian on the same-sized source (9-tap equivalent)
            half3 c0 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(0.0, texelSize * 3.23076923)));
            half3 c1 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv - float2(0.0, texelSize * 1.38461538)));
            half3 c2 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv                                      ));
            half3 c3 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(0.0, texelSize * 1.38461538)));
            half3 c4 = DecodeHDR(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, uv + float2(0.0, texelSize * 3.23076923)));

            // half3 color = c0 * 0.07027027 + c1 * 0.31621622
            //             + c2 * 0.22702703
            //             + c3 * 0.31621622 + c4 * 0.07027027;

        	float w0=0.07027027/(1.0+Luminance(c0));
        	float w1=0.31621622/(1.0+Luminance(c1));
        	float w2=0.22702703/(1.0+Luminance(c2));
        	float w3=0.31621622/(1.0+Luminance(c3));
        	float w4=0.07027027/(1.0+Luminance(c4));

        	half3 color = c0 * w0 + c1 * w1+ c2 * w2
            + c3 * w3 + c4 * w4;

        	color/=(w0+w1+w2+w3+w4);

            return EncodeHDR(color);
        }
        
        ENDHLSL
	
		SubShader
 		{
 			Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
			Cull Off ZWrite Off ZTest Always
 			
		Pass  //1
		{
			Name "Bloom Prefilter"
			
			HLSLPROGRAM
			#pragma vertex FullscreenVert
			#pragma fragment FragExtract
			ENDHLSL
		}

		Pass  //1
		{
            Name "Bloom Blur Horizontal"
			
			HLSLPROGRAM
			#pragma vertex FullscreenVert
			#pragma fragment FragBlurHLow
			ENDHLSL
		}
    	
		Pass  //2
		{
            Name "Bloom Blur Vertical"
			
			HLSLPROGRAM
			#pragma vertex FullscreenVert
			#pragma fragment FragBlurVLow
			ENDHLSL
		}
 			
 		Pass  //3
 		{	
 			Name "Bloom Blur Combine"	
 			HLSLPROGRAM
 			#pragma vertex FullscreenVert
 			#pragma fragment FragBloom
 			ENDHLSL
 		}			
 			
		Pass  //4
		{
			Name "Bloom Blur Gaussian"
			HLSLPROGRAM
			#pragma vertex FullscreenVert
			#pragma fragment FragBlurG
			ENDHLSL
		}
 			
 		Pass  //5
		{
            Name "Bloom Blur Horizontal 2"
			
			HLSLPROGRAM
			#pragma vertex FullscreenVert
			#pragma fragment FragBlurH
			ENDHLSL
		}
    	
		Pass  //6
		{
            Name "Bloom Blur Vertical 2"
			
			HLSLPROGRAM
			#pragma vertex FullscreenVert
			#pragma fragment FragBlurV
			ENDHLSL
		}
 			

		
    }
}