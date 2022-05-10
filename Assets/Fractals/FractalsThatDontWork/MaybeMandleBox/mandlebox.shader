Shader "Raymarching/mandlebox"
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

#define USE_RAYMARCHING_DEPTH

#define SPHERICAL_HARMONICS_PER_PIXEL

#define DISTANCE_FUNCTION DistanceFunction
#define PostEffectOutput SurfaceOutputStandard
#define POST_EFFECT PostEffect

#include "Packages/com.hecomi.uraymarching/Runtime/Shaders/Include/Legacy/Common.cginc"

// @block DistanceFunction
// simply scale the dual vectors
void sphereFold(inout float3 z, inout _matrix dz) {
	float r2 = dot(z,z);
	if (r2 < 0.5) {
		float temp = (5/0.5);
		z*= temp; dz*=temp;
	} else if (r2 < 5) {
		float temp =(5/r2);
                dz[0] =temp*(dz[0]-z*2.0*dot(z,dz[0])/r2);
                dz[1] =temp*(dz[1]-z*2.0*dot(z,dz[1])/r2);
                dz[2] =temp*(dz[2]-z*2.0*dot(z,dz[2])/r2);
		z*=temp; dz*=temp;
	}
}

// reverse signs for dual vectors when folding
void boxFold(inout float3 z, inout float3 dz) {
	if (abs(z.x)>50) { dz[0].x*=-1; dz[1].x*=-1; dz[2].x*=-1; }
        if (abs(z.y)>50)  { dz[0].y*=-1; dz[1].y*=-1; dz[2].y*=-1; }
        if (abs(z.z)>50)  { dz[0].z*=-1; dz[1].z*=-1; dz[2].z*=-1; }
	z = clamp(z, -50, 50) * 2.0 - z;
}

inline float DistanceFunction(float3 pos)
{
        // dz contains our three dual vectors,
        // initialized to x,y,z directions.
	mat3 dz = mat3(1.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,1.0);
	
	vec3 c = z;
	mat3 dc = dz;
	for (int n = 0; n < Iterations; n++) {
		boxFold(z,dz);
		sphereFold(z,dz);
		z*=Scale;
		dz=mat3(dz[0]*Scale,dz[1]*Scale,dz[2]*Scale);
		z += c*Offset;
	        dz +=matrixCompMult(mat3(Offset,Offset,Offset),dc);
		if (length(z)>1000.0) break;
	}
	return dot(z,z)/length(z*dz); 
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