Shader "antpaw/ConeLight"
{
    Properties
    {
        [HDR] _Color1 ("Color 1", Color) = (1,1,1,0)      //Receive input from a fixed Color
        [HDR] _Color2 ("Color 2", Color) = (1,1,1,1)      //Receive input from a fixed Color
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
        LOD 100

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            fixed4 _Color1;
            fixed4 _Color2;

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (
                float4 vertex : POSITION, // vertex position input
                float2 uv : TEXCOORD0
            )
            {
                v2f o;
                o.pos = UnityObjectToClipPos(vertex);
                o.uv = uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return lerp(_Color1, _Color2, i.uv.y);
            }
            ENDCG
        }
    }
}
