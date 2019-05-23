//
// Kino/Bloom v2 - Bloom filter for Unity
//
// Copyright (C) 2015, 2016 Keijiro Takahashi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
Shader "Hidden/Kino/Bloom"
{
    Properties
    {
        _MainTex("", 2D) = "" {}
        _BaseTex("", 2D) = "" {}
    }

    SubShader
    {
        // 0: Prefilter
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma multi_compile _ UNITY_COLORSPACE_GAMMA
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag_prefilter
            #pragma target 3.0

            sampler2D _MainTex;
            sampler2D _BaseTex;
            float2 _MainTex_TexelSize;
            float2 _BaseTex_TexelSize;
            half4 _MainTex_ST;
            half4 _BaseTex_ST;

            float _PrefilterOffs;
            half _Threshold;
            half3 _Curve;
            float _SampleScale;
            half _Intensity;


            v2f_img vert(appdata_img v)
            {
                v2f_img o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = UnityStereoScreenSpaceUVAdjust(v.texcoord, _MainTex_ST);
                // o.uvMain = UnityStereoScreenSpaceUVAdjust(v.texcoord, _MainTex_ST);
                // o.uvBase = UnityStereoScreenSpaceUVAdjust(v.texcoord, _BaseTex_ST);
                return o;
            }


            // Clamp HDR value within a safe range
            half3 SafeHDR(half3 c) { return min(c, 65000); }
            half4 SafeHDR(half4 c) { return min(c, 65000); }

            half Brightness(half3 c)
            {
                return max(max(c.r, c.g), c.b);
            }

            half4 EncodeHDR(float3 rgb)
            {
                return half4(rgb, 0);
            }

            float3 DecodeHDR(half4 rgba)
            {
                return rgba.rgb;
            }

            half3 UpsampleFilter(float2 uv)
            {
                // 4-tap bilinear upsampler
                float4 d = _MainTex_TexelSize.xyxy * float4(-1, -1, +1, +1) * (_SampleScale * 0.5);

                half3 s;
                s  = DecodeHDR(tex2D(_MainTex, uv + d.xy));
                s += DecodeHDR(tex2D(_MainTex, uv + d.zy));
                s += DecodeHDR(tex2D(_MainTex, uv + d.xw));
                s += DecodeHDR(tex2D(_MainTex, uv + d.zw));

                return s * (1.0 / 4);
            }

            half4 frag_prefilter(v2f_img i) : SV_Target
            {
                float2 uv = i.uv + _MainTex_TexelSize.xy * _PrefilterOffs;

                half4 s0 = SafeHDR(tex2D(_MainTex, uv));
                half3 m = s0.rgb;

                // Pixel brightness
                half br = Brightness(m);

                // Under-threshold part: quadratic curve
                half rq = clamp(br - _Curve.x, 0, _Curve.y);
                rq = _Curve.z * rq * rq;

                // Combine and apply the brightness response curve.
                m *= max(rq, br - _Threshold) / max(br, 1e-5);

                half4 x = EncodeHDR(m);
                // return x;


                half3 blur = UpsampleFilter(i.uv);
                half3 cout = x.rgb + blur * _Intensity;
                return half4(cout, 0.6);

            }

            ENDCG

        }
    }
}
