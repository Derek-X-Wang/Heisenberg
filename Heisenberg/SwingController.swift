//
//  SwingController.swift
//  Heisenberg
//
//  Created by Shameek Sarkar on 15/01/18.
//  Copyright © 2018 Shameek. All rights reserved.
//

import UIKit
import CoreMotion

class SwingController: UIViewController {
    
    @IBOutlet weak var swingView: SwingView!
    let manager = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager.deviceMotionUpdateInterval = 1 / 60
    }
    
    override func viewDidAppear(_ animated: Bool) {
        manager.startDeviceMotionUpdates(to: OperationQueue.main) { (motion, error) in
            self.swingView.update(motion: motion)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        manager.stopDeviceMotionUpdates()
    }
}
