//
//  ViewController.swift
//  Test
//
//  Created by 巩小鹏 on 2022/8/15.
//

import UIKit

class ViewController: UIViewController {
    let bar = SegmentedProgressBar.init(numberOfSegments: 6, duration: 3)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bar.frame = .init(x: 20, y: 200, width: view.frame.width - 2 * 20, height: 10)
        view.backgroundColor = UIColor.cyan
        bar.topColor = .white
        bar.bottomColor = .gray.withAlphaComponent(0.2)
        bar.padding = 8
        view.addSubview(bar)
        
        bar.delegate = self
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func onPauseTapped(_ sender: Any) {
        guard !bar.isPaused else { return }
        bar.isPaused = true
    }
    
    @IBAction func onResumeTapped(_ sender: Any) {
        guard bar.isPaused else { return }
        bar.isPaused = false
    }
    
    @IBAction func onGoToTapped(_ sender: Any) {
        let index = Int.random(in: 0..<6)
        bar.goto(index: index)
    }
    
    @IBAction func onStartTapped(_ sender: Any) {
        bar.startAnimation()
    }
    
    @IBAction func onResetTapped(_ sender: Any) {
        bar.reset()
    }
}

extension ViewController: SegmentedProgressBarDelegate {
    func segmentedProgressBarChangedIndex(index: Int, animated: Bool) {
        
    }
    
    func segmentedProgressBarFinished() {
        print("segmentedProgressBarFinished")
    }
}
