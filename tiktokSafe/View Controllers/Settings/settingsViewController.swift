//
//  settingsViewController.swift
//  tiktokSafe
//
//  Created by Ryan Reid on 8/3/20.
//  Copyright © 2020 Ryan Reid. All rights reserved.
//

import UIKit
import SwiftyStoreKit

class settingsViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    
    var settingsArray = ["Purchase Pro", "Restore Purchase", "Change User Tag", "Share App"]
    var settingsImageArray = [UIImage(named: "proIcon"), UIImage(named: "restoreProIcon"), UIImage(named: "changeUserIcon"), UIImage(named: "shareAppIcon")]

    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        verifyPurchase()
        tableView.reloadData()
        tableView.isScrollEnabled = false
        self.tableView.tableFooterView = UIView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        tableView.reloadData()
        
    }
    
    func purchaseProduct() {
        
        SwiftyStoreKit.retrieveProductsInfo(["unlimitedtokens"]) { result in
            if let product = result.retrievedProducts.first {
                SwiftyStoreKit.purchaseProduct(product, quantity: 1, atomically: true) { result in
                    
                    switch result {
                    case .success(let product):
                        // fetch content from your server, then:
                        if product.needsFinishTransaction {
                            SwiftyStoreKit.finishTransaction(product.transaction)
                        }
                        print("Purchase Success: \(product.productId)")
                        self.defaults.set(true, forKey: "proPurchased")
                        self.tableView.reloadData()
                        case .error(let error):
                        switch error.code {
                        case .unknown: print("Unknown error. Please contact support")
                        case .clientInvalid: print("Not allowed to make the payment")
                        case .paymentCancelled: break
                        case .paymentInvalid: print("The purchase identifier was invalid")
                        case .paymentNotAllowed: print("The device is not allowed to make the payment")
                        case .storeProductNotAvailable: print("The product is not available in the current storefront")
                        case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                        case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                        case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                        default: print((error as NSError).localizedDescription)
                        }
                    }
                    
                }
            }
        }
        
    }
    
    func verifyPurchase() {
        
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: "f3f4869b2a56417ba6a54a5b45971521")
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                let productId = "unlimitedtokens"
                // Verify the purchase of Consumable or NonConsumable
                let purchaseResult = SwiftyStoreKit.verifyPurchase(
                    productId: productId,
                    inReceipt: receipt)
                    
                switch purchaseResult {
                case .purchased(let receiptItem):
                    print("\(productId) is purchased: \(receiptItem)")
                case .notPurchased:
                    print("The user has never purchased \(productId)")
                }
            case .error(let error):
                print("Receipt verification failed: \(error)")
            }
        }
        
    }
    

}

extension settingsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if defaults.bool(forKey: "proPurchased") == true {
        
            settingsArray = ["Change User Tag", "Share App"]
            settingsImageArray = [UIImage(named: "changeUserIcon"), UIImage(named: "shareAppIcon")]
        
        }

        return settingsArray.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! TableViewCell
        cell.label.text = settingsArray[indexPath.row]
        cell.icon.image = settingsImageArray[indexPath.row]
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if settingsArray[indexPath.row] == "Change User Tag" {
            self.performSegue(withIdentifier: "changeUserSegue", sender: nil)
        } else if settingsArray[indexPath.row] == "Share App" {
            let sms: String = "sms:&body=Hey, check out this cool app! https://abc123.com"
            let strURL: String = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            UIApplication.shared.open(URL.init(string: strURL)!, options: [:], completionHandler: nil)
        } else if settingsArray[indexPath.row] == "Restore Purchase" {
            SwiftyStoreKit.restorePurchases(atomically: true) { results in
                if results.restoreFailedPurchases.count > 0 {
                    print("Restore Failed: \(results.restoreFailedPurchases)")
                }
                else if results.restoredPurchases.count > 0 {
                    print("Restore Success: \(results.restoredPurchases)")
                    self.defaults.set(true, forKey: "proPurchased")
                    self.tableView.reloadData()
                }
                else {
                    print("Nothing to Restore")
                }
            }
        } else if settingsArray[indexPath.row] == "Purchase Pro" {
            
            SwiftyStoreKit.restorePurchases(atomically: true) { results in
                if results.restoreFailedPurchases.count > 0 {
                    print("Restore Failed: \(results.restoreFailedPurchases)")
                }
                else if results.restoredPurchases.count > 0 {
                    print("Already Purchased... Restoring Purchase")
                    let alertController = UIAlertController(title: "Already Purchased!", message: "You have recieved unlimited tokens.", preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                    print("Restore Success: \(results.restoredPurchases)")
                    self.defaults.set(true, forKey: "proPurchased")
                    self.tableView.reloadData()
                }
                else {
                    self.purchaseProduct()
                }
            }
            
        }
        
    }
    
    


}
