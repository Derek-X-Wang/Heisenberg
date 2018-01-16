//
//  SwingView.swift
//  Heisenberg
//
//  Created by Shameek Sarkar on 15/01/18.
//  Copyright © 2018 Shameek. All rights reserved.
//

import UIKit
import RxSwift
import CoreMotion


class SwingView: UIView {
    var disposeBag = DisposeBag()
    var mosaicImage: UIImageView!
    
    var isDebug = false
    var lastRoll: Int = 0
    var imageIndex: Int = 30
    var motion = PublishSubject<CMDeviceMotion>()
    
    var xOrigin: CGFloat {
        return CGFloat(imageIndex % 10) * -self.frame.width
    }
    
    var yOrigin: CGFloat {
        return CGFloat(imageIndex / 10) * -self.frame.height
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _init()
    }
    
    func _init() {
        mosaicImage = UIImageView(frame: .zero)
        mosaicImage.contentMode = .scaleAspectFit
        mosaicImage.image = #imageLiteral(resourceName: "mosaic")
        addSubview(mosaicImage)
        
        clipsToBounds = !isDebug
        if isDebug {
            let borderView = UIView(frame: self.bounds)
            borderView.layer.borderColor = UIColor.red.cgColor
            borderView.layer.borderWidth = 2
            addSubview(borderView)
        }
        
        motion.asObservable()
            .map({ Int($0.attitude.roll * 1000) })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (roll) in
            if abs(roll - self.lastRoll) > 10 {
                let direction = (self.lastRoll - roll) > 0 ? 1 : -1
                self.imageIndex = max(min(59, self.imageIndex + direction), 0)
                self.mosaicImage.frame.origin = CGPoint(x: self.xOrigin, y: self.yOrigin)
                self.lastRoll = roll
            }
        }).disposed(by: disposeBag)
    }
    
    override func layoutSubviews() {
        mosaicImage.frame = CGRect(x: xOrigin, y: yOrigin, width: frame.width * 10, height: frame.height * 6)
    }
}
