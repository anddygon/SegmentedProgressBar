//
//  ViewWithPersistentAnimations.swift
//  SegmentedProgressBar
//
//  Created by 巩小鹏 on 2022/8/25.
//

import UIKit

class ViewWithPersistentAnimations : UIView {
    private var persistentAnimations: [String: CAAnimation] = [:]
    private var persistentSpeed: Float = 0.0


    @objc func willEnterForeground() {
        self.restoreAnimations(withKeys: Array(self.persistentAnimations.keys))
        self.persistentAnimations.removeAll()
        if self.persistentSpeed == 1.0 { //if layer was plaiyng before backgorund, resume it
            self.layer.resume()
        }
    }

    @objc func didEnterBackground() {
        self.persistentSpeed = self.layer.speed

        self.layer.speed = 1.0 //in case layer was paused from outside, set speed to 1.0 to get all animations
        self.persistAnimations(withKeys: self.layer.animationKeys())
        self.layer.speed = self.persistentSpeed //restore original speed
        self.layer.pause()
    }

    func persistAnimations(withKeys: [String]?) {
        withKeys?.forEach({ (key) in
            if let animation = self.layer.animation(forKey: key) {
                self.persistentAnimations[key] = animation
            }
        })
    }

    func restoreAnimations(withKeys: [String]?) {
        withKeys?.forEach { key in
            if let persistentAnimation = self.persistentAnimations[key] {
                self.layer.add(persistentAnimation, forKey: key)
            }
        }
    }
}
