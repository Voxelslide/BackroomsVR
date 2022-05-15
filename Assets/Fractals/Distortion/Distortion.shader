Shader "Raymarching/Distortion"
{

Properties
{
    [Header(PBS)]
    _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Metallic("Metallic", Range(0.0, 1.0)) = 0.5
    _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5

    [Header(Pass)]
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendSrc("Blend Src", Float) = 5 
    [Enum(UnityEngine.Rendering.BlendMode)] _BlendDst("Blend Dst", Float) = 10
    [Toggle][KeyEnum(Off, On)] _ZWrite("ZWrite", Float) = 1

    [Header(Raymarching)]
    _Loop("Loop", Range(1, 100)) = 30
    _MinDistance("Minimum Distance", Range(0.001, 0.1)) = 0.01
    _DistanceMultiplier("Distance Multiplier", Range(0.001, 2.0)) = 1.0
    _ShadowLoop("Shadow Loop", Range(1, 100)) = 30
    _ShadowMinDistance("Shadow Minimum Distance", Range(0.001, 0.1)) = 0.01
    _ShadowExtraBias("Shadow Extra Bias", Range(0.0, 0.1)) = 0.0
    [PowerSlider(10.0)] _NormalDelta("NormalDelta", Range(0.00001, 0.1)) = 0.0001

// @block Properties
// _Color2("Color2", Color) = (1.0, 1.0, 1.0, 1.0)
// @endblock
}

SubShader
{

Tags
{
    "RenderType" = "Opaque"
    "Queue" = "Geometry"
    "DisableBatching" = "True"
}

Cull [_Cull]

CGINCLUDE

#define OBJECT_SHAPE_CUBE

#define CAMERA_INSIDE_OBJECT

#define USE_RAYMARCHING_DEPTH

#define DISTANCE_FUNCTION DistanceFunction
#define PostEffectOutput SurfaceOutputStandard
#define POST_EFFECT PostEffect

#include "Packages/com.hecomi.uraymarching/Runtime/Shaders/Include/Legacy/Common.cginc"

// @block DistanceFunction
inline float displacement(float3 p, float k)
{
    return p.x/p.y + p.z/p.x;
}

inline float DistanceFunction(float3 pos)
{
    float t = _Time;
    float s = sin(t*10)*0.01;
    float d1 = Sphere(pos, 0.05);
    float d2 = displacement(pos, s);
    return d1 + d2*s;
}
// @endblock

// @block PostEffect
inline void PostEffect(RaymarchInfo ray, inout PostEffectOutput o)
{
}
// @endblock

ENDCG

Pass
{
    Tags { "LightMode" = "ForwardBase" }
    Blend [_BlendSrc] [_BlendDst]
    ZWrite [_ZWrite]

    CGPROGRAM
    #include "Packages/com.hecomi.uraymarching/Runtime/Shaders/Include/Legacy/ForwardBaseStandard.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma multi_compile_fwdbase
    ENDCG
}

Pass
{
    Tags { "LightMode" = "ShadowCaster" }

    CGPROGRAM
    #include "Packages/com.hecomi.uraymarching/Runtime/Shaders/Include/Legacy/ShadowCaster.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma fragmentoption ARB_precision_hint_fastest
    #pragma multi_compile_shadowcaster
    ENDCG
}

}

Fallback Off

CustomEditor "uShaderTemplate.MaterialEditor"

}