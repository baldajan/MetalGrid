//
//  GridObject.swift
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Basil Al-Dajane. All rights reserved.
//

import Foundation
import UIKit
import Metal

class GridObject {
    
    let geometryBuffer: MTLBuffer
    let indexBuffer:    MTLBuffer
    let constants:      [MTLBuffer]
    
    var objectsData: [ObjectData] = []
    
    let rowCount: Int = 5 // make sure it's odd
    let gridPad: Float = 10
    
    init(_ device: MTLDevice) {
        let gridCount = rowCount * rowCount
        
        self.geometryBuffer = device.makeBuffer(length: MemoryLayout<vector_float2>.stride * 4, options: [])!
        self.indexBuffer    = device.makeBuffer(length: MemoryLayout<UInt16>.stride * 6, options: [])!
        
        let constantsLength = MemoryLayout<ObjectConsts>.stride + MemoryLayout<ObjectData>.stride * gridCount
        self.constants      = [
            device.makeBuffer(length: constantsLength, options: [])!,
            device.makeBuffer(length: constantsLength, options: [])!,
            device.makeBuffer(length: constantsLength, options: [])!
        ]
        
        self.layoutChanged()
    }
    
    func layoutChanged() {
        let screenWidth  = Float(UIScreen.main.bounds.width)
        let screenHeight = Float(UIScreen.main.bounds.height)
        
        let minDim = min(screenWidth, screenHeight)
        let pad    = self.gridPad
        let dim    = (minDim - pad * Float(rowCount)) / Float(rowCount)
        
        do {
            let geometry = [
                vector_float2(pad / 2,       pad / 2),
                vector_float2(pad / 2 + dim, pad / 2),
                vector_float2(pad / 2,       pad / 2 + dim),
                vector_float2(pad / 2 + dim, pad / 2 + dim),
            ]
            
            let index: [UInt16] = [
                0, 1, 2,
                1, 2, 3
            ]
            
            memcpy(self.geometryBuffer.contents(), UnsafeRawPointer(geometry), MemoryLayout<vector_float2>.stride * 4)
            memcpy(self.indexBuffer.contents(), UnsafeRawPointer(index), MemoryLayout<UInt16>.stride * 6)
        }
    }
    
    func update(_ diff: CFTimeInterval) {
        let screenWidth  = Float(UIScreen.main.bounds.width)
        let screenHeight = Float(UIScreen.main.bounds.height)
        
        let gridCount = rowCount * rowCount
        let minDim = min(screenWidth, screenHeight)
        let pad    = self.gridPad
        let dim    = (minDim - pad * Float(rowCount)) / Float(rowCount)
        
        // Create & Buffer Object Consts
        var consts = ObjectConsts(matrix: getMatrix(), color: getColor(hex: 0xffffff, alpha: 0.35))
        memcpy(self.constants[0].contents(), &consts, MemoryLayout<ObjectConsts>.stride)
        
        // Create Object Data
        for i in 0..<gridCount {
            let origin = vector_float2(Float(i % 5) * (dim + pad),
                                       Float(i / 5) * (dim + pad))
            let data = ObjectData(offset: origin)
            
            objectsData.append(data)
        }
        
        let ptr = self.constants[0].contents() + MemoryLayout<ObjectConsts>.stride
        memcpy(ptr, UnsafeRawPointer(objectsData), MemoryLayout<ObjectData>.stride * gridCount)
    }
    
    func render(with renderEncoder: MTLRenderCommandEncoder, index: Int) {
        let mtl = MetalController.instance
        
        renderEncoder.pushDebugGroup("Grid")
        renderEncoder.setRenderPipelineState(mtl.pipeline.grid)
        
        renderEncoder.setVertexBuffer(self.geometryBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(self.constants[0], offset: 0, index: 1)
        renderEncoder.setVertexBuffer(self.constants[0], offset: MemoryLayout<ObjectConsts>.stride, index: 2)
        
        renderEncoder.drawIndexedPrimitives(type:              .triangle,
                                            indexCount:        6,
                                            indexType:         .uint16,
                                            indexBuffer:       self.indexBuffer,
                                            indexBufferOffset: 0,
                                            instanceCount:     self.rowCount * self.rowCount)
        renderEncoder.popDebugGroup()
    }
}
