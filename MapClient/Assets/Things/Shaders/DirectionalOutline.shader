// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "XianXia/DirectionalOutline"
{
	Properties
	{
		_Dir("Dir", Vector) = (30,-5,50,0)
		_Distance("Distance", Float) = 5
		_Offset_Unit("Offset_Unit", Float) = 500
		_Offset_Factor("Offset_Factor", Float) = 500
		_Color("Color", Color) = (0,0,0,1)
	}
	
	SubShader
	{
		Tags { "RenderType"="Transparent" }
		LOD 100
		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Front
		ColorMask RGBA
		ZWrite Off
		ZTest LEqual
		Offset [_Offset_Factor] , [_Offset_Unit]
		
		

		Pass
		{
			Name "Unlit"
			
			Stencil {
				Ref 15
				Comp NotEqual
				Pass Replace
			}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			

			struct appdata
			{
				float4 vertex : POSITION;
				
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			uniform half _Offset_Unit;
			uniform half _Offset_Factor;
			uniform float _Distance;
			uniform float3 _Dir;
			uniform float4 _Color;
			
			v2f vert ( appdata v )
			{
				v2f o;

				float3 normalizeResult10 = normalize( _Dir );
				float4 transform15 = mul(unity_WorldToObject,float4( normalizeResult10 , 0.0 ));
				
				
				v.vertex.xyz += ( ( _Distance / 100.0 ) * transform15 ).xyz;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				fixed4 finalColor;
				
				finalColor = _Color;
				return finalColor;
			}
			ENDCG
		}
	}
}
