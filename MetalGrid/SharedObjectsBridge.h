//
//  SharedObjectsBridge.h
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Basil Al-Dajane. All rights reserved.
//

#include <simd/simd.h>

typedef struct ObjectData {
    vector_float4 color;
    vector_float2 offset;
} ObjectData __attribute__((aligned(16)));
