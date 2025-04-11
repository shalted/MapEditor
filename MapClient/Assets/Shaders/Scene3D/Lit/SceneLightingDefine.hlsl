#ifndef SCENE_LIGHTING_DEFINE_INCLUDED
#define SCENE_LIGHTING_DEFINE_INCLUDED

#include "UnityCG.cginc"
#include "Packages/com.shiyue.combinedrawcall/ShaderLibrary/CombineDrawCallDefine.hlsl"

UNITY_DECLARE_TEX2D(_MainTex);
DEFINE_COMBINE_DC_PROP(half4, _MainTex_ST);
DEFINE_COMBINE_DC_PROP(half4, _Color);
DEFINE_COMBINE_DC_PROP(half, _MainTexSaturation);
DEFINE_COMBINE_DC_PROP(half, _MainTexValue);
DEFINE_COMBINE_DC_PROP(half, _MainTexContrast);
DEFINE_COMBINE_DC_PROP(half, _Cutoff);

DEFINE_COMBINE_DC_PROP(half, _AmbientSpecularScale);
UNITY_DECLARE_TEXCUBE(_AmbientSpecCube);

half4 GetMainTex(float2 uv)
{
	half4 mainTex = UNITY_SAMPLE_TEX2D(_MainTex, uv);
	mainTex *= ACCESS_COMBINE_DC_PROP(_Color);
	half grey = dot(mainTex.rgb, unity_ColorSpaceLuminance.rgb);
	half texValue = ACCESS_COMBINE_DC_PROP(_MainTexValue);
	half texSaturation = ACCESS_COMBINE_DC_PROP(_MainTexSaturation);
	half texContrast = ACCESS_COMBINE_DC_PROP(_MainTexContrast);
	mainTex.rgb = lerp(grey, mainTex.rgb * texValue, texSaturation);
	mainTex.rgb = lerp(half3(0.5, 0.5, 0.5), mainTex.rgb, texContrast);
    return mainTex;
}
half4 GetMainTexOnly(float2 uv)
{
	half4 mainTex = UNITY_SAMPLE_TEX2D(_MainTex, uv);
    return mainTex;
}


#ifdef USE_GLOBAL_SCENE_FADE
	UNITY_DECLARE_TEX2D_HALF(_LightmapFade0);
	UNITY_DECLARE_TEX2D(_ShadowmaskFade0);
	UNITY_DECLARE_TEX2D_HALF(_LightmapFade1);
	UNITY_DECLARE_TEX2D(_ShadowmaskFade1);
	UNITY_DECLARE_TEXCUBE(_FadeAmbientSpecCube);
	half _GlobalSceneFadeWeight;
	#define SHADOWMASK_INDEX_CHANNEL_MULTIPLE 10.0

	half4 SampleShadowmaskFade(half4 mask, float2 uv)
	{
		half4 texArray[2] = {
			UNITY_SAMPLE_TEX2D(_ShadowmaskFade0, uv),
			UNITY_SAMPLE_TEX2D(_ShadowmaskFade1, uv)
		};
		half index = round(mask.g * SHADOWMASK_INDEX_CHANNEL_MULTIPLE);
		return texArray[index];
	}
#endif

half4 SampleLightmap(half4 mask, float2 uv)
{
	half4 lightmap = UNITY_SAMPLE_TEX2D(unity_Lightmap, uv);
	#ifdef USE_GLOBAL_SCENE_FADE
		half4 texArray[2] = {
			UNITY_SAMPLE_TEX2D(_LightmapFade0, uv),
			UNITY_SAMPLE_TEX2D(_LightmapFade1, uv)
		};
		half index = round(mask.g * SHADOWMASK_INDEX_CHANNEL_MULTIPLE);
		half4 lightmapFade = texArray[index];
		lightmap = lerp(lightmap, lightmapFade, _GlobalSceneFadeWeight);
	#endif
	return lightmap;
}


#ifdef USE_DITHER_CROSSFADE
    #define APPLY_DITHER_CROSSFADE(vpos)  ApplyDitherCrossFade(vpos)
	float _DitherCrossFade;
    sampler2D unity_DitherMask;
    void ApplyDitherCrossFade(float2 vpos)
    {
        vpos /= 4; // the dither mask texture is 4x4
        float mask = tex2D(unity_DitherMask, vpos).a;
        //float sgn = _DitherCrossFade > 0 ? 1.0f : -1.0f;
        clip(_DitherCrossFade - mask);
    }
#else
    #define APPLY_DITHER_CROSSFADE(vpos)
#endif

#ifdef USE_WAVE_ANIM
    half _WaveSizeX, _WaveSizeZ;
    half _WaveAmount, _WaveSpeed;

	// Calculate a 4 fast sine-cosine pairs
	// val:     the 4 input values - each must be in the range (0 to 1)
	// s:       The sine of each of the 4 values
	// c:       The cosine of each of the 4 values
	void FastSinCos(float4 val, out float4 s, out float4 c) {
		val = val * 6.408849 - 3.1415927;
		// powers for taylor series
		float4 r5 = val * val;                  // wavevec ^ 2
		float4 r6 = r5 * r5;                        // wavevec ^ 4;
		float4 r7 = r6 * r5;                        // wavevec ^ 6;
		float4 r8 = r6 * r5;                        // wavevec ^ 8;

		float4 r1 = r5 * val;                   // wavevec ^ 3
		float4 r2 = r1 * r5;                        // wavevec ^ 5;
		float4 r3 = r2 * r5;                        // wavevec ^ 7;


													//Vectors for taylor's series expansion of sin and cos
		float4 sin7 = { 1, -0.16161616, 0.0083333, -0.00019841 };
		float4 cos8 = { -0.5, 0.041666666, -0.0013888889, 0.000024801587 };

		// sin
		s = val + r1 * sin7.y + r2 * sin7.z + r3 * sin7.w;

		// cos
		c = 1 + r5 * cos8.x + r6 * cos8.y + r7 * cos8.z + r8 * cos8.w;
	}

	void WavingVertPos(inout float4 vertex, half4 color)
	{
		float animWaveSpeed = _WaveSpeed * _Time.x;
		// MeshGrass v.color.a: 1 on top vertices, 0 on bottom vertices
		// _WaveAndDistance.z == 0 for MeshLit
		float waveAmount = color.a * _WaveAmount;

		float4 _waveXSize = float4(0.012, 0.02, 0.06, 0.024) * _WaveSizeX;
		float4 _waveZSize = float4 (0.006, .02, 0.02, 0.05) * _WaveSizeZ;
		float4 waveSpeed = float4 (0.3, .5, .4, 1.2) * 4;

		float4 _waveXmove = float4(0.012, 0.02, -0.06, 0.048) * 2;
		float4 _waveZmove = float4 (0.006, .02, -0.02, 0.1);

		float4 waves;
		waves = vertex.x * _waveXSize;
		waves += vertex.z * _waveZSize;

		// Add in time to model them over time
		waves += animWaveSpeed * waveSpeed;

		float4 s, c;
		waves = frac(waves);
		FastSinCos(waves, s, c);

		s = s * s;

		s = s * s;

		float lighting = dot(s, normalize(float4 (1, 1, .4, .2))) * .7;

		s = s * waveAmount;

		float3 waveMove = float3 (0, 0, 0);
		waveMove.x = dot(s, _waveXmove);
		waveMove.z = dot(s, _waveZmove);

		vertex.xz -= waveMove.xz * _WaveAmount;
	}
#endif

#ifdef USE_WAVE_ANIM
	#define TRANSFORM_WAVE_VERTEX(v, c) WavingVertPos(v, c)
#else
	#define TRANSFORM_WAVE_VERTEX(v, c)
#endif

#endif
