Shader "CustomShader/IntersectionGlow"
{
    Properties
    {
        [HDR] _Color("Color", Color) = (1, 1, 1, 1) // HDR to allow emmisive colours

        _DepthFactor("Depth Factor", float) = 1.0   // Controls the fade length
        _DepthPow("Depth Power", float) = 1.0       // Controls the smoothness of the fade

        [HDR] _EdgeColor("Edge Color", Color) = (1, 1, 1, 1)
        _IntersectionThreshold("Intersection Threshold", Float) = 1 // Intersection thickness
        _IntersectionPow("Intersection Power", Float) = 1           // Intersection smoothness
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "IgnoreProjector"="True" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha // SrcAlpha is Source Alpha; OneMinusSrcAlpha for grey vignette, One to remove
        LOD 100

        Pass
        {
            ZTest always
            ZWrite Off
            Cull Front // Removes the front faces

            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert     // Vertex runs on every single vertex
            #pragma fragment frag   // Fragment runs on every single pixel
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight // Disables lighting features

            #include "UnityCG.cginc"

            struct appdata // Object Data or Mesh
            {
                float4 vertex : POSITION;
            };

            struct v2f // Vert to frag; passes data from the vert shader to the frag shader
            {
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;// Stores screen space position
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
                o.vertex = UnityObjectToClipPos(v.vertex); // Model View Projection Matrix

                o.screenPos = ComputeScreenPos(o.vertex);
                COMPUTE_EYEDEPTH(o.screenPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = _Color;

                // Computes depth
                float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)));
                float depth = sceneZ - i.screenPos.z;

                // Makes a depth fading effect
                fixed depthFading = saturate((abs(pow(depth, _DepthPow))) / _DepthFactor);
                col *= depthFading;

                // Makes the intersection effect
                fixed intersect = saturate((abs(depth)) / _IntersectionThreshold);
                col += _EdgeColor * pow(1 - intersect, 4) * _IntersectionPow;

                return col;
            }
            ENDCG
        }
    }
}
