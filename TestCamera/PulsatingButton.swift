//
//  PulsatingButton.swift
//  TestCamera
//
//  Created by Ksenia on 03.05.2021.
//

import UIKit

final class PulsatingButton: UIButton {
    func startPulsatiion() {
        DispatchQueue.main.async {

            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 1
            animation.toValue = 0.5
            animation.duration = 0.4
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.layer.add(animation, forKey: "pulse")
        }
    }
    
    func stopPulsation() {
        DispatchQueue.main.async {

            self.layer.removeAllAnimations()
        }
    }
}
