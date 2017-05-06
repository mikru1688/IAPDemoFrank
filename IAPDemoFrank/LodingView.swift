//
//  LodingView.swift
//  IAPDemo
//
//  Created by Frank.Chen on 2017/5/4.
//  Copyright © 2017年 Frank.Chen. All rights reserved.
//

import UIKit

class LodingView: UIView {
    
    var indicator: UIActivityIndicatorView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.indicator = self.getIndicatorView(frame)
        self.addSubview(self.indicator)
        self.indicator.startAnimating()
        self.backgroundColor = UIColor(white: 0.0, alpha: 0)
        self.isUserInteractionEnabled = true // 吃事件
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    func getIndicatorView(_ frame: CGRect) -> UIActivityIndicatorView{
        let indicator: UIActivityIndicatorView = UIActivityIndicatorView()
        indicator.tintColor = UIColor.white
        indicator.alpha = 1
        indicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        indicator.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        return indicator
    }
    
    deinit {        
        self.indicator.stopAnimating()
    }
    
}
