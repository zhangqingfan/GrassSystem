Shader "MyShader/GrassShader_TBN_1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TopColor("Top Color", Color) = (1,1,1,1)
        _BottomColor("Bottom Color", Color) = (1,1,1,1)
    }

    CGINCLUDE
    #include "UnityCG.cginc"
	#include "Autolight.cginc"

    float4 _TopColor;
    float4 _BottomColor;

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
        float3 normal : NORMAL;
        float4 tangent : TANGENT;
    };

    struct geometryOutput
    { 
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    geometryOutput VertexOutput(float3 pos, float2 uv)
    {
        geometryOutput o;
        o.pos = UnityObjectToClipPos(pos);
        o.uv = uv;
        return o;
    }


    [maxvertexcount(3)]
    void geo(triangle v2f input[3] : SV_POSITION, inout TriangleStream<geometryOutput> newTriangle)
    {
        float4 pos = input[0].vertex;
        float3 normal = input[0].normal;
        float3 tangent = input[0].tangent;
        float3 biNormal = cross(normal, tangent) *  input[0].tangent.w;

        float3x3 TBNMetrix = transpose(float3x3(tangent, biNormal, normal));

        //Remind: the triange might be culled if do not use "Cull Off" in SubShader!!!!!!!!!!!!!!
        geometryOutput o = VertexOutput(pos + mul(TBNMetrix, float3(0.5, 0, 0)), float2(1, 0));
        newTriangle.Append(o);

        o = VertexOutput(pos + mul(TBNMetrix, float3(-0.5, 0, 0)), float2(0, 0));
        newTriangle.Append(o);

       o = VertexOutput(pos + mul(TBNMetrix, float3(0, 0, 1)), float2(0.5, 1));
        newTriangle.Append(o);

        //newTriangle.RestartStrip();
    }

    ENDCG


    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geo
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = (v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = v.normal;
                o.tangent = v.tangent;
                return o;
            }

            fixed4 frag (geometryOutput i) : SV_Target
            {
                fixed4 col = lerp(_BottomColor, _TopColor, i.uv.y);
                return col;
            }
            ENDCG
        }
    }
}
