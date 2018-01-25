//
//  Utils.swift
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Medly Labs Inc. All rights reserved.
//

import Foundation
import UIKit

func getColor(hex: UInt32, alpha: Float) -> vector_float4 {
    let red   = Float((hex & 0xFF_00_00) >> 16)
    let green = Float((hex & 0x00_FF_00) >>  8)
    let blue  = Float((hex & 0x00_00_FF) >>  0)
        
    return vector_float4(Float(red)/255.0, Float(green)/255.0, Float(blue)/255.0, alpha)
}

func getMatrix() -> matrix_float4x4 {
    let screenWidth  = Float(UIScreen.main.bounds.width)
    let screenHeight = Float(UIScreen.main.bounds.height)
    
    return matrix_ortho(0, screenWidth, 0, screenHeight, 0, 1)
}

func makeMatrix(with frame: CGRect) -> matrix_float4x4 {
    let matrix = matrix_ortho(0, Float(frame.size.width), 0, Float(frame.size.height), 0, 1)
    let trans  = matrix4x4_translation(Float(-frame.origin.x), Float(-frame.origin.y), 0)
    
    return matrix_multiply(matrix, trans)
}
