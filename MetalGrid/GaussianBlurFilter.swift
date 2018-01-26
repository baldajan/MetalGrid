//
//  GaussianBlurFilter.swift
//  Medly
//
//  Created by Basil Al-Dajane on 2017-01-30.
//  Copyright © 2017 Basil Al-Dajane. All rights reserved.
//

import Foundation
import Metal
import MetalPerformanceShaders


class GaussianBlurFilter {
    
    private let parent: MetalController
    
    private let useMPS: Bool
    private let blurMPS: MPSImageGaussianBlur?
    
    private let downKernelFunc: MTLFunction?
    private let downKernalPipe: MTLComputePipelineState?
    private let blurKernelFunc: MTLFunction?
    private let blurKernalPipe: MTLComputePipelineState?
    private var blurKernalTex:  MTLTexture?
    
    
    init(_ parent: MetalController, _ library: MTLLibrary) {
        self.parent = parent
        
        self.useMPS = parent.device.supportsFeatureSet(.iOS_GPUFamily2_v2)
        
        if self.useMPS {
            self.blurMPS = MPSImageGaussianBlur(device: self.parent.device, sigma: 7)
            self.blurMPS!.edgeMode = .clamp
            
            self.downKernelFunc = nil
            self.downKernalPipe = nil
            self.blurKernelFunc = nil
            self.blurKernalPipe = nil
        } else {
            self.blurMPS = nil
            
            self.downKernelFunc = library.makeFunction(name: "k_quarter_down")
            self.downKernalPipe = try? self.parent.device.makeComputePipelineState(function: self.downKernelFunc!)
            if self.downKernalPipe == nil { print("problem creating the pipeline state") }
            self.blurKernelFunc = library.makeFunction(name: "k_gaussian_blur")
            self.blurKernalPipe = try? self.parent.device.makeComputePipelineState(function: self.blurKernelFunc!)
            if self.blurKernalPipe == nil { print("problem creating the pipeline state") }
            
            generateBlurWeightTexture()
        }
    }
    
    private func generateBlurWeightTexture() {
        guard let device = self.parent.device else { return }
        
        let sigma:    Float = 2
        let radius:   Float = 8
        let size:     Int   = Int(round(radius) * 2.0) + 1
        let delta:    Float = (radius * 2.0) / (Float(size) - 1.0)
        let expScale: Float = -1.0 / (2.0 * sigma * sigma)
        
        var weights = [Float](repeating: 0, count: size * size)
        var weightSum: Float = 0
        var y: Float = -radius
        
        for j in 0..<size {
            var x = -radius
            
            for i in 0..<size {
                let weight: Float = exp((x * x + y * y) * expScale);
                weights[j * size + i] = weight
                weightSum += weight
                x += delta
            }
            
            y += delta
        }
        
        let weightScale: Float = 1.0 / weightSum
        for j in 0..<size {
            for i in 0..<size {
                weights[j * size + i] *= weightScale
            }
        }
        
        let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float,
                                                               width:       size,
                                                               height:      size,
                                                               mipmapped:   false)
        self.blurKernalTex = device.makeTexture(descriptor: texDesc)
        
        // Load data to texture
        let region = MTLRegionMake2D(0, 0, size, size)
        self.blurKernalTex?.replace(region: region, mipmapLevel: 0, withBytes: weights, bytesPerRow: MemoryLayout<Float>.stride * size)
    }
    
    func encode(commandBuffer: MTLCommandBuffer, sourceTexture: MTLTexture, destinationTexture: MTLTexture) {
        if self.useMPS {
            self.blurMPS?.encode(commandBuffer: commandBuffer, sourceTexture: sourceTexture, destinationTexture: destinationTexture)
        }
        else {
            let texDown = MetalController.instance.textures.blurTextureDown!
            
            // Downsample
            do {
                let stride = MTLSizeMake(4, 4, 1)
                let threadgroupCounts = MTLSizeMake(8, 8, 1)
                let threadgroups = MTLSizeMake(sourceTexture.width  / threadgroupCounts.width / stride.width,
                                               sourceTexture.height / threadgroupCounts.height / stride.height,
                                               1)
                
                let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
                
                commandEncoder.setComputePipelineState(self.downKernalPipe!)
                commandEncoder.setTexture(sourceTexture, index: 0)
                commandEncoder.setTexture(texDown, index: 1)
                
                commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
                commandEncoder.endEncoding()
            }
            
            do {
                let stride = MTLSizeMake(1, 1, 1)
                let threadgroupCounts = MTLSizeMake(8, 8, 1)
                let threadgroups = MTLSizeMake(texDown.width  / threadgroupCounts.width  / stride.width,
                                               texDown.height / threadgroupCounts.height / stride.height,
                                               1)
                
                let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
                
                commandEncoder.setComputePipelineState(self.blurKernalPipe!)
                commandEncoder.setTexture(texDown,       index: 0)
                commandEncoder.setTexture(destinationTexture,  index: 1)
                commandEncoder.setTexture(self.blurKernalTex!, index: 2)
                
                commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupCounts)
                commandEncoder.endEncoding()
            }
        }
    }
}
