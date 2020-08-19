//
//  tiktokLoginViewController.swift
//  tiktokSafe
//
//  Created by Ryan Reid on 8/1/20.
//  Copyright © 2020 Ryan Reid. All rights reserved.
//

import UIKit
import WebKit
import Foundation

class tiktokLoginViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    var popupWebView : WKWebView? = nil
    
    let defaults = UserDefaults.standard
    
    var webView = WKWebView()
    
    var firstTime = true
    var done = false
    
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
    
    func webView(_ webView: WKWebView, didCommit: WKNavigation!) {
        
        print(webView.url!.absoluteString)
        
        if webView.url!.absoluteString.contains("/foryou") {
            
            print("LOGGED IN")
            
            webView.evaluateJavaScript("document.documentElement.outerHTML") { (html, error) in
                guard let html = html as? String else {
                    print(error!)
                    return
                }
                
                // GET UID
                if let rangeFound = html.range(of: "\"uid\":") {
                
                    let y = rangeFound.upperBound
                    
                    let nsRange = NSRange(rangeFound, in: html)
                    print("Found uid from \(nsRange.location) to \(nsRange.location + nsRange.length - 1)")
                    
                    let unfinishedUID = String(html[y...])
                    print(unfinishedUID)
                    
                    var quoteCounter = 0
                    var positionCounter = -1
                    for char in unfinishedUID {
                        
                        positionCounter += 1
                        
                        if char == "\"" {
                            
                            quoteCounter += 1
                        }
                        
                        if quoteCounter == 2 {
                            
                            let totalCharacters = unfinishedUID.count
                            var finishedUID = String(unfinishedUID.dropLast(totalCharacters - positionCounter))
                            
                            finishedUID = finishedUID.replacingOccurrences(of: "\"", with: "")
                            
                            self.defaults.set(finishedUID, forKey: "uid")
                            
                            quoteCounter += 1
                            
                        }
                        
                    }

                }
                
                //GET SEC_UID
                if let rangeFound = html.range(of: "\"secUid\":") {
                
                    let y = rangeFound.upperBound
                    
                    let nsRange = NSRange(rangeFound, in: html)
                    print("Found suid from \(nsRange.location) to \(nsRange.location + nsRange.length - 1)")
                    
                    let unfinishedSUID = String(html[y...])
                    print(unfinishedSUID)
                    
                    var quoteCounter = 0
                    var positionCounter = -1
                    for char in unfinishedSUID {
                        
                        positionCounter += 1
                        
                        if char == "\"" {
                            
                            quoteCounter += 1
                        }
                        
                        if quoteCounter == 2 {
                            
                            let totalCharacters = unfinishedSUID.count
                            var finishedSUID = String(unfinishedSUID.dropLast(totalCharacters - positionCounter))
                            
                            finishedSUID = finishedSUID.replacingOccurrences(of: "\"", with: "")
                            print(finishedSUID)
                            
                            self.defaults.set(finishedSUID, forKey: "suid")
                            
                            quoteCounter += 1
                            
                        }
                        
                    }

                }
                
            }
            
//            self.dismiss(animated: true, completion: nil)
            self.performSegue(withIdentifier: "webLogin", sender: nil)
            defaults.set(true, forKey: "loggedIn")
            
            
        } else if webView.url!.absoluteString.contains("google") {
            googleLogin()
        }
        
    }
    
    func googleLogin() {
        
        if done == false {
            
            if firstTime == true {
                let url = URL(string: "https://www.gmail.com")!
                webView.load(URLRequest(url: url))
                firstTime = false
            }
            
            if webView.url!.absoluteString.contains("authError") {
                print("ignore")
            } else {
                
                if webView.url!.absoluteString.contains("accounts.google.com") {
                    print("logging in")
                    
                } else {
                    webView = WKWebView()

                    webView.navigationDelegate = self
                    view = webView


                    let url = URL(string: "https://www.tiktok.com/login/")!
                    webView.load(URLRequest(url: url))
                    webView.allowsBackForwardNavigationGestures = true
                    webView.customUserAgent = "Version/8.0.2 Safari/600.2.5"

                    webView.evaluateJavaScript("window.open = function(open) { return function (url, name, features) { window.location.href = url; return window; }; } (window.open);", completionHandler: nil)

                    done = true
                    
                }
                
            }
            
        }
        
        
    }
    
    
    

}

extension String {
    subscript(range: CountableRange<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex..<endIndex])
    }

    subscript(range: CountableClosedRange<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
        return String(self[startIndex...endIndex])
    }
}
