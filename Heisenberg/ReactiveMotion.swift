//
//  ReactiveMotion.swift
//  Heisenberg
//
//  Created by Shameek Sarkar on 16/01/18.
//  Copyright © 2018 Shameek. All rights reserved.
//

import Foundation
import CoreMotion
import RxSwift

class ReactiveMotion {
    lazy var manager: CMMotionManager = {
        let manager = CMMotionManager()
        manager.deviceMotionUpdateInterval = 1 / 30
        return manager
    }()
    
    lazy var motionObservable: Observable<CMDeviceMotion> = {
        return Observable.create({ (observer) -> Disposable in
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            self.manager.startDeviceMotionUpdates(to: queue) { (motion, error) in
                guard let motion = motion else { return }
                observer.onNext(motion)
            }
            
            return Disposables.create {
                self.manager.stopDeviceMotionUpdates()
            }
        })
    }()
}
