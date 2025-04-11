Shader "XianXia/UnlitTransparent" {
    Properties {
		_Color("_Color", Color) = (1, 1, 1, 1)
        _MainTex("_MainTex", 2D) = "white" {}
		[HideInInspector]_ProceduralColor ("Procedural Color", Color) = (1, 1, 1, 1)
    }

    SubShader {
    	Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

    	ZWrite Off
    	Blend SrcAlpha OneMinusSrcAlpha

    	Pass {
    		CGPROGRAM
    			#pragma vertex vert
    			#pragma fragment frag

                #include "../CGInclude/GameCGDefines.cginc"

    			struct appdata_t {
    				float4 vertex : POSITION;
    				float2 texcoord : TEXCOORD0;
    			};
    			struct v2f {
    				float4 vertex : SV_POSITION;
    				half2 texcoord : TEXCOORD0;
    			};

    			v2f vert (appdata_t v)
    			{
    				v2f o;
    				o.vertex = UnityObjectToClipPos(v.vertex);
    				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
    				return o;
    			}

    			fixed4 frag (v2f i) : SV_Target
    			{
    				fixed4 col = tex2D(_MainTex, i.texcoord) * _Color;
					col *= _ProceduralColor;
                    #if IS_UNIT_ON
                        col.rgb *= _GameUnitColor;
                    #endif
    				return col;
    			}
    		ENDCG
    	}
    }
}
