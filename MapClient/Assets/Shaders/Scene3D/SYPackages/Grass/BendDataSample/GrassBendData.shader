Shader "ShiYue/Tools/GrassBendData"
{
    Properties
    {
        
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            ZWrite Off
            Blend One OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #include "UnityCG.cginc"

            //half2 _WeightAndRange;
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float4, _WeightAndRange)
            UNITY_INSTANCING_BUFFER_END(Props)
            struct appdata
            { 
                
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 positionWS : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            float3 GetPivotPos()
	        {
	        	return float3(unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w);
	        }

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o); // necessary only if you want to access instanced properties in the fragment Shader.
                float4 weightAndRange = UNITY_ACCESS_INSTANCED_PROP(Props, _WeightAndRange);
                o.vertex = UnityObjectToClipPos(v.vertex * weightAndRange.y);
                o.uv = v.uv;
                o.positionWS = mul(UNITY_MATRIX_M,v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {         
                UNITY_SETUP_INSTANCE_ID(i);
                //UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float4 weightAndRange = UNITY_ACCESS_INSTANCED_PROP(Props, _WeightAndRange);
                //return weightAndRange;
                half dis = (1 - distance(0,abs(i.uv -0.5) * 2))* weightAndRange.x;
                half2 dir = normalize(i.positionWS - GetPivotPos()).xz ;
                dir = (dir + 1) * 0.5;
                return fixed4(dir.x,dis,dir.y,dis);
            }
            ENDCG
        }
    }
}
