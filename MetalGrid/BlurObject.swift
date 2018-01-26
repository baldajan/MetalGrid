//
//  BlurObject.swift
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Basil Al-Dajane. All rights reserved.
//

import Foundation
import UIKit
import Metal

class BlurObject {
    
    let geometry: MTLBuffer
    
    init(_ device: MTLDevice) {
        self.geometry = device.makeBuffer(length: MemoryLayout<TexVertex>.stride * 6, options: [])!
        self.layoutChanged()
    }
    
    func layoutChanged() {
        let screenWidth  = Float(UIScreen.main.bounds.width)
        let screenHeight = Float(UIScreen.main.bounds.height)
        
        let A = TexVertex(0,           0,            0, 1)
        let B = TexVertex(screenWidth, 0,            1, 1)
        let C = TexVertex(0,           screenHeight, 0, 0)
        let D = TexVertex(screenWidth, screenHeight, 1, 0)
        
        let geometry = [ A, B, C, B, C, D ]
        
        memcpy(self.geometry.contents(), UnsafeRawPointer(geometry), MemoryLayout<TexVertex>.stride * 6)
    }
    
    func render(with renderEncoder: MTLRenderCommandEncoder) {
        let mtl = MetalController.instance
        
        var matrix = getMatrix()
        let len = MemoryLayout<matrix_float4x4>.stride
        
        // Scissor Scene
        let screenWidth  = Float(UIScreen.main.bounds.width)
        let screenHeight = Float(UIScreen.main.bounds.height)
        let minDim = min(screenWidth, screenHeight) / 2.0
        
        let scale = Int(UIScreen.main.scale)
        let scissor = MTLScissorRect(x:      scale * Int((screenWidth - minDim) / 2),
                                     y:      scale * Int((screenHeight - minDim) / 2),
                                     width:  scale * Int(minDim),
                                     height: scale * Int(minDim))
        renderEncoder.setScissorRect(scissor)
        
        // Draw Blur
        renderEncoder.pushDebugGroup("Blur")
        renderEncoder.setRenderPipelineState(mtl.pipeline.tex)
        
        renderEncoder.setFragmentTexture(mtl.textures.blurTextureDst, index: 0)
        renderEncoder.setFragmentSamplerState(mtl.textures.sampler, index: 0)
        
        renderEncoder.setVertexBuffer(self.geometry, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&matrix, length: len, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.popDebugGroup()
        
        // Reset Scissor
        let reset = MTLScissorRect(x: 0, y: 0, width: scale * Int(screenWidth), height: scale * Int(screenHeight))
        renderEncoder.setScissorRect(reset)
    }
}
