//
//  ViewController.swift
//  IAPDemoFrank
//
//  Created by Frank.Chen on 2017/5/5.
//  Copyright © 2017年 Frank.Chen. All rights reserved.
//

import UIKit

class ViewController: UIViewController, IAPurchaseViewControllerDelegate {
    
    var userDefault: UserDefaults = UserDefaults.standard

    @IBOutlet weak var chatSwitch: UISwitch!
    @IBOutlet weak var coinCountLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 將購買資訊的初始值存放在 UserDefaults
        if self.userDefault.object(forKey: "consumablePurchase") == nil || self.userDefault.object(forKey: "nonConsumablePurchase") == nil {
            
            self.userDefault.setValue(0, forKey: "consumablePurchase") // 消費性產品，可透過重覆購買來增加數量
            self.userDefault.setValue("N", forKey: "nonConsumablePurchase") // 非消費性產品，購買一次後該帳號將永遠免費。重覆購買時 Apple 會自動判斷該帳號是否已購買過，並不會重覆付費
        }
        
        // 更新當前金幣、可否使用聊天功能
        self.setLabelValue()

    }

    // MARK: - Callback
    // ---------------------------------------------------------------------    
    // 更新當前金幣、可否使用聊天功能
    func setLabelValue() {
        self.coinCountLabel.text = "\(self.userDefault.object(forKey: "consumablePurchase")!)"
        
        self.chatSwitch.isOn = self.userDefault.string(forKey: "nonConsumablePurchase") == "N" ? false : true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueIAP" {
            let iapViewController = segue.destination as! IAPViewController
            iapViewController.delegate = self
        }
    }
    
    // MARK: - Delegate
    // ----------------------------------------------------------------------------------------------
    // 處理完付款的動作的 protocol，更新當前金幣、可否使用聊天功能
    func didBuySomething(_ iAPurchaceViewController: IAPViewController, _ product: Product) {
        // 更新 UserDefaule 的值
        switch product {
        case .consumable:
            // 購買消耗性產品
            self.userDefault.setValue(self.userDefault.integer(forKey: "consumablePurchase") + 10, forKey: "consumablePurchase")
        case .nonConsumable:
            // 購買非消耗性產品
            self.userDefault.setValue("Y", forKey: "nonConsumablePurchase")
        case .restore:
            // 回復
            self.userDefault.setValue("Y", forKey: "nonConsumablePurchase")
        }
        
        // 更新當前金幣、可否使用聊天功能
        self.setLabelValue()        
    }
}

enum Product {
    case consumable
    case nonConsumable
    case restore
}
