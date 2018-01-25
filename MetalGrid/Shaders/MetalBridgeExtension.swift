//
//  MetalBridgeExtension.swift
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Medly Labs Inc. All rights reserved.
//

import Foundation

extension ColorVertex {
    init(_ x: Float, _ y: Float, _ color: vector_float4) {
        self.position = vector_float2(x, y)
        self.r = color.x; self.g = color.y; self.b = color.z; self.a = color.w;
    }
}

