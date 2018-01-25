//
//  MetalRenderer.swift
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Medly Labs Inc. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import QuartzCore

class MetalRenderer {
    
    private let parent: MetalController
    private let dispatchQueue = DispatchQueue(label: "com.medlylabs.metal.renderer", attributes: .concurrent)
    
    init(_ parent: MetalController) {
        self.parent = parent
    }
    
    func render(at index: Int, _ completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()
        
        // Create Command Buffers
        let backBuffer = self.parent.commandQueue.makeCommandBuffer()!
        let blurBuffer = self.parent.commandQueue.makeCommandBuffer()!
        let mainBuffer = self.parent.commandQueue.makeCommandBuffer()!
        
        backBuffer.enqueue()
        blurBuffer.enqueue()
        mainBuffer.enqueue()
        
        
        // Render to texture
        dispatchGroup.enter()
        self.dispatchQueue.async {
            let texture = self.parent.textures.blurTextureSrc!
            self.renderToTexture(commandBuffer: backBuffer, texture: texture, block: { renderEncoder in
                self.parent.background.render(with: renderEncoder)
                self.parent.grid.render(with: renderEncoder, index: index)
            })
            
            backBuffer.commit()
            dispatchGroup.leave()
        }
        
        // Blur
        dispatchGroup.enter()
        self.dispatchQueue.async {
            let textureSrc = self.parent.textures.blurTextureSrc!
            let textureDst = self.parent.textures.blurTextureDst!
            let blur       = self.parent.pipeline.blur
            
            blur.encode(commandBuffer: blurBuffer, sourceTexture: textureSrc, destinationTexture: textureDst)
            
            blurBuffer.commit()
            dispatchGroup.leave()
        }
        
        // Render to screen
        dispatchGroup.enter()
        self.dispatchQueue.async {
            self.renderToScreen(commandBuffer: mainBuffer, block: { renderEncoder in
                self.parent.background.render(with: renderEncoder)
                self.parent.grid.render(with: renderEncoder, index: index)
                self.parent.blur.render(with: renderEncoder)
            })
            
            mainBuffer.addCompletedHandler { _ in
                completion()
            }
            
            mainBuffer.commit()
            dispatchGroup.leave()
        }
        
        // Now Wait
        _ = dispatchGroup.wait(timeout: DispatchTime.distantFuture)
        
        // Use For `presentWithTransaction`
        if let view = MetalController.instance.metalView,
            let drawable = view.currentDrawable,
            view.presentsWithTransaction
        {
            mainBuffer.waitUntilScheduled()
            drawable.present()
        }
    }
    
    //
    // MARK: - Private Rendering Methods
    private func renderToScreen(commandBuffer: MTLCommandBuffer, block: (MTLRenderCommandEncoder) -> Void) {
        guard let view = MetalController.instance.metalView else { return }
        guard let descriptor = view.currentRenderPassDescriptor else { return }
        
        // Create Encoder
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        
        // Render
        block(renderEncoder)
        
        // We are finished with this render command encoder, so end it.
        renderEncoder.endEncoding()
        
        // Tell the system to present the cleared drawable to the screen.
        if let drawable = view.currentDrawable, !view.presentsWithTransaction {
            commandBuffer.present(drawable)
        }
    }
    
    private func renderToTexture(commandBuffer: MTLCommandBuffer, texture: MTLTexture, clear: Bool = false, block: (MTLRenderCommandEncoder) -> Void) {
        let renderDesc = MTLRenderPassDescriptor()
        renderDesc.colorAttachments[0].texture = texture
        renderDesc.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, clear ? 0 : 1)
        renderDesc.colorAttachments[0].loadAction = .clear
        renderDesc.colorAttachments[0].storeAction = .store
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDesc)!
        
        // Render block
        block(renderEncoder)
        
        // We are finished with this render command encoder, so end it.
        renderEncoder.endEncoding()
    }
}
