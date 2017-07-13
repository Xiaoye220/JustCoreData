//
//  FPSView.swift
//  CardWatch
//
//  Created by 叶增峰 on 27/4/17.
//  Copyright © 2017年 叶增峰. All rights reserved.
//

import UIKit

class FPSView: UIView {

    private var fpsLabel: UILabel!
    private var link: CADisplayLink!
    private var lastTime: TimeInterval = 0
    private var count = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupFpsLabel()
        setupDisplayLink()
    }
    
    convenience init() {
        self.init(frame: CGRect.init(x: UIScreen.main.bounds.width - 90, y: 20, width: 80, height: 30))
        self.center = CGPoint.init(x: UIScreen.main.bounds.width / 2, y: 40)
    }
    
    private func setupFpsLabel() {
        fpsLabel = UILabel.init(frame: frame)
        fpsLabel.center = CGPoint.init(x: frame.width / 2, y: frame.height / 2)
        fpsLabel.layer.cornerRadius = 5
        fpsLabel.clipsToBounds = true
        fpsLabel.textAlignment = .center
        fpsLabel.isUserInteractionEnabled = false
        fpsLabel.backgroundColor = UIColor.init(white: 0, alpha: 0.7)
        addSubview(fpsLabel)
    }
    
    private func setupDisplayLink() {
        link = CADisplayLink.init(target: self, selector: #selector(tick(_:)))
        link.add(to: RunLoop.main, forMode: .commonModes)
    }
    
    @objc private func tick(_ link: CADisplayLink) {
        if lastTime == 0 {           //对LastTime进行初始化
            lastTime = link.timestamp
            return
        }
        
        count += 1   //记录tick在1秒内执行的次数
        let delta = link.timestamp - self.lastTime;  //计算本次刷新和上次更新FPS的时间间隔
        
        //大于等于1秒时，来计算FPS
        if delta >= 1 {
            lastTime = link.timestamp
            let fps = Float(count) / Float(delta)      // 次数 除以 时间 = FPS （次/秒）
            count = 0
            updateDisplayLabelText(fps: fps)
        }
    }
    
    
    private func updateDisplayLabelText(fps: Float) {
        let progress = fps / 60.0
        let color = UIColor.init(hue: CGFloat(0.27 * (progress - 0.2)), saturation: 1, brightness: 0.9, alpha: 1)
        fpsLabel.text = String(Int(fps)) + " FPS"
        //[NSString stringWithFormat:@"%d FPS",(int)round(fps)];
        fpsLabel.textColor = color
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
