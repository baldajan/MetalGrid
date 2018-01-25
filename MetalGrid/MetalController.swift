//
//  MetalController.swift
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Basil Al-Dajane. All rights reserved.
//

import Foundation
import Metal
import MetalKit

class MetalController: NSObject, MTKViewDelegate {
    
    static let instance = MetalController()
    
    // Metal Objects
    weak var metalView: MTKView?
    
    var device:       MTLDevice!
    var commandQueue: MTLCommandQueue!
    var library:      MTLLibrary!
    
    // Custom Metal Objects
    var pipeline:   MetalPipeline!
    var renderer:   MetalRenderer!
    var background: Background!
    var grid:       GridObject!
    
    // Timing Objects
    var timer: CADisplayLink! = nil
    private var lastFrameTimeStamp: CFTimeInterval = 0.0
    
    // Triple Buffer Objects & Methods
    var queue = [(() -> Void)]()
    
    static  let MaxBufferCount = 3
    private var bufferIndex = 0
    private var semaphore = DispatchSemaphore(value: MetalController.MaxBufferCount)
    private var activeIndex = 0
    
    func getBufferIndex() -> Int {
        assert(self.bufferIndex == self.activeIndex)
        return self.bufferIndex
    }
    
    
    //
    // Create Metal Device in init
    override init() {
        self.device = MTLCreateSystemDefaultDevice()
        super.init()
    }
    
    // MARK: - Setup
    // Perform setup of MetalController and MetalView once
    // main UIViewController is ready
    func setup(with mtkView: MTKView) {
        
        // Setup Metal View
        self.metalView = mtkView
        mtkView.sampleCount = 1
        mtkView.autoResizeDrawable = true
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.delegate = self
        mtkView.isPaused = false
        
        // For ProMotion displays
        if #available(iOS 10.3, *) {
            mtkView.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        }
        
        // Visual Sync with UIKit Animations
        // When `presentsWithTransaction` is on, framerate will not be
        // displayed in XCode. So we only turn it on during release builds.
        #if DEBUG
            mtkView.presentsWithTransaction = false
        #else
            mtkView.presentsWithTransaction = true
        #endif
        
        
        // Remaining Metal Objects
        self.commandQueue = self.device.makeCommandQueue()!
        self.library      = self.device.makeDefaultLibrary()!
        
        self.pipeline     = MetalPipeline(self)
        self.renderer     = MetalRenderer(self)
        
        self.background   = Background(device)
        self.grid         = GridObject(device)
    }
    
    
    //
    // MARK: - MTKViewDelegate Methods
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Update layout here
        
//        if self.textures == nil { return }
//        self.queue.append {
//            self.textures.layoutChanged()
//            SessionController.instance.layoutChanged()
//        }
    }
    
    func draw(in view: MTKView) {
        _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
        self.activeIndex = self.bufferIndex
        
        // Consolidate buffers first
        let timestamp = CFAbsoluteTimeGetCurrent()
        let diff = min(timestamp - lastFrameTimeStamp, 1.0)
        lastFrameTimeStamp = timestamp
        
        executeQueue()
        update(diff)
        
        let bufferIndex = self.bufferIndex
        autoreleasepool {
            self.renderer.render(at: bufferIndex, {
                self.semaphore.signal()
            })
        }
        
        self.bufferIndex = (self.bufferIndex + 1) % MetalController.MaxBufferCount
    }
    
    private func update(_ diff: CFTimeInterval) {
        
        
//        self.scissor.update(diff)
//
//        WindowController.instance()!.update(diff)
//
//        AudioController.instance().playback.update(diff)
//        SessionController.instance.update(diff)
//        SectionController.instance.update(diff)
    }
    
    private func executeQueue() {
        let queue = self.queue; self.queue.removeAll()
        for block in queue { block() }
    }
}
