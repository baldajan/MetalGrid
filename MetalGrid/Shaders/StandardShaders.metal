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



// Object Shader
vertex VertexOut v_object(device   vector_float2   *verts   [[buffer(0)]],   // Vertex Data
                          constant matrix_float4x4 &matrix  [[buffer(1)]],   // Constant Data (used across all objects)
                          constant ObjectData      *objects [[buffer(2)]],   // Objects Data
                                   uint             vid     [[vertex_id]],   // Iterates through vertices
                                   ushort           iid     [[instance_id]]) // Iterates through objects (will reset vertex_id when incremented)
{
    float2 pos = verts[vid];
    ObjectData data = objects[iid];
    
    VertexOut out = {
        .position = matrix * float4(pos + data.offset, 1, 1),
        .color    = static_cast<half4>(data.color),
    };
    
    return out;
}

fragment half4 f_color(VertexOut frag [[stage_in]]) {
    return frag.color;
}


