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
    
    let rowCount: Int = 5
    let gridPad: Float = 10
    let outerPad: Float = 200
    
    var time: CFTimeInterval = 0
    
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
        
        let minDim = min(screenWidth, screenHeight) - outerPad
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
        // Create & Buffer Object Consts
        var consts = ObjectConsts(matrix: getMatrix(), color: getColor(hex: 0xffffff, alpha: 0.35))
        memcpy(self.constants[0].contents(), &consts, MemoryLayout<ObjectConsts>.stride)

        // Create Object Data
        let screenWidth  = Float(UIScreen.main.bounds.width)
        let screenHeight = Float(UIScreen.main.bounds.height)
        
        let gridCount = rowCount * rowCount
        let minDim = min(screenWidth, screenHeight) - outerPad
        let pad    = self.gridPad
        let dim    = (minDim - pad * Float(rowCount)) / Float(rowCount)
        
        let xOffset = (screenWidth  - minDim) / 2.0
        let yOffset = (screenHeight - minDim) / 2.0
        
        var objectsData: [ObjectData] = []
        objectsData.reserveCapacity(gridCount)
        
        // Create Origins
        for i in 0..<gridCount {
            let origin = vector_float2(Float(i % rowCount) * (dim + pad) + xOffset,
                                       Float(i / rowCount) * (dim + pad) + yOffset)
            objectsData.append(ObjectData(offset: origin))
        }
        
        // Animate Origins
        let cycleDistance: Float = 100
        let cycleDuration: Float = 0.5
        let colPhaseOffset = Float.pi / Float(rowCount)
        
        time += diff
        
        for i in 0..<gridCount {
            var newObj = objectsData[i]
            let col = Float(i % rowCount)
            newObj.offset.y += cycleDistance * sin((Float(time) * (2 * Float.pi / cycleDuration) + colPhaseOffset * col))
            objectsData[i] = newObj
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
