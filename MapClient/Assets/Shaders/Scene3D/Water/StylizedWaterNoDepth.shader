Shader "ShiYue/StylizedWaterNoDepth"
{
	Properties
	{
        _WaterShallowColor("浅水区颜色", Color) = (0.7,0.8,0.9,1) 
		_WaterDeepColor("深水区颜色", Color) = (0.1,0.5,0.7,1)   
        _DepthRange("深度范围",float) = 0.5   
        _SideAlpha("边缘过渡",Range(0,16)) = 0

        // [Header(Depth)]
        // [Toggle(_DEPTHTEX_ON)]_Depth("启用自定义深度图",Float)=0
        _DepthTex ("深度贴图", 2D) = "white"{}
    	_TexPos   ("深度贴图位置偏移", Vector) = (0,0,0,0)
        // _DepthPos("深度图坐标",Vector)=(0,0,0,0)

		[Header(Specular)]
        //[CustomLightDir]_LightDir("主光方向",Vector)=(0,0,0,1)
        _SpecularRange("高光范围",float)=64
        _SpecularOffest("高光发散",float)=1
		_SpecularFactor("高光粒度", Range(0 , 1)) = 0.95
        _SpecularSmooth("高光平滑", Range(0 ,0.5)) = 0
		_SpecularColor("高光颜色",  Color) = (1,1,1,1)   
		_LightAngle("光照角度",Vector) = (1,1,1,1)

		[Header(Bump)]
		_BumpTex("法线贴图", 2D) = "white"{}
		_BumpStrength("法线强度", Range(0.0, 6.0)) = 1.0
		_BumpDirection("法线流动方向(XY)", Vector) = (0,0,0,0)
		// _BumpTiling("法线平铺(2 wave)", Vector) = (0.01,0.01,0.013,0.013)

        //_Length("波形(XY:方向和长度)", Vector) = (0,0,0,0)
        //_MatInt("波形强度",Range(0, 1)) = 0

        [Header(Reflect)]
		[NoScaleOffset]_Skybox("反射球", CUBE) = "white"{}
		_SkyBoxColor ("反射球颜色", Color) = (1,1,1,1)
        _CubeMapRotate("旋转反射球", Range(0,360)) = 0
        //_DistancesAtten("距离衰减", Range(0, 1)) = 0
        //_DistancesSmooth("衰减平滑",Range(0.1,0.5))=0.5
        [Toggle(USE_REFLECTION)]_UseReflection("是否开启水面倒影", Float) = 0
        [HideInInspector]_ScreenReflectionTex("_ScreenReflectionTex", 2D) = "white" {}
        _ReflectionAlpha("水面倒影 强度", Range(0.01, 1)) = 0.3
        _ReflectionNoiseTiling("水面倒影 扰动缩放", Float) = 20
        _ReflectionNoiseParams("水面倒影 扰动(xy强度，zw速度)", Vector) = (0.5, 0.5, -1, 1)
        [Header(Caustics)]
        [NoScaleOffset]_CausticsTex("焦散贴图",2D) = "black"{}
        [HDR] _CausticsColor("焦散颜色",Color) = (1,1,1,1)  
        _CausticsRange("焦散范围",float) = 0.5 
        _CausticsSide("焦散大小",float) = 10  
        _CausticsIntensity("焦散强度", Range(0, 5)) = 0.5 
        _CausticsSpeed("焦散速度", float) = 0.1   

        [Header(Foam)]
        _FoamColor("浪花颜色", Color) = (1,1,1,1)   
        _FoamTex("浪花贴图",2D) = "white"{}   
        _FoamWidth("浪花宽度",Range(0.001,8)) = 1    
        _FoamSpeed("浪花速度",float) = 0.1   
        _FoamDensity("浪花密度",Range(0,16)) =4    
        _FoamRange("浪花形状",Range(0.01,1)) =0.2  
        _FoamSmooth("浪花平滑",Range(0,0.5))=0
	    [HideInInspector]_CameraPos ("相机位置", Vector) = (0,0,0,0)
	    [HideInInspector]_ZTest ("深度测试", float) = 4
        _CloudMap ("云阴影", 2D) = "black"{}
        _CloudMove ("云流动速度", Vector) = (0,0,0,0)
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "ObjectType" = "Water" }
		ZTest [_ZTest]
       	ZWrite off
       	Cull back
       	Blend SrcAlpha OneMinusSrcAlpha 

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

            #pragma multi_compile_local _ USE_REFLECTION
			#pragma shader_feature_local _ _ADJUSTVIEWDIR
			#pragma shader_feature_local _ _ADJUSTDEPTH
            #pragma target 3.0
			#include "UnityCG.cginc"
			#include "../../Scene3D/Fog/ModelComputeFogLibrary.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldPos:TEXCOORD0;
	            float3 normalWS:TEXCOORD1;
				float3 tangentWS:TEXCOORD2;
				float3 binormalWS:TEXCOORD3;

	            float4 scrPos:TEXCOORD4;
				#ifdef USE_REFLECTION
                float2 refNoiseUV : TEXCOORD6;
                float3 refViewPos : TEXCOORD7;
                #endif
			};
			
			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
			sampler2D _GlobalReflectionTex;
			sampler2D _BumpTex;
			sampler2D _CausticsTex;
	        sampler2D _FoamTex;
			samplerCUBE _Skybox;
            sampler2D _DepthTex;
            float4 _TexPos;

			float4 _CameraPos;
	        float4 _BumpTex_ST;
	        float4 _FoamTex_ST;
			
	        half4 _WaterShallowColor;
	        half4 _WaterDeepColor;
			half4 _CausticsColor;
			half4 _SkyBoxColor;
	        half _DepthRange;
	        half _SideAlpha;
			sampler2D _ScreenReflectionTex;
            half _ReflectionAlpha;
            half _ReflectionNoiseTiling;
            half4 _ReflectionNoiseParams;
	        // half _DistancesAtten;
	        // half _DistancesSmooth;

	        half _SpecularRange;
	        half _SpecularOffest;
			half _SpecularFactor;
	        half _SpecularSmooth;
			half4 _SpecularColor;
			float4 _LightAngle;

			half4 _BumpDirection;
			half _BumpStrength;
			
	        half4 _FoamColor;
	        half _FoamSpeed;
	        half _FoamWidth;
	        half _FoamAlpha;
	        half _FoamDensity;
	        half _FoamRange;	
	        half _FoamSmooth;
			
            half _CausticsRange;
            half _CausticsSide;
            half _CausticsIntensity;
            half _CausticsSpeed;
			
	        half _CubeMapRotate;

			float4 PackedUV(float2 sourceUV, float2 speed)
			{
				float2 uv1 = sourceUV.xy + _Time.y * speed;
				float2 uv2 = (sourceUV.xy * 0.5) + (_Time.y * speed);
			    return float4(uv1.xy, uv2.xy);
			}
			
			half3 RotateFunction(half RotateValue, half3 Target)      //旋转cubemap的函数
			{
			    half rotation_cube = RotateValue * UNITY_PI / 180;
			    half cos2 = cos(rotation_cube);
			    half sin2 = sin(rotation_cube);
			    half2x2 m_rotate_cube = half2x2(cos2, -sin2, sin2, cos2);
			    half2 redlect_dir_rotate = mul(Target.xz, m_rotate_cube);    //旋转xz平面
			    Target = half3(redlect_dir_rotate.x, Target.y, redlect_dir_rotate.y);   //y值不变
			    return Target;
			}

			half3 PerPixelNormal(sampler2D bumpMap, half2 coords,half2 speed, half bumpStrength)
			{
			    float4 uvs = PackedUV(coords,speed);
				
				half3 worldNormal = half3(0, 0, 0);
				worldNormal += UnpackNormalWithScale(tex2D(bumpMap, uvs.xy), bumpStrength);
				worldNormal += UnpackNormalWithScale(tex2D(bumpMap, uvs.zw), bumpStrength);
				//half2 bump = (UnpackNormal(tex2D(bumpMap, uvs.xy)).xy + UnpackNormal(tex2D(bumpMap, uvs.zw)).xy) * 0.5;

				// half3 worldNormal = half3(0, 0, 0);
				// worldNormal.xz = bump.xy * bumpStrength;
				// worldNormal.y = 1;
				
				return worldNormal * 0.5f;
			}
			
			float3x3 GetTBN(float4 tangentOS, float3 normalOS)
			{
				float sign = tangentOS.w;
				
				float3 tangentWS   = UnityObjectToWorldDir(tangentOS);
				float3 normalWS    = UnityObjectToWorldNormal(normalOS);
				float3 binormalWS  = normalize(cross(normalWS, tangentWS)) * sign;
			
				float3x3 TBN = float3x3(
					tangentWS,
					binormalWS,
					normalWS
				);
			
				return TBN;
			
				// You should do :
				// float3 normalDir = normalize(mul(normalData, tbn));
			}
			
			float3 TBNToNormalWS(float4 tangentOS, float3 normalOS, float3 normalTS)
			{
				float3 tangentWS   = UnityObjectToWorldDir(tangentOS);
				float3 normalWS    = UnityObjectToWorldNormal(normalOS);
				float sgn = tangentOS.w;
						
				float3 binormalWS  = cross(normalWS, tangentWS) * sgn;
			
				normalWS = mul(normalTS, float3x3(tangentWS, binormalWS, normalWS));
			
				return normalWS;
			}

    //         half4 OrthoDepth(float4 scrPos, float depth)
    //         {
				// float2 screenPos= scrPos .xy / scrPos .w;
				//
				// float rawDepth = tex2D(_CameraDepthTexture, screenPos).r;
    //             #if UNITY_REVERSED_Z
    //                 rawDepth = 1.0 - rawDepth;
    //             #endif
				//
    //             float near = _ProjectionParams.y;
    //             float far = _ProjectionParams.z;
    //             float ortho = (far - near) * rawDepth + near;
    //             depth = lerp(depth, ortho, unity_OrthoParams.w);
    //             float deltaDepth = depth - scrPos.z;
    //             
    //             deltaDepth = min(_DepthRange, deltaDepth) / _DepthRange;
    //             if(deltaDepth > 0.99)
	   //              deltaDepth = 0;
    //             return float4(deltaDepth, deltaDepth, deltaDepth, 1);
    //         }

			float GetDepthOfOrthoCamera(float3 positionWS)
			{
				float selfDepth = _TexPos.y - positionWS.y;

				float2 uv = (positionWS.xz - _TexPos.xz) * rcp(_TexPos.w * 2) + float2(0.5, 0.5);
				float targetDepth = tex2D(_DepthTex, uv);

				return targetDepth;
				//return abs(selfDepth - targetDepth);
			}

			half3 ReflectionGI(float2 uv)
			{
			    half3 GI = tex2D(_GlobalReflectionTex, uv).rgb;
			    
			    return GI;
			}

			float3 SampleCaustics(float3 depthPos, float2 time, float tiling)
			{
				//Planar depth projection
				float3 caustics1 = tex2D(_CausticsTex, depthPos.xz* tiling + (time.xy )).rgb;
			    float3 caustics2 = tex2D(_CausticsTex, (depthPos.xz* tiling * 0.8) -(time.xy)).rgb;
				float3 caustics = min(caustics1, caustics2);
				
				return caustics;
			}

			float3 ReconstructViewPos(float4 screenPos, float origDepth)
			{
				float4 ndcPos = (screenPos / screenPos.w) * 2 - 1; //屏幕坐标--->ndc坐标变换公式
				float far = _ProjectionParams.z; //获取投影信息的z值，代表远平面距离
				float3 clipVec = float3(ndcPos.x, ndcPos.y, ndcPos.z * -1) * far; //裁切空间下的视锥顶点坐标
				float3 viewVec = mul(unity_CameraInvProjection, clipVec.xyzz).xyz;
				
				float depth = Linear01Depth(origDepth); //转换为线性深度
				float3 viewPos = viewVec * depth; //获取实际的观察空间坐标（插值后）
				return mul(unity_CameraToWorld, float4(viewPos, 1)).xyz; //观察空间-->世界空间坐标
			}
		
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex.xyz);
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex).xyz;

				float3x3 tbn = GetTBN(v.tangent, v.normal);
				
				o.tangentWS  = tbn[0].xyz;
				o.binormalWS = tbn[1].xyz;
				o.normalWS   = tbn[2].xyz;

	            o.scrPos = ComputeScreenPos(o.vertex);
	            o.scrPos.z = -UnityObjectToViewPos(v.vertex.xyz).z;//计算深度
	            #ifdef USE_REFLECTION
                o.refNoiseUV = v.vertex.xz * _ReflectionNoiseTiling * 0.01 + _Time.x * _ReflectionNoiseParams.zw;
                o.refViewPos = UnityObjectToViewPos(v.vertex);
                #endif
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
			#if _ADJUSTVIEWDIR
				float3 viewVector = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
				float3 halfVector = normalize(normalize(_LightAngle)+viewVector);
			#else
				float3 viewVector = normalize(_CameraPos.xyz - i.worldPos);
				float3 halfVector = normalize(normalize(_LightAngle)+viewVector);
			#endif
	            float2 wuv=0.1*i.worldPos.xz*_BumpTex_ST.xy;

	            //是否启用深度图
	            float depthrange = 0;
	            float deltaDepth = 0;
				
	            // 控制浅水区和深水区的范围
				float2 screenPos = i.scrPos .xy / i.scrPos .w;
				float origDepth = tex2D(_CameraDepthTexture, screenPos).r;
				float depth = LinearEyeDepth(origDepth);
				
		    	deltaDepth = depth - i.scrPos.z;//地面深度减去水面深度，得到深度的差值，用来判断水的深浅
				deltaDepth = GetDepthOfOrthoCamera(i.worldPos);
	            depthrange = min(_DepthRange, deltaDepth) / _DepthRange;
				
			#if _ADJUSTDEPTH
				return half4(depthrange.xxx, 1); 
			#endif

			    half4 bascol= lerp(_WaterShallowColor, _WaterDeepColor, depthrange);
				
				float3 worldNormal = normalize(PerPixelNormal(_BumpTex, wuv,_BumpDirection.xy, _BumpStrength));

				//法线控制
				worldNormal = normalize(mul(worldNormal, float3x3(
						i.tangentWS,
						i.binormalWS,
						i.normalWS
						)
					)
				);
				
				//#if _CAUSTICS_ON
            	float3 opaqueWorldPos = ReconstructViewPos(i.scrPos, origDepth);
                float3 caustics = SampleCaustics(i.worldPos, _CausticsSpeed * _Time.x, _CausticsSide) * _CausticsIntensity * (1 - depthrange);
				caustics *= _CausticsColor.rgb;

                float causticsMask = min(_CausticsRange, deltaDepth) /_CausticsRange;//深度越小越接近1
                bascol = lerp(bascol + float4(caustics,0), bascol, causticsMask);
                //#endif
				
				//反射
				viewVector = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
				float3 refrV = refract((viewVector), float3(0,0,1), 1 / 1.33f);  
	            refrV = RotateFunction(_CubeMapRotate, refrV);
	            half4 ref = texCUBE(_Skybox, float4(normalize(worldNormal + refrV), 0));
				half frensel = 1 - saturate(dot(worldNormal, viewVector));
	            bascol.rgb = bascol.rgb + ref.rgb * _SkyBoxColor.rgb * _SkyBoxColor.a * frensel;

				//高光
				worldNormal = normalize(worldNormal + half3(0, _SpecularOffest, 0));
				half spec = pow(max(0, dot(worldNormal, normalize(halfVector))), _SpecularRange) * _SpecularColor.w;
				spec = smoothstep(max(0,_SpecularFactor-_SpecularSmooth),min(1,_SpecularFactor+_SpecularSmooth), spec);
				bascol.rgb += _SpecularColor.xyz * spec;

				#ifdef USE_REFLECTION
                half2 refNoiseTex = tex2D(_BumpTex, i.refNoiseUV).rg - 0.5;
                i.refViewPos.xy += refNoiseTex * _ReflectionNoiseParams.xy * 0.1;
                float4 refClipPos = UnityViewToClipPos(i.refViewPos);
                float4 refScreenPos = ComputeNonStereoScreenPos(refClipPos);
                half4 reflectTex = tex2Dproj(_ScreenReflectionTex, UNITY_PROJ_COORD(refScreenPos));
                half refAlpha = saturate(reflectTex.a * _ReflectionAlpha);
                bascol.rgb = reflectTex.rgb * refAlpha + bascol.rgb * (1 - refAlpha);
                #endif

	            //岸边浪花
	            half wave = 1 - min(_FoamWidth, deltaDepth) / _FoamWidth;
	            float foamspeed = _Time.x * _FoamSpeed;
	            float2 foamuv = wuv * _FoamTex_ST.xy + _FoamTex_ST.zw ;
	            half foamnoise = tex2D(_FoamTex, foamuv).r;
	            half foam = foamnoise*wave*saturate(sin((deltaDepth + foamspeed) * _FoamDensity * UNITY_PI));
	            foam = smoothstep(max(0, _FoamRange - _FoamSmooth), min(1, _FoamRange + _FoamSmooth), foam) * _FoamColor.a;
				bascol.rgb = bascol.rgb + _FoamColor.rgb * foam;

	            half alpha = saturate(bascol.a*saturate(deltaDepth/max(0.001,_SideAlpha)));//+foam*saturate(deltaDepth/0.001));		    //防止边缘消除边缘白点		
				ComputeModelFog(i.vertex.z, i.worldPos.y, bascol.rgb);
				ComputeCloudShadow(i.worldPos, bascol.rgb);
				return half4(bascol.rgb, alpha);
			}
			ENDCG
		}
	}
	 CustomEditor "StylizedWaterGUI"
}
