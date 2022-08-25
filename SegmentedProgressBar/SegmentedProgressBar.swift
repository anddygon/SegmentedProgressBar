//
//  SegmentedProgressBar.swift
//  SegmentedProgressBar
//
//  Created by 巩小鹏 on 2022/8/25.
//

import UIKit

protocol SegmentedProgressBarDelegate: AnyObject {
    func segmentedProgressBarChangedIndex(index: Int, animated: Bool)
    func segmentedProgressBarFinished()
}

class SegmentedProgressBar: UIView {
    weak var delegate: SegmentedProgressBarDelegate?
    var topColor = UIColor.gray {
        didSet {
            self.updateColors()
        }
    }
    var bottomColor = UIColor.gray.withAlphaComponent(0.25) {
        didSet {
            self.updateColors()
        }
    }
    var extraVerticalTouchInset: CGFloat = -8
    var isLoop: Bool = true
    var padding: CGFloat = 8.0
    var isPaused: Bool = false {
        didSet {
            if isPaused {
                for segment in segments {
                    let layer = segment.topSegmentView.layer
                    layer.pause()
                }
            } else {
                currentSegment.topSegmentView.layer.resume()
            }
        }
    }
    
    private var segments = [Segment]()
    private let duration: TimeInterval
    private var hasDoneLayout = false // hacky way to prevent layouting again
    private var currentAnimationIndex = 0
    private var isAnimating = false
    
    
    init(numberOfSegments: Int, duration: TimeInterval = 5.0) {
        self.duration = duration
        super.init(frame: CGRect.zero)
        
        for _ in 0..<numberOfSegments {
            let segment = Segment()
            addSubview(segment.bottomSegmentView)
            addSubview(segment.topSegmentView)
            segments.append(segment)
        }
        self.updateColors()
        self.setupGesture()
        self.aotoHandleBackground()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if hasDoneLayout {
            return
        }
        let width = (frame.width - (padding * CGFloat(segments.count - 1)) ) / CGFloat(segments.count)
        for (index, segment) in segments.enumerated() {
            let segFrame = CGRect(x: CGFloat(index) * (width + padding), y: 0, width: width, height: frame.height)
            segment.bottomSegmentView.frame = segFrame
            segment.topSegmentView.frame = segFrame
            segment.topSegmentView.frame.size.width = 0
            
            let cr = frame.height / 2
            segment.bottomSegmentView.layer.cornerRadius = cr
            segment.topSegmentView.layer.cornerRadius = cr
        }
        hasDoneLayout = true
    }
    
    func startAnimation() {
        layoutSubviews()
        
        if !isAnimating {
            isAnimating = true
            animate()
        }
    }
    
    private func animate(animationIndex: Int = 0) {
        let nextSegment = segments[animationIndex]
        currentAnimationIndex = animationIndex
        self.isPaused = false // no idea why we have to do this here, but it fixes everything :D
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
            nextSegment.topSegmentView.frame.size.width = nextSegment.bottomSegmentView.frame.width
        }, completion: { [weak self] (finished) in
            guard let self = self else { return }
            if !finished {
                return
            }
            self.next()
        })
    }
    
    private func updateColors() {
        for segment in segments {
            segment.topSegmentView.backgroundColor = topColor
            segment.bottomSegmentView.backgroundColor = bottomColor
        }
    }
    
    private func next() {
        let newIndex = self.currentAnimationIndex + 1
        if newIndex < self.segments.count {
            self.animate(animationIndex: newIndex)
            self.delegate?.segmentedProgressBarChangedIndex(index: newIndex, animated: true)
        } else {
            self.delegate?.segmentedProgressBarFinished()
            if isLoop {
                segments.forEach { segment in
                    segment.topSegmentView.layer.removeAllAnimations()
                    segment.topSegmentView.frame.size.width = 0
                }
                animate()
            }
        }
    }
    
    func goto(index: Int, callDelegate: Bool = true) {
        let index = max(0, min(index, segments.count))
        for i in 0..<segments.count {
            let currentSegment = segments[i]
            // 移除正在进行的动画
            currentSegment.topSegmentView.layer.removeAllAnimations()
            let width = i <= index ? currentSegment.bottomSegmentView.frame.width : 0
            currentSegment.topSegmentView.frame.size.width = width
        }
        currentAnimationIndex = index
        isAnimating = false
        if callDelegate {
            self.delegate?.segmentedProgressBarChangedIndex(index: index, animated: false)
        }
    }
    
    func reset() {
        currentAnimationIndex = 0
        isAnimating = false
        
        segments.forEach { segment in
            segment.topSegmentView.layer.removeAllAnimations()
            segment.topSegmentView.frame.size.width = 0
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension SegmentedProgressBar {
    private var currentSegment: Segment {
        return segments[currentAnimationIndex]
    }
    
    func aotoHandleBackground() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive),
                                               name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func willEnterForeground() {
        currentSegment.topSegmentView.willEnterForeground { [weak self] in
            self?.next()
        }
    }
    
    @objc func didEnterBackground() {
        currentSegment.topSegmentView.didEnterBackground()
    }
    
    @objc func willResignActive() {
        currentSegment.topSegmentView.willResignActive()
    }
    
    @objc func didBecomeActive() {
        currentSegment.topSegmentView.didBecomeActive()
    }
}

extension SegmentedProgressBar {
    private func setupGesture() {
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(onTapped(gesture:)))
        addGestureRecognizer(tap)
    }
    
    @objc private func onTapped(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        if let index = segments.firstIndex(where: { ($0.bottomSegmentView.frame.minX...$0.bottomSegmentView.frame.maxX).contains(point.x) }) {
            goto(index: index)
        }
    }
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: 0, dy: extraVerticalTouchInset).contains(point)
    }
}

private class Segment {
    let bottomSegmentView = UIView()
    let topSegmentView = ViewWithPersistentAnimations()
    
    
    init() {
        
    }
}
