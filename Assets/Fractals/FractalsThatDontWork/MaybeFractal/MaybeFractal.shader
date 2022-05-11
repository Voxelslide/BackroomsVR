Shader "Raymarching/MaybeFractal"
{

Properties
{
    [Header(PBS)]
    _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
    _Metallic("Metallic", Range(0.0, 1.0)) = 0.5
    _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5

    [Header(Pass)]
    [Enum(UnityEngine.Rendering.CullMode)] _Cull("Culling", Int) = 2

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
_Color2("Color2", Color) = (1.0, 1.0, 1.0, 1.0)
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

#define OBJECT_SCALE

#define OBJECT_SHAPE_CUBE

#define USE_RAYMARCHING_DEPTH

#define USE_CAMERA_DEPTH_TEXTURE

#define SPHERICAL_HARMONICS_PER_PIXEL

#define DISTANCE_FUNCTION DistanceFunction
#define PostEffectOutput SurfaceOutputStandard
#define POST_EFFECT PostEffect

#include "Packages/com.hecomi.uraymarching/Runtime/Shaders/Include/Legacy/Common.cginc"

// @block DistanceFunction
int Iterations = 50;
float Scale = 10;
float foldingLimit = 20;
float r = 10;
float minRadius2 = 2;
float fixedRadius2 = 5;

void boxFold(inout float3 z, inout float dz) {
	z = clamp(z, -foldingLimit, foldingLimit) * 2.0 - z;
}

void sphereFold(inout float3 z, inout float dz) {
	float r2 = dot(z,z);
	if (r<minRadius2) { 
		// linear inner scaling
		float temp = (fixedRadius2/minRadius2);
		z *= temp;
		dz*= temp;
	} else if (r2<fixedRadius2) { 
		// this is the actual sphere inversion
		float temp =(fixedRadius2/r2);
		z *= temp;
		dz*= temp;
	}
}

inline float DistanceFunction(float3 pos)
{
	float3 offset = pos;
	float dr = 1.0;
	for (int n = 0; n < Iterations; n++) {
		boxFold(pos,dr);       // Reflect
		sphereFold(pos,dr);    // Sphere Inversion
	}
                pos=Scale*pos + offset;  // Scale & Translate
                dr = dr*abs(Scale)+1.0;
	float r = length(pos);
	return r/abs(dr);
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
    Tags { "LightMode" = "ForwardAdd" }
    ZWrite Off 
    Blend One One

    CGPROGRAM
    #include "Packages/com.hecomi.uraymarching/Runtime/Shaders/Include/Legacy/ForwardAddStandard.cginc"
    #pragma target 3.0
    #pragma vertex Vert
    #pragma fragment Frag
    #pragma multi_compile_instancing
    #pragma multi_compile_fog
    #pragma skip_variants INSTANCING_ON
    #pragma multi_compile_fwdadd_fullshadows
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

Fallback "Raymarching/Fallbacks/StandardSurfaceShader"

CustomEditor "uShaderTemplate.MaterialEditor"

}