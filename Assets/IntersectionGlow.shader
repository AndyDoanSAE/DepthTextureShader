Shader "CustomShader/IntersectionGlow"
{
    Properties
    {
        [HDR] _Color("Color", Color) = (1, 1, 1, 1)
        _DepthFactor("Depth Factor", float) = 1.0
        _DepthPow("Depth Pow", float) = 1.0

        [HDR] _EdgeColor("Edge Color", Color) = (1, 1, 1, 1)
        _IntersectionThreshold("Intersection threshold", Float) = 1
        _IntersectionPow("Pow", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            // ZTest always
            // ZWrite Off
            Cull Front

            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;
            };

            float4 _Color;
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            float _DepthFactor;
            fixed _DepthPow;
            float4 _EdgeColor;
            fixed _IntersectionThreshold;
            fixed _IntersectionPow;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.screenPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.screenPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = _Color;

                float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)));
                float depth = sceneZ - i.screenPos.z;

                fixed depthFading = saturate((abs(pow(depth, _DepthPow))) / _DepthFactor);
                col *= depthFading;

                fixed intersect = saturate((abs(depth)) / _IntersectionThreshold);
                col += _EdgeColor * pow(1 - intersect, 4) * _IntersectionPow;

                return col;
            }
            ENDCG
        }
    }
}
