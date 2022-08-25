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
    private var whenRestoredAnimationFinished: (() -> Void)?


    @objc func willEnterForeground(completion: (() -> Void)?) {
        self.restoreAnimations(withKeys: Array(self.persistentAnimations.keys), completion: completion)
        self.persistentAnimations.removeAll()
        if self.persistentSpeed == 1.0 { // if layer was plaiyng before backgorund, resume it
            self.layer.resume()
        }
    }

    @objc func didEnterBackground() {
        self.persistentSpeed = self.layer.speed

        self.layer.speed = 1.0 // in case layer was paused from outside, set speed to 1.0 to get all animations
        self.persistAnimations(withKeys: self.layer.animationKeys())
        self.layer.speed = self.persistentSpeed //restore original speed
        self.layer.pause()
    }

    func persistAnimations(withKeys: [String]?) {
        withKeys?.forEach({ (key) in
            // 这里必须进行mutable copy 否则会崩溃
            if let animation = self.layer.animation(forKey: key)?.mutableCopy() as? CAAnimation {
                self.persistentAnimations[key] = animation
                animation.delegate = self
            }
        })
    }

    func restoreAnimations(withKeys: [String]?, completion: (() -> Void)?) {
        whenRestoredAnimationFinished = completion
        
        withKeys?.forEach { key in
            if let persistentAnimation = self.persistentAnimations[key] {
                self.layer.add(persistentAnimation, forKey: key)
            }
        }
    }
    
    func willResignActive() {
        layer.pause()
    }
    
    func didBecomeActive() {
        if layer.isPaused() {
            layer.resume()
        }
    }
}

extension ViewWithPersistentAnimations: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            whenRestoredAnimationFinished?()
            // 因为多个动画的代理结束都会走到这里 防止重复调用
            whenRestoredAnimationFinished = nil
        }
    }
}
