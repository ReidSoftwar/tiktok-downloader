//
//  webViewController.swift
//  tiktokSafe
//
//  Created by Ryan Reid on 8/7/20.
//  Copyright © 2020 Ryan Reid. All rights reserved.
//

import UIKit
import WebKit
import Foundation

class webViewController: UIViewController, WKNavigationDelegate {
    
    var webView = WKWebView()

    override func viewDidLoad() {
        super.viewDidLoad()

            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore

            cookieStore.getAllCookies {
                cookies in

                for cookie in cookies {
                    cookieStore.delete(cookie)
                }
            }
            
            webView.navigationDelegate = self
            view = webView
            
            
            let url = URL(string: "https://www.tiktok.com/login/")!
            webView.load(URLRequest(url: url))
            webView.allowsBackForwardNavigationGestures = true

            webView.evaluateJavaScript("window.open = function(open) { return function (url, name, features) { window.location.href = url; return window; }; } (window.open);", completionHandler: nil)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
