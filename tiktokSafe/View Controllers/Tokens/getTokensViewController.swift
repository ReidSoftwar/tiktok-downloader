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
    
    
    let defaults = UserDefaults.standard
    
    var rewardedAd: GADRewardedAd?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        premiumView.layer.cornerRadius = 8
        watchAdView.layer.cornerRadius = 8
        
        GADMobileAds.sharedInstance().applicationVolume = 1.0
        self.watchAdButton.isEnabled = false
        watchAdButton.alpha = 0.5
        rewardedAd = createAndLoadRewardedAd()
        
      }
    
    func createAndLoadRewardedAd() -> GADRewardedAd? {
        
        rewardedAd = GADRewardedAd(adUnitID: "ca-app-pub-3940256099942544/1712485313")
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
        
        SwiftyStoreKit.retrieveProductsInfo(["com.reidapps.tiktokVideoDownloader"]) { result in
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
        
    }
    
    

}
