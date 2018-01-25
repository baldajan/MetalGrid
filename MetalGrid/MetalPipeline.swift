//
//  MetalPipeline.swift
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Basil Al-Dajane. All rights reserved.
//

import Foundation
import Metal

class MetalPipeline {
    
    var simple:  MTLRenderPipelineState! = nil
    var objects: MTLRenderPipelineState! = nil
    var overlay: MTLRenderPipelineState! = nil
    var tex:     MTLRenderPipelineState! = nil
    
    init(_ parent: MetalController) {
        
        let descriptors = [
            PipelineDesc("Simple",   kernel: "simple",   result: {self.simple   = $0}),
            //PipelineDesc("Color",   kernel: "color",   result: {self.color   = $0}),
            //PipelineDesc("Overlay", kernel: "overlay", result: {self.overlay = $0}),
            //PipelineDesc("Tex",     kernel: "tex",     result: {self.tex     = $0}),
        ]

        for desc in descriptors {
            desc.load(with: parent.device, library: parent.library)
        }
    }
}

fileprivate struct PipelineDesc {
    var label: String
    var vertex: String
    var frag: String
    var format: MTLPixelFormat
    var result: (MTLRenderPipelineState) -> Void
    
    init(_ label: String, kernel: String, format: MTLPixelFormat = .bgra8Unorm, result: @escaping (MTLRenderPipelineState) -> Void) {
        self.init(label, vertex: kernel, frag: kernel, format: format, result: result)
    }
    
    init(_ label: String, vertex: String, frag: String, format: MTLPixelFormat = .bgra8Unorm, result: @escaping (MTLRenderPipelineState) -> Void) {
        self.label  = label
        self.vertex = vertex
        self.frag   = frag
        self.format = format
        self.result = result
    }
    
    func load(with device: MTLDevice, library: MTLLibrary) {
        let vertex = library.makeFunction(name: "v_" + self.vertex)
        let fragment = library.makeFunction(name: "f_" + self.frag)
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.label = self.label
        pipelineDesc.vertexFunction = vertex
        pipelineDesc.fragmentFunction = fragment
        
        let renderbufferAttch = pipelineDesc.colorAttachments[0]!
        renderbufferAttch.pixelFormat = self.format
        renderbufferAttch.isBlendingEnabled = true
        renderbufferAttch.sourceRGBBlendFactor = .sourceAlpha
        renderbufferAttch.sourceAlphaBlendFactor = .one
        renderbufferAttch.destinationRGBBlendFactor = .oneMinusSourceAlpha
        renderbufferAttch.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        let pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDesc)
        self.result(pipelineState)
    }
}

