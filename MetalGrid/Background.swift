//
//  Background.swift
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Medly Labs Inc. All rights reserved.
//

import Foundation
import UIKit
import Metal

class Background {
    
    let color: MTLBuffer
    let bar:   MTLBuffer
    
    init(_ device: MTLDevice) {
        
        self.color = device.makeBuffer(length: MemoryLayout<ColorVertex>.stride * 6, options: [])!
        self.bar   = device.makeBuffer(length: MemoryLayout<ColorVertex>.stride * 6, options: [])!
        
        self.layoutChanged()
    }
    
    func layoutChanged() {
        
        let screenWidth  = Float(UIScreen.main.bounds.width)
        let screenHeight = Float(UIScreen.main.bounds.height)
        
        // Color
        do {
            let A = ColorVertex(0,           0,            getColor(hex: 0x00ff00, alpha: 1.0))
            let B = ColorVertex(screenWidth, 0,            getColor(hex: 0x00ff00, alpha: 1.0))
            let C = ColorVertex(0,           screenHeight, getColor(hex: 0x00ff00, alpha: 1.0))
            let D = ColorVertex(screenWidth, screenHeight, getColor(hex: 0x00ff00, alpha: 1.0))
            
            let geometry = [
                A, B, C,
                B, C, D
            ]
            
            memcpy(self.color.contents(), UnsafeRawPointer(geometry), MemoryLayout<ColorVertex>.stride * 6)
        }
        
        // Bar
        do {
            let height: Float = 150
            let yOffset: Float = (screenHeight - height) / 2.0
            
            let A = ColorVertex(0,           yOffset,          getColor(hex: 0x00ffff, alpha: 1.0))
            let B = ColorVertex(screenWidth, yOffset,          getColor(hex: 0x00ffff, alpha: 1.0))
            let C = ColorVertex(0,           yOffset + height, getColor(hex: 0x00ffff, alpha: 1.0))
            let D = ColorVertex(screenWidth, yOffset + height, getColor(hex: 0x00ffff, alpha: 1.0))
            
            let geometry = [
                A, B, C,
                B, C, D
            ]
            
            memcpy(self.bar.contents(), UnsafeRawPointer(geometry), MemoryLayout<ColorVertex>.stride * 6)
        }
    }
    
    func render(with renderEncoder: MTLRenderCommandEncoder) {
        let mtl = MetalController.instance
        var matrix = getMatrix()
        
        renderEncoder.pushDebugGroup("Background")
        
        // Draw Color
        renderEncoder.pushDebugGroup("Color")
        renderEncoder.setRenderPipelineState(mtl.pipeline.simple)
        renderEncoder.setVertexBuffer(self.color, offset: 0, index: 0)
        
        let len = MemoryLayout<matrix_float4x4>.stride
        renderEncoder.setVertexBytes(&matrix, length: len, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.popDebugGroup()
        
        
        // Draw Bar
//        renderEncoder.pushDebugGroup("Color")
//        renderEncoder.setRenderPipelineState(mtl.pipeline.simple)
//        renderEncoder.setVertexBuffer(self.color, offset: 0, index: 0)
//
//        let len = MemoryLayout<matrix_float4x4>.stride
//        renderEncoder.setVertexBytes(&matrix, length: len, index: 1)
//
//        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
//        renderEncoder.popDebugGroup()
//
        renderEncoder.popDebugGroup()
    }
}
