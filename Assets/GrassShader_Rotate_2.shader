﻿Shader "MyShader/GrassShader_Rotate_2"
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

    float random (float2 uv)
    {
        return frac(sin(dot(uv, float2(12.9898,78.233)))*43758.5453123);
    }

    float3x3 AngleAxis3x3(float angle, float3 axis)
    {
        float c, s;
        sincos(angle, s, c);

        float t = 1 - c;
        float x = axis.x;
        float y = axis.y;
        float z = axis.z;

        return float3x3(
            t * x * x + c,      t * x * y - s * z,  t * x * z + s * y,
            t * x * y + s * z,  t * y * y + c,      t * y * z - s * x,
            t * x * z - s * y,  t * y * z + s * x,  t * z * z + c
        );
    }

    [maxvertexcount(3)]
    void geo(triangle v2f input[3] : SV_POSITION, inout TriangleStream<geometryOutput> newTriangle)
    {
        float4 pos = input[0].vertex;
        float3 normal = input[0].normal;
        float3 tangent = input[0].tangent;
        float3 biNormal = cross(normal, tangent) *  input[0].tangent.w;

        float3x3 TBNMetrix = transpose(float3x3(tangent, biNormal, normal));
        float3x3 rotationMatrixZ = AngleAxis3x3(random(pos.xy + pos.xz) * UNITY_PI, float3(0, 0, 1));
        float3x3 rotationMatrixX = AngleAxis3x3(random(pos.xz + pos.yz) * UNITY_PI * 0.5, float3(1, 0, 0));

        float3x3 tranformMatrix = mul(rotationMatrixZ, rotationMatrixX);
        tranformMatrix = mul(TBNMetrix, tranformMatrix);
      
        //Remind: the triange might be culled if do not use "Cull Off" in SubShader!!!!!!!!!!!!!!
        geometryOutput o = VertexOutput(pos + mul(tranformMatrix, float3(0.5, 0, 0)), float2(1, 0));
        newTriangle.Append(o);

        o = VertexOutput(pos + mul(tranformMatrix, float3(-0.5, 0, 0)), float2(0, 0));
        newTriangle.Append(o);

       o = VertexOutput(pos + mul(tranformMatrix, float3(0, 0, 1)), float2(0.5, 1)); //in TBN space the z is y in model space
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
