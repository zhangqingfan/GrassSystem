Shader "MyShader/GrassShader_Tessellation_5"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WindDirectionTex ("WindDirectionTex", 2D) = "white" {}
        _Width("Width", float) = 1
        _Height("Height", float) = 1
        _WindSpeed("WindSpeed", float) = 0.07
        _Curve("_Curve", Range(1, 4)) = 2
        _TopColor("Top Color", Color) = (1,1,1,1)
        _BottomColor("Bottom Color", Color) = (1,1,1,1)
        _TessellationUniform ("Tessellation Uniform", Range(1, 12)) = 6
    }

    CGINCLUDE
    #include "UnityCG.cginc"
	#include "Autolight.cginc"
    #include "CustomTessellation.cginc"
    
    sampler2D _WindDirectionTex;
    float4 _WindDirectionTex_ST;

    float4 _TopColor;
    float4 _BottomColor;
    float _Width;
    float _Height;
    float _WindSpeed;
    float _Curve;

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

    #define GRASS_SEGMENTS 3

    [maxvertexcount(GRASS_SEGMENTS * 2 + 1)]
    void geo(triangle vertexOutput input[3] : SV_POSITION, inout TriangleStream<geometryOutput> newTriangle)
    {
        float4 pos = input[0].vertex;
        float3 normal = input[0].normal;
        float3 tangent = input[0].tangent;
        float3 biNormal = cross(normal, tangent) *  input[0].tangent.w;

        float3x3 TBNMetrix = transpose(float3x3(tangent, biNormal, normal));
        float3x3 rotationMatrixZ = AngleAxis3x3(random(pos.xy + pos.xz) * UNITY_PI, float3(0, 0, 1));
        float3x3 rotationMatrixX = AngleAxis3x3(random(pos.xz + pos.yz) * UNITY_PI * 0.3, float3(1, 0, 0));

        float2 uv = TRANSFORM_TEX(pos.xz, _WindDirectionTex);
        uv += _Time.y * float2(_WindSpeed, _WindSpeed);
        float2 windSample = tex2Dlod(_WindDirectionTex, float4(uv, 0, 0)); 
        float3 windDirection = normalize(float3(windSample.x, windSample.y, 1));
        float3x3 rotationWind = AngleAxis3x3(windSample * UNITY_PI * 0.5, windDirection);

        float3x3 tranformMatrix = mul(rotationMatrixZ, rotationMatrixX);
        tranformMatrix = mul(rotationWind, tranformMatrix);
        tranformMatrix = mul(TBNMetrix, tranformMatrix);

        _Width = random(pos.xy) * _Width;
        _Height = random(pos.yz) * _Height;
        _Curve =  random(pos.yz) * _Curve;

        for(int i = 0; i < GRASS_SEGMENTS; i++)
        {
            float t = i / (float)GRASS_SEGMENTS;
            float width = _Width * (1 - t);
            float height = _Height * t;
            float curve = pow(t, _Curve) * sign(windDirection.y);

            //Remind: the triange might be culled if do not use "Cull Off" in SubShader!!!!!!!!!!!!!!
            geometryOutput o = VertexOutput(pos + mul(tranformMatrix, float3(width, curve, height)), float2(0, t));
            newTriangle.Append(o);

            o = VertexOutput(pos + mul(tranformMatrix, float3(-width, curve, height)), float2(0, t));
            newTriangle.Append(o);
        }

        geometryOutput o = VertexOutput(pos + mul(tranformMatrix, float3(0, _Curve, _Height)), float2(0, 1)); //in TBN space the z is y in model space
        newTriangle.Append(o);
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
            #pragma hull hull
			#pragma domain domain
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            fixed4 frag (geometryOutput i) : SV_Target
            {
                fixed4 col = lerp(_BottomColor, _TopColor, i.uv.y);
                return col;
            }
            ENDCG
        }
    }
}
