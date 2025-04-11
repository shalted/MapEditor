Shader "XianXia/Post Process"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    CGINCLUDE
	#include "UnityCG.cginc"

	sampler2D _MainTex;
	//float4 _MainTex_ST;
	float4 _MainTex_TexelSize;
	float4 _NormDistParam;

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };
	struct BaseV2F
	{
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
	};

	half4 SampleBoxMainTex(float2 uv, half offset) {
		half4 uv_offset = _MainTex_TexelSize.xyxy * half4(-offset, -offset, offset, offset);
		half4 col =
			tex2D(_MainTex, uv + uv_offset.xy) +
			tex2D(_MainTex, uv + uv_offset.zy) +
			tex2D(_MainTex, uv + uv_offset.xw) +
			tex2D(_MainTex, uv + uv_offset.zw);
		return col * 0.25h;
	}

	BaseV2F BaseVert(appdata v)
	{
		BaseV2F o;
		UNITY_INITIALIZE_OUTPUT(BaseV2F, o);
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.uv;
		return o;
	}
	fixed4 BaseFrag(BaseV2F i) : SV_Target
	{
		return tex2D(_MainTex, i.uv.xy);
	}

	//Down Sample 4
	struct DownSample4V2F
	{
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
		float4 uv1 : TEXCOORD1;
	};
	DownSample4V2F DownSample4Vert(appdata v)
	{
		DownSample4V2F o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.uv + _MainTex_TexelSize.xy * half2(1, 1);
		o.uv.zw = v.uv + _MainTex_TexelSize.xy * half2(1, -1);
		o.uv1.xy = v.uv + _MainTex_TexelSize.xy * half2(-1, -1);
		o.uv1.zw = v.uv + _MainTex_TexelSize.xy * half2(-1, 1);
		return o;
	}
	fixed4 DownSample4Frag(DownSample4V2F i) : SV_Target
	{
		half4 col = tex2D(_MainTex, i.uv.xy)
			+ tex2D(_MainTex, i.uv.zw)
			+ tex2D(_MainTex, i.uv1.xy)
			+ tex2D(_MainTex, i.uv1.zw);
		return col * 0.25;
	}

	//Blur
	sampler2D _BlurTex;
	float4 _BlurMaskRect;
	half _BlurMaskFadePixel;
	half _BlurGradientValue;
	struct BlurV2F
	{
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
		float4 uv1 : TEXCOORD1;
	};
	BlurV2F BlurHorizontalVert(appdata v)
	{
		BlurV2F o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.uv + float2(-_NormDistParam.y, 0);
		o.uv.zw = v.uv + float2(-_NormDistParam.x, 0);
		o.uv1.xy = v.uv + float2(_NormDistParam.x, 0);
		o.uv1.zw = v.uv + float2(_NormDistParam.y, 0);
		return o;
	}
    fixed4 BlurFrag (BlurV2F i) : SV_Target
	{
		half4 col = (tex2D(_MainTex, i.uv.xy) + tex2D(_MainTex, i.uv1.zw)) * _NormDistParam.w;
		col += (tex2D(_MainTex, i.uv.zw) + tex2D(_MainTex, i.uv1.xy)) * _NormDistParam.z;
        return col;
    }

	BlurV2F BlurVerticalVert(appdata v)
	{
		BlurV2F o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.uv + float2(0, -_NormDistParam.y);
		o.uv.zw = v.uv + float2(0, -_NormDistParam.x);
		o.uv1.xy = v.uv + float2(0, _NormDistParam.x);
		o.uv1.zw = v.uv + float2(0, _NormDistParam.y);
		return o;
	}
	fixed4 BlurApplyMaskFrag(BlurV2F i) : SV_Target
	{
		float2 uv = i.uv.xy;
		fixed4 col = tex2D(_MainTex, uv);
		fixed4 blur_col = tex2D(_BlurTex, uv);
		fixed2 inside = step(_BlurMaskRect.xy, uv) * step(uv, _BlurMaskRect.zw);
		half2 min_dist = min(abs(uv - _BlurMaskRect.xy), abs(uv - _BlurMaskRect.zw)) * _ScreenParams.xy;
		fixed v = lerp(0, inside.x * inside.y, min(min_dist.x, min_dist.y) / _BlurMaskFadePixel);
		return lerp(blur_col, col, saturate(v));
	}
	fixed4 BlurApplyGradientFrag(BlurV2F i) : SV_Target
	{
		float2 uv = i.uv.xy;
		fixed4 col = tex2D(_MainTex, uv);
		fixed4 blurCol = tex2D(_BlurTex, uv);
		float dist = distance(uv, float2(0.5, 0.5));
		fixed fade = pow(dist / 0.5, _BlurGradientValue);
		return lerp(col, blurCol, saturate(fade));
	}

	//Bloom
	sampler2D _BloomTex;
	sampler2D _BloomMaskTex;
	float4 _BloomTex_TexelSize;
	half4 _BloomSettings;
	float4 _BloomThreshold;
	half _BloomSampleScale;

	half4 QuadraticThreshold(half4 color, half threshold, half3 curve)
	{
		// Pixel brightness
		half br = max(max(color.r, color.g), color.b);

		// Under-threshold part: quadratic curve
		half rq = clamp(br - curve.x, 0.0, curve.y);
		rq = curve.z * rq * rq;

		// Combine and apply the brightness response curve.
		color *= max(rq, br - threshold) / max(br, 1.0e-4);

		return color;
	}
	half4 BloomPrefilterFrag(BaseV2F i) : SV_Target{
		half4 color = SampleBoxMainTex(i.uv.xy, 1);
		color = QuadraticThreshold(color, _BloomThreshold.x, _BloomThreshold.yzw);
		fixed4 maskCol = tex2D(_BloomMaskTex, i.uv.xy);
		color.rgb *= maskCol.rrr;
		return color;
	}
	half4 BloomUpSampleApply(BaseV2F i) : SV_Target {
		float2 uv = i.uv.xy;
		float4 d = _BloomTex_TexelSize.xyxy * float4(-1.0, -1.0, 1.0, 1.0) * (_BloomSampleScale * 0.5);
		half4 bloom;
		bloom = (tex2D(_BloomTex, uv + d.xy));
		bloom += (tex2D(_BloomTex, uv + d.zy));
		bloom += (tex2D(_BloomTex, uv + d.xw));
		bloom += (tex2D(_BloomTex, uv + d.zw));
		bloom *= 0.25;
		bloom.rgb *= _BloomSettings.rgb * _BloomSettings.w;

		half4 color = tex2D(_MainTex, uv);
		color.rgb = GammaToLinearSpace(color.rgb) + bloom.rgb;
		color.rgb = LinearToGammaSpace(color.rgb);
		return color;
	}
	fixed4 BloomDrawMaskRendererFrag(BaseV2F i) : SV_Target
	{
		return fixed4(0, 0, 0, 1);
	}

	//Color
	uniform half _color_s;
	uniform half _color_v;

	fixed4 ColorFrag(BaseV2F i) : SV_Target {
		fixed4 col = tex2D(_MainTex, i.uv.xy);
		col.rgb = col.rgb * _color_v;
		fixed grey = dot(col.rgb, unity_ColorSpaceLuminance.rgb);
		col.rgb = lerp(grey, col.rgb, _color_s);
		return col;
	}

	//Wave
	half4 _WaveParamTb;//x-->strength, y-->start dist, z-->end dist

	BaseV2F WaveVert (appdata v){
		BaseV2F o;
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv.xy = v.uv;
        o.uv.zw = (v.uv - 0.5f) * 2;
        return o;
    }
    fixed4 WaveFrag (BaseV2F i) : SV_Target {
        half dist = length(i.uv.zw);
        half distortion = saturate((dist - _WaveParamTb.z) / (_WaveParamTb.y - _WaveParamTb.z));
        distortion *= step(distortion, 0.99h);
		half2 uv_offset = sin((dist - _WaveParamTb.y) * _WaveParamTb.x) * 0.02h * distortion * i.uv.zw;
        half4 col = tex2D(_MainTex, i.uv.xy + uv_offset);
        col.rgb *= 1 - uv_offset.x * 5.0h;
        return col;
    }

	//Distortion Effect
	sampler2D _DistortionTex;
	float4 _DistortionTex_ST;
	half2 _DistortionValue;

	BaseV2F DistortionEffectVert(appdata v)
	{
		BaseV2F o;
		UNITY_INITIALIZE_OUTPUT(BaseV2F, o);
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xy = v.uv;
		o.uv.zw = TRANSFORM_TEX(v.uv, _DistortionTex);
		return o;
	}

	fixed4 DistortionEffectFrag(BaseV2F i) : SV_Target {
		fixed4 dis_col = tex2D(_DistortionTex, i.uv.zw);
		float2 tex_uv = i.uv.xy + (dis_col.rg * 2 - 1) * _DistortionValue * dis_col.a;
		fixed4 col = tex2D(_MainTex, tex_uv);
		return col;
	}

	//Motion Blur
	sampler2D _MotionBlurFilterTex;
	sampler2D _MotionBlurCacheTex;
	fixed _MotionBlurAlpha;

	fixed4 MotionBlurFilterFrag(BaseV2F i) : SV_Target {
		return fixed4(0, 0, 0, 0);
	}

	fixed4 MotionBlurBlendFrag(BaseV2F i) : SV_Target {
		fixed4 color = tex2D(_MainTex, i.uv.xy);
		fixed4 filter_col = tex2D(_MotionBlurFilterTex, i.uv.xy);
		color.a = lerp(0, _MotionBlurAlpha, filter_col.r);
		return color;
	}

	fixed4 MotionBlurFrag(BaseV2F i) : SV_Target {
		fixed4 tex_col = tex2D(_MainTex, i.uv.xy);
		fixed4 cache_col = tex2D(_MotionBlurCacheTex, i.uv.xy);
		fixed4 color = fixed4(lerp(tex_col.rgb, cache_col.rgb, step(0.01, cache_col.a)), 1);
		return color;
	}

	//Color Lookup
    sampler2D _LookupTex;
    float4 _LookupTex_TexelSize;
    half _LutLerpWeight;
	#define LUT_PIXEL_COUNT 32.0

    fixed4 ColorLookupFrag(BaseV2F i) : SV_Target
    {
        float maxColor = LUT_PIXEL_COUNT - 1.0;
        fixed4 col = saturate(tex2D(_MainTex, i.uv.xy));
        float halfColX = 0.5 / _LookupTex_TexelSize.z;
        float halfColY = 0.5 / _LookupTex_TexelSize.w;
        float threshold = maxColor / LUT_PIXEL_COUNT;

        float xOffset = halfColX + col.r * threshold / LUT_PIXEL_COUNT;
        float yOffset = halfColY + col.g * threshold;
        float cell = floor(col.b * maxColor);

        float2 lutPos = float2(cell / LUT_PIXEL_COUNT + xOffset, yOffset);
		fixed4 gradedCol = tex2D(_LookupTex, lutPos);
        return lerp(col, gradedCol, _LutLerpWeight);
    }

	ENDCG
    SubShader
    {
        Cull Back
		ZWrite Off
		ZTest Always

		pass{
			Name "BLIT"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment BaseFrag
			ENDCG
		}

		pass{
			Name "DOWN_SAMPLE_4"
			CGPROGRAM
			#pragma vertex DownSample4Vert
			#pragma fragment DownSample4Frag
			ENDCG
		}

		pass{
			Name "DOWN_SAMPLE_BOX"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment Frag
			half4 Frag(BaseV2F i) : SV_Target {
				return SampleBoxMainTex(i.uv.xy, 1);
			}
			ENDCG
		}

		pass {
			Name "UP_SAMPLE_BOX"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment Frag
			half4 Frag(BaseV2F i) : SV_Target {
				return SampleBoxMainTex(i.uv.xy, 0.5h);
			}
			ENDCG
		}

		pass {
			Name "BLUR_HORIZONTAL"
			CGPROGRAM
			#pragma vertex BlurHorizontalVert
			#pragma fragment BlurFrag
			ENDCG
		}

		pass {
			Name "BLUR_VERTICAL"
			CGPROGRAM
			#pragma vertex BlurVerticalVert
			#pragma fragment BlurFrag
			ENDCG
		}

		pass {
			Name "BLUR_APPLY_MASK"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment BlurApplyMaskFrag
			ENDCG
		}
		pass {
			Name "BLUR_APPLY_GRADIENT"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment BlurApplyGradientFrag
			ENDCG
		}

		pass {
			Name "BLOOM_PREFILTER"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment BloomPrefilterFrag
			ENDCG
		}
		pass {
			Name "BLOOM_DOWN_SAMPLE"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment Frag
			half4 Frag(BaseV2F i) : SV_Target{
				return SampleBoxMainTex(i.uv.xy, 1);
			}
			ENDCG
		}
		pass {
			Name "BLOOM_UP_SAMPLE"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment Frag
			half4 Frag(BaseV2F i) : SV_Target {
				half4 bloom = SampleBoxMainTex(i.uv.xy, _BloomSampleScale * 0.5);
				return bloom + tex2D(_BloomTex, i.uv.xy);
			}
			ENDCG
		}
		pass {
			Name "BLOOM_UP_SAMPLE_APPLY"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment BloomUpSampleApply
			ENDCG
		}
		pass {
			Name "BLOOM_DRAW_MASK_RENDERER"
			Cull Off
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment BloomDrawMaskRendererFrag
			ENDCG
		}

		pass {
			Name "COLOR"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment ColorFrag
			ENDCG
		}

		pass {
			Name "WAVE"
			CGPROGRAM
			#pragma vertex WaveVert
			#pragma fragment WaveFrag
			ENDCG
		}

		pass {
			Name "DISTORTION_EFFECT"
			CGPROGRAM
			#pragma vertex DistortionEffectVert
			#pragma fragment DistortionEffectFrag
			ENDCG
		}

		pass {
			Name "MOTION_BLUR_FILTER"
			Stencil
			{
				Ref [_Stencil]
				Comp [_StencilComp]
				Pass [_StencilOp]
			}
			ZTest Off
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment MotionBlurFilterFrag
			ENDCG
		}
		pass {
			Name "MOTION_BLUR_BLEND"
			Blend SrcAlpha OneMinusSrcAlpha, One Zero
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment MotionBlurBlendFrag
			ENDCG
		}
		pass {
			Name "MOTION_BLUR_APPLY"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment MotionBlurFrag
			ENDCG
		}
		pass {
			Name "LUT"
			CGPROGRAM
			#pragma vertex BaseVert
			#pragma fragment ColorLookupFrag
			ENDCG
		}
    }
}
