//
//  SwingController.swift
//  Heisenberg
//
//  Created by Shameek Sarkar on 15/01/18.
//  Copyright © 2018 Shameek. All rights reserved.
//

import UIKit
import RxSwift

class SwingController: UIViewController {
    let motion = ReactiveMotion()
    var motionDisposable: Disposable?
    @IBOutlet weak var swingView: SwingView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        motionDisposable = motion.motionObservable.bind(to: swingView.motion)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        motionDisposable?.dispose()
    }
}
