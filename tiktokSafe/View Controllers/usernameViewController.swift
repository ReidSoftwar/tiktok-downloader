//
//  usernameViewController.swift
//  tiktokSafe
//
//  Created by Ryan Reid on 8/7/20.
//  Copyright © 2020 Ryan Reid. All rights reserved.
//

import UIKit
import CoreData
import WebKit
import JGProgressHUD

class usernameViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    let defaults = UserDefaults.standard
    var webView = WKWebView()
    
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var usernameEntry: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                    
                    if self.defaults.bool(forKey: "isNotFirstTime") == false {
                            
                        self.defaults.set(true, forKey: "isNotFirstTime")
                        self.defaults.set(100, forKey: "tokens")
                            
                        let alert = UIAlertController(title: "Welcome New User!", message: "You have receieved \(self.defaults.integer(forKey: "tokens")) free tokens!", preferredStyle: .alert)

                            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { action in
                                self.performSegue(withIdentifier: "logIn", sender: nil)
                            }))
                            
                            self.present(alert, animated: true)
                        
                        self.hud.dismiss()
                        
                        self.performSegue(withIdentifier: "logIn", sender: nil)
                        self.defaults.setValue(true, forKey: "loggedIn")
                        self.defaults.setValue(self.usernameEntry.text!, forKey: "username")
                            
                        } else {
                            self.hud.dismiss()
                            self.performSegue(withIdentifier: "logIn", sender: nil)
                            self.defaults.setValue(true, forKey: "loggedIn")
                            self.defaults.setValue(self.usernameEntry.text!, forKey: "username")
                        }
                    
                }
            }
        
    }

    @IBAction func nextButtonPressed(_ sender: Any) {
        
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
