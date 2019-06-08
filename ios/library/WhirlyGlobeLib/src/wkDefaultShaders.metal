/*
 *  wkDefaultShaders.metal
 *  WhirlyGlobeLib
 *
 *  Created by Steve Gifford on 5/16/19.
 *  Copyright 2011-2019 mousebird consulting
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

#include <metal_stdlib>
#import "../include/DefaultShadersMTL.h"

using namespace metal;
using namespace WhirlyKitShader;

// Vertices with position, color, and normal
struct VertexA
{
    float3 position [[attribute(WKSVertexPositionAttribute)]];
    float4 color [[attribute(WKSVertexColorAttribute)]];
    float3 normal [[attribute(WKSVertexNormalAttribute)]];
};

// Position, color, and dot project (for backface checking)
struct ProjVertexA
{
    float4 position [[position]];
    float4 color;
    float dotProd;
};

// Vertex shader for simple line on the globe
vertex ProjVertexA vertexLineOnly_globe(
    VertexA vert [[stage_in]],
    constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
    constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]])
{
    ProjVertexA outVert;
    
    outVert.color = float4(vert.color) * uniDrawState.fade;
    if (uniDrawState.clipCoords) {
        outVert.dotProd = 1.0;
        outVert.position = uniforms.mvpMatrix * float4(vert.position,1.0);
    } else {
        float4 pt = uniforms.mvMatrix * float4(vert.position, 1.0);
        pt /= pt.w;
        float4 testNorm = uniforms.mvNormalMatrix * float4(vert.normal,0.0);
        outVert.dotProd = dot(-pt.xyz,testNorm.xyz);
        outVert.position = uniforms.mvpMatrix * float4(vert.position,1.0);
    }
    
    return outVert;
}

// Fragment shader for simple line case
fragment float4 framentLineOnly_globe(
    ProjVertexA in [[stage_in]])
{
    if (in.dotProd <= 0.0)
        discard_fragment();
    return in.color;
}

// Just position and color
struct ProjVertexB
{
    float4 position [[position]];
    float4 color;
};

// Vertex shader for simple line on the flat map (no backface checking)
vertex ProjVertexB vertexLineOnly_flat(
    VertexA vert [[stage_in]],
    constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
    constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]])
{
    ProjVertexB outVert;
    
    outVert.color = float4(vert.color) * uniDrawState.fade;
    if (uniDrawState.clipCoords)
        outVert.position = float4(vert.position,1.0);
    else
        outVert.position = uniforms.mvpMatrix * float4(vert.position,1.0);
    
    return outVert;
}

// Simple fragment shader for lines on flat map
fragment float4 fragmentLineOnly_flat(
    ProjVertexB vert [[stage_in]],
    constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]])
{
    return vert.color;
}

// Ye olde triangle vertex
struct VertexTriA
{
    float3 position [[attribute(WKSVertexPositionAttribute)]];
    float4 color [[attribute(WKSVertexColorAttribute)]];
    float3 normal [[attribute(WKSVertexNormalAttribute)]];
    float2 texCoord [[attribute(WKSVertexTextureBaseAttribute)]];
};

// Output vertex to the fragment shader
struct ProjVertexTriA {
    float4 position [[position]];
    float4 color;
    float2 texCoord;
};

// Resolve texture coordinates with their parent offsts, if necessary
float2 resolveTexCoords(float2 texCoord,TexIndirect texIndr)
{
    if (texIndr.scale.x == 0.0)
        return texCoord;
    
    return texCoord * texIndr.scale + texIndr.offset;
}

// Calculate lighting for the given position and normal
float4 resolveLighting(float3 pos,
                      float3 norm,
                      float4 color,
                      constant Lighting &lighting,
                      constant float4x4 &mvpMatrix)
{
    float4 ambient(0.0,0.0,0.0,0.0);
    float4 diffuse(0.0,0.0,0.0,0.0);

    for (int ii=0;ii<lighting.numLights;ii++) {
        constant Light &light = lighting.lights[ii];
        float3 adjNorm = light.viewDepend > 0.0 ? normalize((mvpMatrix * float4(norm.xyz, 0.0)).xyz) : norm.xzy;
        float ndotl = max(0.0, dot(adjNorm, light.direction));
        ambient += light.ambient;
        diffuse += ndotl * light.diffuse;
    }
    
    return float4(ambient.xyz * lighting.mat.ambient.xyz * color.xyz + diffuse.xyz * color.xyz,1.0);
}

// Simple vertex shader for triangle with no lighting
vertex ProjVertexTriA vertexTri_noLight(VertexTriA vert [[stage_in]],
                                        constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
                                        constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]],
                                        constant TexIndirect &texIndirect [[buffer(WKSTexIndirectStartBuffer)]])
{
    ProjVertexTriA outVert;
    
    if (uniDrawState.clipCoords)
        outVert.position = float4(vert.position,1.0);
    else
        outVert.position = uniforms.mvpMatrix * float4(vert.position,1.0);
    outVert.color = float4(vert.color) * uniDrawState.fade;
    outVert.texCoord = resolveTexCoords(vert.texCoord,texIndirect);
    
    return outVert;
}

// Simple vertex shader for triangle with basic lighting
vertex ProjVertexTriA vertexTri_light(VertexTriA vert [[stage_in]],
                                      constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
                                      constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]],
                                      constant Lighting &lighting [[buffer(WKSLightingBuffer)]],
                                      constant TexIndirect &texIndirect [[buffer(WKSTexIndirectStartBuffer)]])
{
    ProjVertexTriA outVert;
    
    if (uniDrawState.clipCoords)
        outVert.position = float4(vert.position,1.0);
    else
        outVert.position = uniforms.mvpMatrix * float4(vert.position,1.0);
    outVert.color = resolveLighting(vert.position,
                                    vert.normal,
                                    float4(vert.color),
                                    lighting,
                                    uniforms.mvpMatrix) * uniDrawState.fade;
    outVert.texCoord = resolveTexCoords(vert.texCoord,texIndirect);
    
    return outVert;
}

// Simple fragment shader for lines on flat map
fragment float4 fragmentTri_basic(ProjVertexTriA vert [[stage_in]],
                                      constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
                                      constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]],
                                      texture2d<float,access::sample> tex [[texture(0)]])
{
    if (uniDrawState.numTextures > 0) {
        constexpr sampler sampler2d(coord::normalized, filter::linear);
        return vert.color * tex.sample(sampler2d, vert.texCoord);
    } else
        return vert.color;
}

// Triangle vertex with a couple of texture coordinates
struct VertexTriB
{
    float3 position [[attribute(WKSVertexPositionAttribute)]];
    float4 color [[attribute(WKSVertexColorAttribute)]];
    float3 normal [[attribute(WKSVertexNormalAttribute)]];
    float2 texCoord0 [[attribute(WKSVertexTextureBaseAttribute)]];
    float2 texCoord1 [[attribute(WKSVertexTextureBaseAttribute+1)]];
};

// Output vertex to the fragment shader
struct ProjVertexTriB {
    float4 position [[position]];
    float4 color;
    float2 texCoord0;
    float2 texCoord1;
};

// Vertex shader that handles up to two textures
vertex ProjVertexTriB vertexTri_multiTex(VertexTriB vert [[stage_in]],
                                         constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
                                         constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]],
                                         constant Lighting &lighting [[buffer(WKSLightingBuffer)]],
                                         constant TexIndirect &texIndirect0 [[buffer(WKSTexIndirectStartBuffer)]],
                                         constant TexIndirect &texIndirect1 [[buffer(WKSTexIndirectStartBuffer+1)]])
{
    ProjVertexTriB outVert;
    
    if (uniDrawState.clipCoords)
        outVert.position = float4(vert.position,1.0);
    else
        outVert.position = uniforms.mvpMatrix * float4(vert.position,1.0);
    outVert.color = resolveLighting(vert.position,
                                    vert.normal,
                                    float4(vert.color),
                                    lighting,
                                    uniforms.mvpMatrix) * uniDrawState.fade;

    // Handle the various texture coordinate input options (none, 1, or 2)
    if (uniDrawState.numTextures == 0) {
        outVert.texCoord0 = float2(0.0,0.0);
        outVert.texCoord1 = float2(0.0,0.0);
    } else if (uniDrawState.numTextures == 1) {
        outVert.texCoord0 = resolveTexCoords(vert.texCoord0,texIndirect0);
        outVert.texCoord1 = vert.texCoord0;
    } else {
        outVert.texCoord0 = resolveTexCoords(vert.texCoord0,texIndirect0);
        outVert.texCoord1 = resolveTexCoords(vert.texCoord1,texIndirect1);
    }
    
    return outVert;
}

// Fragement shader that handles to two textures
fragment float4 fragmentTri_multiTex(ProjVertexTriB vert [[stage_in]],
                                     constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
                                     constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]],
                                     texture2d<float,access::sample> tex0 [[texture(0)]],
                                     texture2d<float,access::sample> tex1 [[texture(1)]])
{
    // Handle none, 1 or 2 textures
    if (uniDrawState.numTextures == 0) {
        return vert.color;
    } else if (uniDrawState.numTextures == 1) {
        constexpr sampler sampler2d(coord::normalized, filter::linear);
        return vert.color * tex0.sample(sampler2d, vert.texCoord0);
    } else {
        constexpr sampler sampler2d(coord::normalized, filter::linear);
        float4 color0 = tex0.sample(sampler2d, vert.texCoord0);
        // Note: There are times we may not want to reuse the same texture coordinates
        float4 color1 = tex1.sample(sampler2d, vert.texCoord0);
        return vert.color * mix(color0,color1,uniDrawState.interp);
    }
}

// Fragment shader that handles two textures and does a ramp lookup
fragment float4 fragmentTri_multiTexRamp(ProjVertexTriB vert [[stage_in]],
                                         constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
                                         constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]],
                                         texture2d<float,access::sample> tex0 [[texture(0)]],
                                         texture2d<float,access::sample> tex1 [[texture(1)]],
                                         texture2d<float,access::sample> rampTex [[texture(WKSTextureEntryLookup)]])
{
    // Handle none, 1 or 2 textures
    if (uniDrawState.numTextures == 0) {
        return vert.color;
    } else if (uniDrawState.numTextures == 1) {
        constexpr sampler sampler2d(coord::normalized, filter::linear);
        float index = tex0.sample(sampler2d, vert.texCoord0).r;
//        return vert.color * index;
        return vert.color * rampTex.sample(sampler2d,float2(index,0.5));
    } else {
        constexpr sampler sampler2d(coord::normalized, filter::linear);
        float index0 = tex0.sample(sampler2d, vert.texCoord0).r;
        // Note: There are times we may not want to reuse the same texture coordinates
        float index1 = tex1.sample(sampler2d, vert.texCoord0).r;
        float index = mix(index0,index1,uniDrawState.interp);
        return vert.color * rampTex.sample(sampler2d,float2(index,0.5));
//        return vert.color * index;
    }
}

/**
  Wide Vector Shaders
  These work to build/render objects in 2D space, but based
   on 3D locations.
  */

struct VertexTriWideVec
{
    float3 position [[attribute(WKSVertexPositionAttribute)]];
    float3 normal [[attribute(WKSVertexNormalAttribute)]];
    float4 texInfo [[attribute(WKSVertexWideVecTexInfoAttribute)]];
    float3 p1 [[attribute(WKSVertexWideVecP1Attribute)]];
    float3 n0 [[attribute(WKSVertexWideVecN0Attribute)]];
    float c0 [[attribute(WKSVertexWideVecC0Attribute)]];
};

// 2D Map version
vertex ProjVertexTriA vertexTri_wideVec(VertexTriWideVec vert [[stage_in]],
                                        constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
                                        constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]],
                                        constant UniformWideVec &uniSS [[buffer(WKSUniformDrawStateWideVecBuffer)]])
{
    ProjVertexTriA outVert;
    
    outVert.color = uniSS.color;
    
    float t0 = vert.c0 * uniSS.real_w2;
    t0 = clamp(t0,0.0,1.0);
    float3 realPos = (vert.p1 - vert.position) * t0 + vert.n0 * uniSS.real_w2 + vert.position;
    float texPos = ((vert.texInfo.z - vert.texInfo.y) * t0 + vert.texInfo.y + vert.texInfo.w * uniSS.real_w2) * uniSS.texScale;
    outVert.texCoord = float2(vert.texInfo.x, texPos);
    float4 screenPos = uniforms.mvpMatrix * float4(realPos,1.0);
    screenPos /= screenPos.w;
    outVert.position = float4(screenPos.xy,0,1.0);

    return outVert;
}

// Fragment shader that doesn't account for the globe
fragment float4 fragmentTri_wideVec(ProjVertexTriA vert [[stage_in]],
                                        constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
                                        constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]],
                                        constant UniformWideVec &uniSS [[buffer(WKSUniformDrawStateWideVecBuffer)]],
                                        texture2d<float,access::sample> tex [[texture(0)]])
{
    // Dot/dash pattern
    float patternVal = 1.0;
    if (uniDrawState.numTextures > 0) {
        constexpr sampler sampler2d(coord::normalized, address::repeat, filter::linear);
        patternVal = tex.sample(sampler2d, float2(0.5,vert.texCoord.y)).r;
    }
    float alpha = 1.0;
    float across = vert.texCoord.x * uniSS.w2;
    if (across < uniSS.edge)
        alpha = across/uniSS.edge;
    if (across > uniSS.w2-uniSS.edge)
        alpha = (uniSS.w2-across)/uniSS.edge;
    return uniSS.color * alpha * patternVal * uniDrawState.fade;
}


// This version has the dot project pass through
struct ProjVertexTriWideVec {
    float4 position [[position]];
    float4 color;
    float2 texCoord;
    float dotProd;
};

// 3D globe version.  Takes the back into account
vertex ProjVertexTriWideVec vertexTri_wideVecGlobe(VertexTriWideVec vert [[stage_in]],
                                            constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
                                            constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]],
                                            constant UniformWideVec &uniSS [[buffer(WKSUniformDrawStateWideVecBuffer)]])
{
    ProjVertexTriWideVec outVert;
    
    outVert.color = uniSS.color;
    
    float t0 = vert.c0 * uniSS.real_w2;
    t0 = clamp(t0,0.0,1.0);
    float3 realPos = (vert.p1 - vert.position) * t0 + vert.n0 * uniSS.real_w2 + vert.position;
    float texPos = ((vert.texInfo.z - vert.texInfo.y) * t0 + vert.texInfo.y + vert.texInfo.w * uniSS.real_w2) * uniSS.texScale;
    outVert.texCoord = float2(vert.texInfo.x, texPos);
    float4 screenPos = uniforms.mvpMatrix * float4(realPos,1.0);
    screenPos /= screenPos.w;
    outVert.position = float4(screenPos.xy,0,1.0);
    
    // Used to evaluate pixels behind the globe
    float4 pt = uniforms.mvMatrix * float4(vert.position,1.0);
    pt /= pt.w;
    float4 testNorm = uniforms.mvNormalMatrix * float4(vert.normal,0.0);
    outVert.dotProd = dot(-pt.xyz,testNorm.xyz);
    
    return outVert;
}

// Fragment share that takes the back of the globe into account
fragment float4 fragmentTri_wideVecGlobe(ProjVertexTriWideVec vert [[stage_in]],
                                        constant Uniforms &uniforms [[buffer(WKSUniformBuffer)]],
                                        constant UniformDrawStateA &uniDrawState [[buffer(WKSUniformDrawStateBuffer)]],
                                        constant UniformWideVec &uniSS [[buffer(WKSUniformDrawStateWideVecBuffer)]],
                                        texture2d<float,access::sample> tex [[texture(0)]])
{
    // Dot/dash pattern
    float patternVal = 1.0;
    if (uniDrawState.numTextures > 0) {
        constexpr sampler sampler2d(coord::normalized, address::repeat, filter::linear);
        patternVal = tex.sample(sampler2d, float2(0.5,vert.texCoord.y)).r;
    }
    float alpha = 1.0;
    float across = vert.texCoord.x * uniSS.w2;
    if (across < uniSS.edge)
        alpha = across/uniSS.edge;
    if (across > uniSS.w2-uniSS.edge)
        alpha = (uniSS.w2-across)/uniSS.edge;
    return vert.dotProd > 0.0 ? uniSS.color * alpha * patternVal * uniDrawState.fade : float4(0.0);
}
