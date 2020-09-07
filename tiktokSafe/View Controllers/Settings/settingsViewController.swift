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
    var freeProCounter = 0
    var tapped3times = false
    
    var settingsArray = ["Purchase Pro", "Restore Purchase", "Change Username", "Share App"]
    var settingsImageArray = [UIImage(named: "proIcon"), UIImage(named: "restoreProIcon"), UIImage(named: "changeUserIcon"), UIImage(named: "shareAppIcon")]

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var codeTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        freeProCounter = 0
        tapped3times = false
        verifyPurchase()
        self.becomeFirstResponder()
        tableView.reloadData()
        tableView.isScrollEnabled = false
        self.tableView.tableFooterView = UIView()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        logoImage.isUserInteractionEnabled = true
        logoImage.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }

    // Enable detection of shake motion
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake && tapped3times == true {
            
            if defaults.bool(forKey: "proPurchased") == false {
                
                let alertController = UIAlertController(title: "Welcome Friend of Ryan!", message: "Type in access code...", preferredStyle: .alert)
                  alertController.addTextField { (pTextField) in
                  pTextField.placeholder = "Access Code..."
                  pTextField.clearButtonMode = .whileEditing
                  pTextField.borderStyle = .none
                    self.codeTextField = pTextField
                }

                // create Ok button
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (pAction) in
                  // when user taps OK, you get your value here
                    let inputValue = self.codeTextField?.text
                    if inputValue == "2486736" {
                        self.defaults.set(true, forKey: "proPurchased")
                        self.tableView.reloadData()
                        let nc = NotificationCenter.default
                        nc.post(name: Notification.Name("needReload"), object: nil)
                    }
                    alertController.dismiss(animated: true, completion: nil)
                }))

                // show alert controller
                self.present(alertController, animated: true, completion: nil)
                
            }

        }
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        
        freeProCounter += 1
        
        if freeProCounter >= 3 {
            tapped3times = true
        }

        // Your action
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        tableView.reloadData()
        freeProCounter = 0
        tapped3times = false
        
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
                        let nc = NotificationCenter.default
                        nc.post(name: Notification.Name("needReload"), object: nil)
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
        
            settingsArray = ["Change Username", "Share App"]
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
        
        if settingsArray[indexPath.row] == "Change Username" {
            self.performSegue(withIdentifier: "changeUserSegue", sender: nil)
        } else if settingsArray[indexPath.row] == "Share App" {
            let sms: String = "sms:&body=Hey, check out this cool app! https://apps.apple.com/us/app/id1528438259"
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
                    let nc = NotificationCenter.default
                    nc.post(name: Notification.Name("needReload"), object: nil)
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
                    let nc = NotificationCenter.default
                    nc.post(name: Notification.Name("needReload"), object: nil)
                }
                else {
                    self.purchaseProduct()
                }
            }
            
        }
        
    }
    
    


}
