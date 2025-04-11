Shader "Hidden/RendererGlow/Process"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

	HLSLINCLUDE
	#include "UnityCG.cginc"

	sampler2D _MainTex;
	sampler2D _GlowTex;
	sampler2D _MaskTex;
	float4 _MainTex_TexelSize;
	half4 _GlowVecParam;
	fixed4 _GlowColor;

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };
	struct V2F
	{
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
	};
	struct SampleBoxV2F
	{
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
		float4 uv1 : TEXCOORD1;
	};
	struct SampleBoxBlendV2F
	{
		float4 pos : SV_POSITION;
		float4 uv : TEXCOORD0;
		float4 uv1 : TEXCOORD1;
		float2 source_uv : TEXCOORD2;
	};

	void TransformBoxUV(inout float4 uv, inout float4 uv1, float2 origin_uv, half scale)
	{
		uv.xy = origin_uv + _MainTex_TexelSize.xy * half2(1, 1) * scale;
		uv.zw = origin_uv + _MainTex_TexelSize.xy * half2(1, -1) * scale;
		uv1.xy = origin_uv + _MainTex_TexelSize.xy * half2(-1, -1) * scale;
		uv1.zw = origin_uv + _MainTex_TexelSize.xy * half2(-1, 1) * scale;
	}
	fixed4 SampleMainTexBoxColor(float4 uv, float4 uv1)
	{
		half4 col = tex2D(_MainTex, saturate(uv.xy))
			+ tex2D(_MainTex, saturate(uv.zw))
			+ tex2D(_MainTex, saturate(uv1.xy))
			+ tex2D(_MainTex, saturate(uv1.zw));
		return col * 0.25;
	}
	fixed4 SampleBoxFrag(SampleBoxV2F i) : SV_Target
	{
		return SampleMainTexBoxColor(i.uv, i.uv1);
	}

	//DownSampleBox
	SampleBoxV2F DownSampleBoxVert(appdata v)
	{
		SampleBoxV2F o;
		o.pos = UnityObjectToClipPos(v.vertex);
		TransformBoxUV(o.uv, o.uv1, v.uv, 1);
		return o;
	}
	//UpSampleBox
	SampleBoxV2F UpSampleBoxVert(appdata v)
	{
		SampleBoxV2F o;
		o.pos = UnityObjectToClipPos(v.vertex);
		TransformBoxUV(o.uv, o.uv1, v.uv, 0.5);
		return o;
	}
	//UpSampleBox Apply
	SampleBoxBlendV2F UpSampleBoxApplyVert(appdata v)
	{
		SampleBoxBlendV2F o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.source_uv = v.uv;
		TransformBoxUV(o.uv, o.uv1, v.uv, 0.5);
		return o;
	}
	fixed4 UpSampleBoxApplyFrag(SampleBoxBlendV2F i) : SV_Target
	{
		fixed4 mask_col = tex2D(_MaskTex, i.source_uv);
		fixed4 glow_col = SampleMainTexBoxColor(i.uv, i.uv1);
		fixed alpha = glow_col.r * _GlowColor.a;
		alpha = lerp(alpha, alpha * _GlowVecParam.x, step(0.01, mask_col.r));
		alpha = pow(alpha, _GlowVecParam.y);
		return fixed4(_GlowColor.rgb, alpha);
	}
	//Blend Blit
	V2F BlendBlitVert(appdata v)
	{
		V2F o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv.xyzw = v.uv.xyxy;
		return o;
	}
	fixed4 BlendBlitFrag(V2F i) : SV_Target
	{
		fixed4 color = tex2D(_MainTex, i.uv.xy);
		return color;
	}
	ENDHLSL


    SubShader
    {
        Cull Back
		ZWrite Off
		ZTest Off

		pass{
			Name "DOWN_SAMPLE_BOX"
			HLSLPROGRAM
			#pragma vertex DownSampleBoxVert
			#pragma fragment SampleBoxFrag
			ENDHLSL
		}

		pass {
			Name "UP_SAMPLE_BOX"
			Blend One One
			HLSLPROGRAM
			#pragma vertex UpSampleBoxVert
			#pragma fragment SampleBoxFrag
			ENDHLSL
		}
		pass {
			Name "UP_SAMPLE_BOX_APPLY"
			Blend SrcAlpha OneMinusSrcAlpha
			HLSLPROGRAM
			#pragma vertex UpSampleBoxApplyVert
			#pragma fragment UpSampleBoxApplyFrag
			ENDHLSL
		}
		pass {
			Name "BLEND_BLIT"
			Blend SrcAlpha OneMinusSrcAlpha
			HLSLPROGRAM
			#pragma vertex BlendBlitVert
			#pragma fragment BlendBlitFrag
			ENDHLSL
		}
    }
}
