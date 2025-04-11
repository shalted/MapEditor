Shader "XianXia/Effect/WaterFalls"
{
	Properties
	{
		_DifffuseColor("底色", Color) = (0.4386792,0.8874071,1,0)
		_BaseTex("底波纹贴图", 2D) = "white" {}
		_Mask1("底波纹遮罩", 2D) = "white" {}
		[HDR]_Base1("底波纹颜色1", Color) = (0.111205,0.3661847,0.4622642,0)
		_BrightLight1("底波纹强度1", Float) = 0
		[HDR]_Base2("底波纹颜色2", Color) = (0.2812389,0.734131,0.754717,0)
		_BrightLight2("底波纹强度2", Float) = 0
		_FlowUV1("第一层平铺和流动速度", Vector) = (0,0,0,0)
		_FlowUV2("第二层平铺和流动速度", Vector) = (0,0,0,0)
		_HighLiightTex("高光层形状", 2D) = "white" {}
		_Mask2("高光层遮罩", 2D) = "white" {}
		[HDR]_WaveColor("高光层颜色", Color) = (1,1,1,0)
		_WaveTillingAndSpeed("高光层平铺和速度", Vector) = (0,0,0,0)
		//_Opacity("整体透明度", Range( 0 , 1)) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
	}
	
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
	    LOD 100
		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			Name "Unlit"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"
			#include "../../Scene3D/Fog/ModelComputeFogLibrary.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float2 uv : TEXCOORD1;
			};

			uniform half _BrightLight1;
			uniform half4 _Base1;
			uniform sampler2D _BaseTex;
			uniform float4 _BaseTex_ST;
			uniform half4 _FlowUV1;
			uniform sampler2D _Mask1;
			uniform half4 _Mask1_ST;
			uniform half4 _FlowUV2;
			uniform half4 _Base2;
			uniform half _BrightLight2;
			uniform sampler2D _Mask2;
			uniform half4 _Mask2_ST;
			uniform half4 _WaveColor;
			uniform sampler2D _HighLiightTex;
			uniform float4 _HighLiightTex_ST;
			uniform half4 _WaveTillingAndSpeed;
			uniform half4 _DifffuseColor;
			uniform half _Opacity;
			
			v2f vert ( appdata v )
			{
				v2f o;
				o.uv.xy = v.texcoord.xy;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				float2 uv1 = i.uv * _BaseTex_ST.xy + _BaseTex_ST.zw;
				float2 uv2 = i.uv * _HighLiightTex_ST.xy + _HighLiightTex_ST.zw;
				fixed4 finalColor;
				half2 FlowUVOffest1 = (half2(_FlowUV1.z , _FlowUV1.w));
				half2 FlowUVTilling1 = (half2(_FlowUV1.x , _FlowUV1.y));
				half2 texCoord1 = uv1 * FlowUVTilling1 + float2( 0,0 );
				half2 panner1 = ( _Time.y * FlowUVOffest1 + texCoord1);
				
				float2 uv_Mask1 = i.uv.xy * _Mask1_ST.xy + _Mask1_ST.zw;
				half4 Mask1 = tex2D( _Mask1, uv_Mask1 );
				
				half2 FlowUVOffest2 = (half2(_FlowUV2.z , _FlowUV2.w));
				half2 FlowUVTilling2 = (half2(_FlowUV2.x , _FlowUV2.y));
				half2 texCoord2 = uv1 * FlowUVTilling2 + float2( 0,0 );
				half2 panner2 = ( _Time.y * FlowUVOffest2 + texCoord2);
				
				float2 uv_Mask2 = i.uv.xy * _Mask2_ST.xy + _Mask2_ST.zw;
				half4 Mask2 =  tex2D( _Mask2, uv_Mask2 );
				
				half2 WaveTilling = (half2(_WaveTillingAndSpeed.x , _WaveTillingAndSpeed.y));
				half2 WaveSpeed= (half2(_WaveTillingAndSpeed.z , _WaveTillingAndSpeed.w));
				half2 texCoord3 = uv2 * WaveTilling + ( WaveSpeed * _Time.y );
				half2 panner3 = ( 1.0 * _Time.y * float2( 0,0 ) + texCoord3);
				
				float4 Color1 =  float4(( _BrightLight1 * ( ( _Base1 * tex2D( _BaseTex, panner1 ).r ) * Mask1.r )).rgb,( _BrightLight1 * ( ( _Base1 * tex2D( _BaseTex, panner1 ).r ) * Mask1.r )).r);
				float4 Color2 = float4((( Mask1.r * ( tex2D( _BaseTex, panner2 ).r * _Base2 ) ) * _BrightLight2 ).rgb,(( Mask1.r * ( tex2D( _BaseTex, panner2 ).r * _Base2 ) ) * _BrightLight2 ).r);
				float4 Color3 = float4(( Mask2.r * ( _WaveColor * tex2D( _HighLiightTex, panner3 ).r ) ).rgb,( Mask2.r * ( _WaveColor * tex2D( _HighLiightTex, panner3 ).r ) ).r);
				half4 color = Color1 + Color2 + Color3 + _DifffuseColor;
				ComputeModelFog(i.vertex.z, i.worldPos.y, color.rgb);
				return color;
			}
			ENDCG
		}
	}
	Fallback Off
}
