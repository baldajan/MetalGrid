//
//  StandardShaders.metal
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Basil Al-Dajane. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
#include "MetalBridge.h"
using namespace metal;

// Shader Structs
struct VertexOut {
    float4 position [[position]];
    half4  color;
};

struct VertexTexOut {
    float4 position [[position]];
    float2 texCoord;
};



// Simple Shader
vertex VertexOut v_simple(device   ColorVertex     *verts   [[buffer(0)]], // Vertex Data
                          constant matrix_float4x4 &matrix  [[buffer(1)]], // Constant Data (used across all objects)
                                   uint             vid     [[vertex_id]]) // Iterates through vertices
{
    ColorVertex vert = verts[vid];
    
    VertexOut out = {
        .position = matrix * float4(vert.position, 1, 1),
        .color    = half4(vert.r, vert.g, vert.b, vert.a),
    };
    
    return out;
}

fragment half4 f_simple(VertexOut frag [[stage_in]]) {
    return frag.color;
}





// Blend Overlay
half BlendOverlayColor(half color, half dest);
half BlendOverlayColor(half color, half dest) {
    return (dest < 0.5h) ? (2.0h * dest * color) : (1.0h - 2.0h * (1.0h - dest) * (1.0h - color));
}
half4 BlendOverlay(half4 color, half4 dest);
half4 BlendOverlay(half4 color, half4 dest) {
    return half4(BlendOverlayColor(color.r, dest.r),
                 BlendOverlayColor(color.g, dest.g),
                 BlendOverlayColor(color.b, dest.b),
                 color.a);
}



// Grid Shader
vertex VertexOut v_grid(device   vector_float2   *verts   [[buffer(0)]],   // Vertex Data
                        constant ObjectConsts    &consts  [[buffer(1)]],   // Constant Data (used across all objects)
                        constant ObjectData      *objects [[buffer(2)]],   // Objects Data
                                 uint             vid     [[vertex_id]],   // Iterates through vertices
                                 ushort           iid     [[instance_id]]) // Iterates through objects (will reset vertex_id when incremented)
{
    float2 pos = verts[vid];
    ObjectData data = objects[iid];
    
    VertexOut out = {
        .position = consts.matrix * float4(pos + data.offset, 1, 1),
        .color    = static_cast<half4>(consts.color),
    };
    
    return out;
}

fragment half4 f_grid(VertexOut frag [[stage_in]],
                      half4     dest [[color(0)]]) {
    return BlendOverlay(frag.color, dest);
}




// Texture Shader
vertex VertexTexOut v_tex(device   TexVertex       *verts  [[buffer(0)]],
                          constant matrix_float4x4 &matrix [[buffer(1)]],
                                       uint         vid    [[vertex_id]])
{
    float2 pos = verts[vid].position;
    float2 texCoord = verts[vid].texCoord;
    
    VertexTexOut out = {
        .position = matrix * float4(pos, 1, 1),
        .texCoord = texCoord,
    };
    
    return out;
}

fragment half4 f_tex(VertexTexOut                     frag   [[stage_in]],
                     texture2d<float, access::sample> tex    [[texture(0)]],
                     sampler                          samplr [[sampler(0)]])
{
    return half4(tex.sample(samplr, frag.texCoord));
}
