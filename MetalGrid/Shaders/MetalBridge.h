//
//  SharedObjectsBridge.h
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Basil Al-Dajane. All rights reserved.
//

#include <simd/simd.h>

// Vertex Structs
typedef struct ColorVertex {
    vector_float2 position;
    float r, g, b, a;
} ColorVertex __attribute__((aligned(16)));


// Object Structs
typedef struct ObjectData {
    vector_float4 color;
    vector_float2 offset;
} ObjectData __attribute__((aligned(16)));
