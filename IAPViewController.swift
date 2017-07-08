//
//  IAPViewController.swift
//  IAPDemoFrank
//
//  Created by Frank.Chen on 2017/5/5.
//  Copyright © 2017年 Frank.Chen. All rights reserved.
//

import UIKit
import StoreKit

// 取得內購所有的產品資訊(SKProductsRequestDelegate) → 列出內購所有的產品在 TableView 上 → 增加 SKPaymentTransactionObserver 來監聽交易流程(SKPaymentQueue.default().add(self)) → 處理購買產品的流程(Action Sheet) → 購買或回復成功更新主頁的值並返回
class IAPViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    @IBOutlet weak var tableView: UITableView!
    var productIDs: [String] = [String]() // 產品ID(Consumable_Product、Not_Consumable_Product)
    var productsArray: [SKProduct] = [SKProduct]() //  存放 server 回應的產品項目
    var selectedProductIndex: Int! // 點擊到的購買項目
    var isProgress: Bool = false // 是否有交易正在進行中
    var delegate: IAPurchaseViewControllerDelegate!
    var lodingView: LodingView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 讀取產品資訊
        self.lodingView = LodingView(frame: UIScreen.main.bounds)
        self.view.addSubview(self.lodingView!)
        
        // 將產品 ID 加入陣列中，以用來請求產品資訊
        self.productIDs.append("Consumable_Product") // 消耗性產品
        self.productIDs.append("Not_Consumable_Product") // 非消耗性產品
        
        // 發送請求取得在iTunes Connect內購的產品資訊，並非所有的產品，只會請求有定義的產品 ID
        self.requestProductInfo()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // 移除觀查者
        SKPaymentQueue.default().remove(self)
    }
    
    // MARK: - Callback
    // ---------------------------------------------------------------------
    // 發送請求以用來取得內購的產品資訊
    func requestProductInfo() {
        if SKPaymentQueue.canMakePayments() {
            // 取得所有在 iTunes Connect 所建立的內購項目
            let productIdentifiers: Set<String> = NSSet(array: self.productIDs) as! Set<String>
            let productRequest: SKProductsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
            
            productRequest.delegate = self
            productRequest.start() // 開始請求內購產品
        } else {
            print("取不到任何內購的商品...")
        }
    }
    
    // 取消按鈕
    @IBAction func goCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // 回復購買
    @IBAction func goRestore(_ sender: Any) {
        self.showActionSheet(.restore)
    }
    
    // 提示購買或回復商品的訊息
    func showMessage(_ product: Product) {
        var message: String!
        
        switch product {
        case .consumable:
            message = "購買消耗性商品成功！"
        case .nonConsumable:
            message = "購買非消耗性商品成功！"
        case .restore:
            message = "回復成功！"
        }
        
        let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "是", style: .default, handler: nil)
        
        alertController.addAction(confirm)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - DataSource
    // ---------------------------------------------------------------------
    // 設定表格section的列數
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.productsArray.count
    }
    
    // 表格的儲存格設定
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: IAPTableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! IAPTableViewCell
        
        let product = self.productsArray[indexPath.row] // 請求的產品
        
        // localizedTitle(商品名稱)、localizedDescription(商品描述)
        cell.productLabel.text = "\(product.localizedTitle)\n\(product.localizedDescription)"
        cell.priceLabel.text = indexPath.row == 0 ? "$30" : "$60"
        
        return cell
    }
    
    // MARK: - Delegate
    // ---------------------------------------------------------------------
    // 接收到產品請求的回應
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        // invalidProductIdentifiers.description 會印出不合法的內購項目，例如：沒有設定價錢、已停用的等等
        print("invalidProductIdentifiers： \(response.invalidProductIdentifiers.description)")
        // 產品陣列(SKProduct)，裡面包含著在iTunes Connect所建立的該 APP 的所有內購項目
        if response.products.count != 0 {
            // 將取得的 IAP 產品放入 tableView 裡
            for product in response.products {
                self.productsArray.append(product)
            }
            
            // 重新載入tableView的資料
            self.tableView.reloadData()
        }
        else {
            print("取不到任何商品...")
        }
        
        // 取得所有產品並完成移除 Loding View
        if self.lodingView != nil {
            self.lodingView?.removeFromSuperview()
        }
    }
    
    // 購買、復原成功與否的 protocol
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        // 送出購買則會 update 一次，購買成功 server 又會回傳一次 update
        for transaction in transactions {
            switch transaction.transactionState {
            case SKPaymentTransactionState.purchased:
                print("交易成功...")
                // 必要的機制
                SKPaymentQueue.default().finishTransaction(transaction)
                self.isProgress = false
                
                // 移除觀查者
                SKPaymentQueue.default().remove(self)
                
                // 跟 ViewController 說已完成付款，必須增加金幣
                delegate.didBuySomething(self, self.selectedProductIndex == 0 ? Product.consumable : Product.nonConsumable)
                
                if self.lodingView != nil {
                    self.lodingView?.removeFromSuperview()
                }
                
                self.dismiss(animated: true, completion: nil)
            case SKPaymentTransactionState.failed:
                print("交易失敗...")
                
                if let error = transaction.error as? SKError {
                    switch error.code {
                    case .paymentCancelled:
                        // 輸入 Apple ID 密碼時取消
                        print("Transaction Cancelled: \(error.localizedDescription)")
                    case .paymentInvalid:
                        print("Transaction paymentInvalid: \(error.localizedDescription)")
                    case .paymentNotAllowed:
                        print("Transaction paymentNotAllowed: \(error.localizedDescription)")
                    default:
                        print("Transaction: \(error.localizedDescription)")
                    }
                }
                
                SKPaymentQueue.default().finishTransaction(transaction)
                self.isProgress = false
            case SKPaymentTransactionState.restored:
                print("復原成功...")
                // 必要的機制
                SKPaymentQueue.default().finishTransaction(transaction)
                self.isProgress = false
                
                // 跟 ViewController 說已回復動作，必須開啟聊天功能
                self.delegate.didBuySomething(self, Product.restore)
                
                if self.lodingView != nil {
                    self.lodingView?.removeFromSuperview()
                }
                
                self.showMessage(.restore)
            default:
                print(transaction.transactionState.rawValue)
            }
        }
    }
    
    // 消耗性或非消耗性產品
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false) // 取消灰底
        self.selectedProductIndex = indexPath.row // 點擊到的購買項目
        self.showActionSheet(self.selectedProductIndex == 0 ? Product.consumable : Product.nonConsumable) // 一樣的處理
    }
    
    // 詢問是否購買或回復的 Action Sheet
    func showActionSheet(_ product: Product) {
        // 代表有購買項目正在處理中
        if self.isProgress {
            return
        }
        
        var message: String!
        var buyAction: UIAlertAction?
        var restoreAction: UIAlertAction?
        
        switch product {
        case .consumable, .nonConsumable:
            // 購買消耗性、非消耗性產品
            message = "確定購買產品？"
            buyAction = UIAlertAction(title: "購買", style: UIAlertActionStyle.default) { (action) -> Void in
                                
                if SKPaymentQueue.canMakePayments() {
                    // 設定交易流程觀察者，會在背景一直檢查交易的狀態，成功與否會透過 protocol 得知
                    SKPaymentQueue.default().add(self)
                    
                    // 取得內購產品
                    let payment = SKPayment(product: self.productsArray[self.selectedProductIndex])
                    
                    // 購買消耗性、非消耗性動作將會開始在背景執行(updatedTransactions delegate 會接收到兩次)
                    SKPaymentQueue.default().add(payment)
                    self.isProgress = true
                    
                    // 開始執行購買產品的動作
                    self.lodingView = LodingView(frame: UIScreen.main.bounds)
                    self.view.addSubview(self.lodingView!)
                }
            }
        default:
            // 復原購買產品
            message = "是否回復？"
            restoreAction = UIAlertAction(title: "回復", style: UIAlertActionStyle.default) { (action) -> Void in
                if SKPaymentQueue.canMakePayments() {
                    SKPaymentQueue.default().restoreCompletedTransactions()
                    self.isProgress = true
                    
                    // 開始執行回復購買的動作
                    self.lodingView = LodingView(frame: UIScreen.main.bounds)
                    self.view.addSubview(self.lodingView!)
                }
            }
        }
        
        // 產生 Action Sheet
        let actionSheetController = UIAlertController(title: "測試內購", message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.cancel, handler: nil)
        
        actionSheetController.addAction(buyAction != nil ? buyAction! : restoreAction!)
        actionSheetController.addAction(cancelAction)
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    // 復原購買失敗
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("復原購買失敗...")
        print(error.localizedDescription)
    }

    // 回復購買成功(若沒實作該 delegate 會有問題產生)
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("復原購買成功...")
    }
}





