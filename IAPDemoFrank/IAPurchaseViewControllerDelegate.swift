//
//  didBuySomething.swift
//  IAPDemo
//
//  Created by Frank.Chen on 2017/5/1.
//  Copyright © 2017年 Frank.Chen. All rights reserved.
//

import Foundation

protocol IAPurchaseViewControllerDelegate {
    func didBuySomething(_ iapViewController: IAPViewController, _ product: Product)
}
