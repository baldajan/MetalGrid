//
//  BlurObject.swift
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Medly Labs Inc. All rights reserved.
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
        
        let A = TexVertex(0,           0,            0, 0)
        let B = TexVertex(screenWidth, 0,            1, 0)
        let C = TexVertex(0,           screenHeight, 0, 1)
        let D = TexVertex(screenWidth, screenHeight, 1, 1)
        
        let geometry = [ A, B, C, B, C, D ]
        
        memcpy(self.geometry.contents(), UnsafeRawPointer(geometry), MemoryLayout<TexVertex>.stride * 6)
    }
    
    func render(with renderEncoder: MTLRenderCommandEncoder) {
        let mtl = MetalController.instance
        
        var matrix = getMatrix()
        let len = MemoryLayout<matrix_float4x4>.stride
        
        // Draw Blur
        renderEncoder.pushDebugGroup("Blur")
        renderEncoder.setRenderPipelineState(mtl.pipeline.tex)
        
        renderEncoder.setFragmentTexture(mtl.textures.blurTextureDst, index: 0)
        renderEncoder.setFragmentSamplerState(mtl.textures.sampler, index: 0)
        
        renderEncoder.setVertexBuffer(self.geometry, offset: 0, index: 0)
        renderEncoder.setVertexBytes(&matrix, length: len, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.popDebugGroup()
    }
}
