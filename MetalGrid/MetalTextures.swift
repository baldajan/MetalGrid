//
//  MetalTextures.swift
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Basil Al-Dajane. All rights reserved.
//

import Foundation
import UIKit
import Metal

class MetalTextures {
    
    private let parent: MetalController
    let sampler: MTLSamplerState
    
    var blurTextureSrc:  MTLTexture?
    var blurTextureDown: MTLTexture?
    var blurTextureDst:  MTLTexture?
    
    init(_ parent: MetalController) {
        self.parent = parent
        
        // Setup Sampler
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        
        self.sampler = self.parent.device.makeSamplerState(descriptor: samplerDescriptor)!
        
        self.layoutChanged()
    }
    
    func layoutChanged() {
        let useMPS       = self.parent.device.supportsFeatureSet(.iOS_GPUFamily2_v2)
        let screenWidth  = Int(UIScreen.main.bounds.width)
        let screenHeight = Int(UIScreen.main.bounds.height)
        
        let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                               width:  screenWidth,
                                                               height: screenHeight,
                                                               mipmapped: false)
        texDesc.usage = [.renderTarget, .shaderRead, .shaderWrite]
        
        self.blurTextureSrc = self.parent.device.makeTexture(descriptor: texDesc)
        
        if useMPS {
            self.blurTextureDst = self.parent.device.makeTexture(descriptor: texDesc)
        } else {
            texDesc.width  = (texDesc.width / 4)
            texDesc.height = (texDesc.height / 4)
            
            self.blurTextureDst  = self.parent.device.makeTexture(descriptor: texDesc)
            self.blurTextureDown = self.parent.device.makeTexture(descriptor: texDesc)
        }

    }
}
