//
//  newUsernameViewController.swift
//  tiktokSafe
//
//  Created by Ryan Reid on 8/17/20.
//  Copyright © 2020 Ryan Reid. All rights reserved.
//

import UIKit
import CoreData
import WebKit
import JGProgressHUD

class newUsernameViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    let defaults = UserDefaults.standard
    var webView = WKWebView()
    
    @IBOutlet weak var usernameEntry: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        errorLabel.text = ""
    }
    
    let hud = JGProgressHUD(style: .dark)
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            
            cookieStore.getAllCookies {
                cookies in
                
                for cookie in cookies {
                    
                    if cookie.name == "s_v_web_id" {
                        
                        self.defaults.setValue(cookie.value, forKey: "verify")
                        
                    }
                }
            }
            
            webView.evaluateJavaScript("document.documentElement.outerHTML") { (html, error) in
                guard let html = html as? String else {
                    print(error!)
                    return
                }
                
                let rangeFound = html.range(of: "://user/profile/")
            
                // GET UID
                if rangeFound == nil {
                    
                    self.errorLabel.text = "not real user"
                    self.hud.dismiss()
                    
                } else {

                    self.hud.dismiss()
                    self.navigationController?.popViewController(animated: true)
                    self.defaults.setValue(self.usernameEntry.text!, forKey: "username")

                    
                }
            }
        
    }
    

    @IBAction func submitButtonTapped(_ sender: Any) {
        
        if usernameEntry.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                
                hud.textLabel.text = "Loading"
                hud.show(in: self.view)
                
                errorLabel.text = ""
                
                let config = WKWebViewConfiguration()

                webView = WKWebView(frame:  UIScreen.main.bounds, configuration: config)

                webView.navigationDelegate = self
                webView.uiDelegate = self

                let url = URL(string: "https://www.tiktok.com/@\(usernameEntry.text!.trimmingCharacters(in: .whitespacesAndNewlines))")!
                webView.load(URLRequest(url: url))
                webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
                webView.allowsBackForwardNavigationGestures = true
            } else {
                errorLabel.text = "please enter a username"
            }
            
        }
    

}
