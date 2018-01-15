//
//  SwingView.swift
//  Heisenberg
//
//  Created by Shameek Sarkar on 15/01/18.
//  Copyright © 2018 Shameek. All rights reserved.
//

import UIKit
import CoreMotion

class SwingView: UIView {
    var mosaicImage: UIImageView!
    var isDebug = false
    
    var imageIndex: Int = 30
    var lastRoll: Int = 0
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
    }
    
    override func layoutSubviews() {
        mosaicImage.frame = CGRect(x: xOrigin, y: yOrigin, width: frame.width * 10, height: frame.height * 6)
    }
    
    func update(motion: CMDeviceMotion?) {
        guard let motion = motion else { return }
        let roll = Int(motion.attitude.roll * 100)
        if abs(roll - lastRoll) > 1 {
            let direction = (lastRoll - roll) > 0 ? 1 : -1
            imageIndex = max(min(59, imageIndex + direction), 0)
            mosaicImage.frame.origin = CGPoint(x: xOrigin, y: yOrigin)
            lastRoll = roll
        }
    }
}
