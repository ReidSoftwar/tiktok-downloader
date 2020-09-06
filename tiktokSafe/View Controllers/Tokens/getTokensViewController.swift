//
//  getTokensViewController.swift
//  tiktokSafe
//
//  Created by Ryan Reid on 8/3/20.
//  Copyright © 2020 Ryan Reid. All rights reserved.
//

import UIKit
import GoogleMobileAds
import SwiftyStoreKit

class getTokensViewController: UIViewController, GADRewardedAdDelegate {
    
    @IBOutlet weak var watchAdButton: UIButton!
    @IBOutlet weak var tokensLabel: UILabel!
    @IBOutlet weak var premiumView: UIView!
    @IBOutlet weak var watchAdView: UIView!
    @IBOutlet weak var rateAppView: UIView!
    @IBOutlet weak var rateAppButton: UIButton!
    
    
    let defaults = UserDefaults.standard
    
    var rewardedAd: GADRewardedAd?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SwiftyStoreKit.retrieveProductsInfo(["unlimitedtokens"]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                print("Product: \(product.localizedDescription), price: \(priceString)")
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
            }
            else {
                print("Error: \(result.error!)")
            }
        }
        
        premiumView.layer.cornerRadius = 8
        watchAdView.layer.cornerRadius = 8
        rateAppView.layer.cornerRadius = 8
        
        if defaults.bool(forKey: "proPurchased") == true {
            
            premiumView.isHidden = true
            watchAdView.isHidden = true
            tokensLabel.isHidden = true
            rateAppView.isHidden = true
            purchasedLabel()
            
        }
        
        GADMobileAds.sharedInstance().applicationVolume = 1.0
        self.watchAdButton.isEnabled = false
        watchAdButton.alpha = 0.5
        rewardedAd = createAndLoadRewardedAd()
        
        verifyPurchase()
        
      }
    
    func createAndLoadRewardedAd() -> GADRewardedAd? {
        
        rewardedAd = GADRewardedAd(adUnitID: "ca-app-pub-9177412731525460/1342848204")
        rewardedAd?.load(GADRequest()) { error in
          if let error = error {
            print("Loading failed: \(error)")
          } else {
            print("Loading Succeeded")
            self.watchAdButton.isEnabled = true
            self.watchAdButton.isUserInteractionEnabled = true
            self.watchAdButton.alpha = 1.0
          }
        }
        return rewardedAd
    }
    
    var Launching = true
    
    override func viewWillAppear(_ animated: Bool) {
        
        tokensLabel.text = "Tokens: \(defaults.integer(forKey: "tokens"))"
        
        if Launching == true {
            Launching = false
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name("needReload"), object: nil)
            self.tabBarController!.selectedIndex = 1
        }
        
        if defaults.bool(forKey: "proPurchased") == true {
            
            premiumView.isHidden = true
            watchAdView.isHidden = true
            tokensLabel.isHidden = true
            rateAppView.isHidden = true
            purchasedLabel()
            
        }
        
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
                        self.premiumView.isHidden = true
                        self.watchAdView.isHidden = true
                        self.rateAppView.isHidden = true
                        self.tokensLabel.isHidden = true
                        self.purchasedLabel()
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
    

    
    @IBAction func watchAddButtonTapped(_ sender: Any) {
        
        if rewardedAd?.isReady == true {
           rewardedAd?.present(fromRootViewController: self, delegate:self)
        }
        
    }
    
    // Tells the delegate that the user earned a reward.
    func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        print("Reward received with currency: \(reward.type), amount \(reward.amount).")
        
        let previousAmount = defaults.integer(forKey: "tokens")
        
        defaults.set(Int(truncating: reward.amount) + previousAmount, forKey: "tokens")
        
    }
    // Tells the delegate that the rewarded ad was presented.
    func rewardedAdDidPresent(_ rewardedAd: GADRewardedAd) {
      print("Rewarded ad presented.")
    }
    // Tells the delegate that the rewarded ad was dismissed.
    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        self.rewardedAd = createAndLoadRewardedAd()
        print("Rewarded ad dismissed.")
        watchAdButton.isEnabled = false
        watchAdButton.alpha = 0.5
    }
    // Tells the delegate that the rewarded ad failed to present.
    func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
      print("Rewarded ad failed to present.")
    }

    
    
    
    
    @IBAction func purchaseProButtonTapped(_ sender: Any) {
        
        purchaseProduct()
    
    }
    
    let w = UIScreen.main.bounds.width
    let h = UIScreen.main.bounds.height
    let width = 275
    let height = 50
    
    var noVideosLabel = UILabel(frame: CGRect(x: 60, y: 100, width: 75, height: 75))
    
    func purchasedLabel() {
        
        noVideosLabel = UILabel(frame: CGRect(x: (w/2) - (CGFloat(width)/2), y: (h/2) - (CGFloat(height)/2), width: CGFloat(width), height: 75))
        
        self.view.addSubview(noVideosLabel)
        noVideosLabel.textColor = .lightGray
        noVideosLabel.text = "Thank You For Purchasing!"
        noVideosLabel.textAlignment = .center
    }
    
    func rateApp() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()

        } else if let url = URL(string: "itms-apps://itunes.apple.com/app/" + "id1528438259") {
            UIApplication.shared.open(url, options: [:], completionHandler: { (newStatus: Bool) in

                if (newStatus == true) {
                    self.appRated()
                }
                else {
                    print("no")
                }
                
            })
        }
    }
    
    func appRated() {
        
        rateAppView.isHidden = true
        rateAppButton.isEnabled = false
        
        let previousAmount = defaults.integer(forKey: "tokens")
        self.defaults.set(100 + previousAmount, forKey: "tokens")
        
    }
    
    @IBAction func rateAppButtonTapped(_ sender: Any) {
        
       rateApp()
        
    }
    
    

}
