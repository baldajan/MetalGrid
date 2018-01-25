//
//  ViewController.swift
//  MetalGrid
//
//  Created by Basil Al-Dajane on 2018-01-25.
//  Copyright © 2018 Basil Al-Dajane. All rights reserved.
//

import UIKit
import Metal
import MetalKit

class ViewController: UIViewController {

    private var metalView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func loadView() {
        let mtl = MetalController.instance
        
        let screenRect = UIScreen.main.bounds
        self.metalView = MTKView(frame: screenRect, device: mtl.device)
        mtl.setup(with: self.metalView)
        
        self.view = self.metalView
    }
    
}

