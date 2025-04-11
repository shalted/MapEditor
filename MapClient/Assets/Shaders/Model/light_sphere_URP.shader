// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Sphere"
{
	Properties
	{
		[Header(____________BaseColor___________)]
		_BaseColor("基础颜色", Color) = (0,0,0,0)
		_BasePower("基础颜色的强度", Float) = 4.84
		
		[Space(20)]
		[Header(_____________Edge______________)]
		_EdgeMin("内边", Range(0,1)) = 0
		_EdgeMax("外边", Range(0,1)) = 0
		_EdgeColor("边缘颜色", Color) = (0.3568628,0.8352942,0.7686275,1)
		
		[Space(20)]
		[Header(__________AddTex_____________)]
		_AddTex("球心光效", 2D) = "black" {}
		_AddPower("光效范围", Float) = 4.84
		_AddColor("光效颜色", Color) = (1,1,1,0)
		_AddSpeedX("X轴流动速度", Float) = 0
		_AddSpeedY("Y轴流动速度", Float) = 0
		
		[Space(20)]
		[Header(___________StarTex______________)]
		_StarTex("星星纹理", 2D) = "black" {}
		_StarPower("星星强度", Float) = 4.84
		[HDR]_StarColor("星星颜色", Color) = (1,1,1,0)
		_StarTillingX("星星X轴的Tilling", Float) = 0
		_StarTillingY("星星Y轴的Tilling", Float) = 0
		
		[Spcae(20)]
		[Header(________NoiseTex(RG)__StarMaskTex(B)____________)]
		_NoiseAndStarMaskTex("采样扰动纹理（RG通道）---星星遮罩（B通道）", 2D) = "white" {}
		_NoiseIntensity("采样扰动强度", Float) = 0
		_NoiseAndStarMaskSpeedX("X轴流动速度", Float) = 0
		_NoiseAndStarMaskSpeedY("Y轴流动速度", Float) = 0
		
		
		
		[Spcae(20)]
		[Header(__________SpecularReflection__________)]
		_Matcap("MatCap", 2D) = "white" {}
		_MatcapIntensity("MatCap强度", Range( 0 , 1)) = 0
		_MatcapColor("MatCap颜色", Color) = (0,0,0,0)

	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Blend Off
		AlphaToMask Off
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		
		
		
		Pass
		{
			
			Tags { "LightMode" = "UniversalForward" }
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"


			struct appdata
			{
				float4 vertex : POSITION;
				half3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				half4 normal : NORMAL;
				float3 worldPos : TEXCOORD0;
				float4 screenPos : TEXCOORD1;
				float4 texcoord : TEXCOORD2;
			};



			TEXTURE2D(_Matcap);	SAMPLER(sampler_Matcap);
			TEXTURE2D(_StarTex);	SAMPLER(sampler_StarTex);
			TEXTURE2D(_AddTex);	SAMPLER(sampler_AddTex);
			TEXTURE2D(_NoiseAndStarMaskTex);	SAMPLER(sampler_NoiseAndStarMaskTex);
            CBUFFER_START(UnityPerMaterial)
			uniform half _StarTillingX;
			uniform half _StarTillingY;
			uniform half4 _StarColor;
			uniform half _StarPower;
			uniform half _AddSpeedX;
			uniform half _AddSpeedY;
			uniform half4 _AddTex_ST;

			//.......
			uniform half4 _NoiseAndStarMaskTex_ST;
			uniform half _NoiseIntensity;
			uniform half _NoiseAndStarMaskSpeedX;
			uniform half _NoiseAndStarMaskSpeedY;
			uniform half4 _AddColor;
			uniform half _AddPower;
			uniform half _BasePower;
			uniform half4 _BaseColor;
			uniform half4 _EdgeColor;
			uniform half _EdgeMin;
			uniform half _EdgeMax;
			uniform half _MatcapIntensity;
			uniform half4 _MatcapColor;
			CBUFFER_END
 
			
			v2f vert ( appdata v )
			{
				v2f o;

                float3 positionWS = TransformObjectToWorld(v.vertex);
                float4 positionCS = TransformWorldToHClip(positionWS);

				float4 ase_clipPos = positionCS;
				float4 screenPos = ComputeScreenPos(ase_clipPos);//屏幕空间的位置
				half3 ase_worldNormal = TransformObjectToWorldNormal(v.normal);
				
				o.screenPos = screenPos;
				o.normal = float4(ase_worldNormal,0);
				o.texcoord= float4(v.texcoord.xy,0,0);
				o.vertex = positionCS;
                o.worldPos = positionWS;

				return o;
			}
			
			half4 frag (v2f i ) : SV_Target
			{
				half4 finalColor;
				float3 WorldPosition = i.worldPos;

				
				
				float4 screenPos = i.screenPos;
				float4 screenPosNorm = screenPos / screenPos.w;
				screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
				half2 screenPosNormUV = half2(screenPosNorm.x , screenPosNorm.y);//屏幕采样坐标
				
				float3 worldViewDir = normalize(_WorldSpaceCameraPos.xyz - WorldPosition);
				half3 worldNormal = i.normal.xyz;
				
				half fresnelNdotV = dot( worldNormal, worldViewDir );
				half NdotV= saturate( fresnelNdotV );//法线和视线的点乘法
				
				half2 AddSpeed = (half2(_AddSpeedX , _AddSpeedY));
				half2 uv_AddTex = i.texcoord.xy * _AddTex_ST.xy + _AddTex_ST.zw;
				half2 AddUV = (_Time.y * AddSpeed+ uv_AddTex);//光效的UV采样坐标
				
				half2 NoiseAndStarMaskSpeed = (half2(_NoiseAndStarMaskSpeedX , _NoiseAndStarMaskSpeedY));
				half2 uv_NoiseTex = i.texcoord.xy * _NoiseAndStarMaskTex_ST.xy + _NoiseAndStarMaskTex_ST.zw;
				
				half2 NoiseAndStarMaskUV = (_Time.y * NoiseAndStarMaskSpeed + uv_NoiseTex);//NoiseAndStarMask的UV坐标
				half4 NoiseAndStarMaskColor = SAMPLE_TEXTURE2D( _NoiseAndStarMaskTex, sampler_NoiseAndStarMaskTex,NoiseAndStarMaskUV );//此处采样NoiseAndStarMask贴图
				//计算UV偏移
				half2 UVoffset = (half2(NoiseAndStarMaskColor.r , NoiseAndStarMaskColor.g));
				
				half fresnel =  pow( 1.0 - NdotV, 1 );
				
				half Edgesmoothstep = smoothstep( _EdgeMin , _EdgeMax , fresnel );//边缘插值系数


				half2 StarTilling = half2(_StarTillingX , _StarTillingY);
				half4 starColor=SAMPLE_TEXTURE2D(_StarTex,sampler_StarTex,( StarTilling * screenPosNormUV )).r* _StarColor * saturate( pow( NdotV , _StarPower ) ) * NoiseAndStarMaskColor.b;//计算星星颜色

				half4 addColor=SAMPLE_TEXTURE2D( _AddTex,sampler_AddTex, ( AddUV + ( UVoffset * _NoiseIntensity ) ) ).r * _AddColor * saturate( pow( NdotV , _AddPower ) ) ;//计算光效颜色

				half4 baseColor=saturate( pow( saturate(NdotV) , _BasePower ) ) * _BaseColor;//计算基础色

				float2 matCapUV=(mul(UNITY_MATRIX_V, half4( worldNormal , 0.0 ) ).xy *0.5 + 0.5);//计算MatcapUV
				half4 matCapColor=SAMPLE_TEXTURE2D( _Matcap,sampler_Matcap, matCapUV ).r * _MatcapIntensity * _MatcapColor ;//计算MatCap颜色
				finalColor = lerp( starColor+addColor+baseColor+matCapColor, _EdgeColor , Edgesmoothstep);//最终颜色和边缘颜色插值
				
				
				return finalColor;
			}
			ENDHLSL
		}
	}
}