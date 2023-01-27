//
//  tikTokVideosCollectionViewController.swift
//  tiktokSafe
//
//  Created by Ryan Reid on 8/5/20.
//  Copyright © 2020 Ryan Reid. All rights reserved.
//

import UIKit
import WebKit
import Foundation
import JavaScriptCore
import JGProgressHUD
import Darwin
import Alamofire
import AlamofireImage
import GoogleMobileAds

private let reuseIdentifier = "videoCell"

class tikTokVideosCollectionViewController: UICollectionViewController, WKNavigationDelegate, WKUIDelegate, GADBannerViewDelegate {
    
    var webView = WKWebView()
    
    var jsonResponse = ""
    
    let defaults = UserDefaults.standard
    
    var progressHudOnce : Bool? = nil
    
    var savedVideosURL : [String] = []
    var savedVideosThumb : [String] = []
    
    var savedVideosDictionary : [String:String] = [:]
    
    var done = false
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.title = "\(defaults.string(forKey: "username")!)'s Videos"
        
        if let button = self.navigationItem.rightBarButtonItem {
            button.isEnabled = false
            button.tintColor = UIColor.clear
        }
        
        let cellSize = CGSize(width:(self.collectionView.frame.size.width - 3)/4 , height:160.5)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical //.horizontal
        layout.itemSize = cellSize
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 1.5
        layout.minimumInteritemSpacing = 1
        
        if self.defaults.bool(forKey: "proPurchased") {
            layout.headerReferenceSize = CGSize(width: 0, height: 0)
            layout.footerReferenceSize = CGSize(width: 0, height: 0)
        } else {
            layout.headerReferenceSize = CGSize(width: 50, height: 50)
            layout.footerReferenceSize = CGSize(width: 50, height: 50)
        }
        
        layout.sectionHeadersPinToVisibleBounds = true
        self.collectionView.setCollectionViewLayout(layout, animated: true)
        
        progressHudOnce = false
        
        let config = WKWebViewConfiguration()

        webView = WKWebView(frame:  UIScreen.main.bounds, configuration: config)

        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        let username = defaults.string(forKey: "username")
        
        let string = "https://www.tiktok.com/@\(username!)"

        let url = URL(string: string.trimmingCharacters(in: .whitespaces))
        
        webView.load(URLRequest(url: url!))
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
        webView.allowsBackForwardNavigationGestures = true
        webView.evaluateJavaScript("window.open = function(open) { return function (url, name, features) { window.location.href = url; return window; }; } (window.open);", completionHandler: nil)
        
    }
    
    var bannerView: GADBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Add Banner Ad
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
         bannerView.adUnitID = "ca-app-pub-9177412731525460/2358957530" //<-- My Ad Unit
//        bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        addBannerViewToView(bannerView)
        bannerView.delegate = self
        
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        view.addConstraints(
            [NSLayoutConstraint(item: bannerView,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: bottomLayoutGuide,
                attribute: .top,
                multiplier: 1,
                constant: 0),
             NSLayoutConstraint(item: bannerView,
                attribute: .centerX,
                relatedBy: .equal,
                toItem: view,
                attribute: .centerX,
                multiplier: 1,
                constant: 0)
            ])
    }
    
    let hud = JGProgressHUD(style: .dark)
    var progressCounter = 1
    
    let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    
    func webView(_ webView: WKWebView, didCommit: WKNavigation!) {
        
        if progressHudOnce == false {
            
            if defaults.array(forKey: "videos") != nil {
                let barButton = UIBarButtonItem(customView: activityIndicator)
                self.navigationItem.setRightBarButton(barButton, animated: true)
                activityIndicator.startAnimating()
            } else {
                hud.textLabel.text = "Loading"
                hud.show(in: self.view)
            }
        }
    
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        progressHudOnce = true
        
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        
        cookieStore.getAllCookies {
            cookies in
            
            var verifyPresent = false
            let totalCookies = cookies.count
            var counter = 0
            
            for cookie in cookies {
                
                print(cookie.name)
                print(cookie.value)
                
                if cookie.name == "s_v_web_id" {
                    
                    self.defaults.setValue(cookie.value, forKey: "verify")
                    verifyPresent = true
                    
                } else if cookie.name == "tt_webid_v2" {
                    
                    self.defaults.setValue(cookie.value, forKey: "web_id")
                    
                }
                
                counter += 1
                
                if counter == totalCookies {
                    
                    if verifyPresent == true {
                       
                        webView.evaluateJavaScript("document.documentElement.outerHTML") { (html, error) in
                            guard let html = html as? String else {
                                print(error!)
                                return
                            }
                            
                            // GET UID
                            if let rangeFound = html.range(of: "://user/profile/") {
                            
                                let y = rangeFound.upperBound
                                
                                let unfinishedUID = String(html[y...])
                                
                                var positionCounter = -1
                                for char in unfinishedUID {
                                    
                                    positionCounter += 1
                                    
                                    if char == "?" {
                                        
                                        positionCounter += 1
                                        
                                        let totalCharacters = unfinishedUID.count
                                        var finishedUID = String(unfinishedUID.dropLast(totalCharacters - positionCounter))
                                        
                                        finishedUID = finishedUID.replacingOccurrences(of: "\"", with: "")
                                        finishedUID = finishedUID.replacingOccurrences(of: "?", with: "")
                                        print(finishedUID)
                                        
                                        self.defaults.set(finishedUID, forKey: "uid")
                                        
                                        let newUrl = "https://m.tiktok.com/api/item_list/?aid=1988&app_name=tiktok_web&device_platform=web&referer=https:%2F%2Fwww.google.com%2F&user_agent=Mozilla%2F5.0+(Macintosh%3B+Intel+Mac+OS+X+10_15_5)+AppleWebKit%2F537.36+(KHTML,+like+Gecko)+Chrome%2F84.0.4147.105+Safari%2F537.36&cookie_enabled=true&screen_width=1536&screen_height=960&browser_language=en-US&browser_platform=MacIntel&browser_name=Mozilla&browser_version=5.0+(Macintosh%3B+Intel+Mac+OS+X+10_15_5)+AppleWebKit%2F537.36+(KHTML,+like+Gecko)+Chrome%2F84.0.4147.105+Safari%2F537.36&browser_online=true&timezone_name=America%2FLos_Angeles&priority_region=&appId=1233&region=US&appType=m&isAndroid=false&isMobile=false&isIOS=false&OS=mac&did=\(self.defaults.string(forKey: "web_id")!)&count=50&id=\(self.defaults.string(forKey: "uid")!)&type=1&secUid=&maxCursor=0&minCursor=0&sourceType=8&language=en&verifyFp=\(self.defaults.string(forKey: "verify")!)"
                                        
                                        webView.evaluateJavaScript("window.byted_acrawler.sign({ url: \"\(newUrl)\" })") { (result, error) in
                                            if error == nil {
                                                
                                                self.defaults.set(result!, forKey: "signature")
                                                
                                                let getUrl = "https://m.tiktok.com/api/item_list/?aid=1988&app_name=tiktok_web&device_platform=web&referer=https:%2F%2Fwww.google.com%2F&user_agent=Mozilla%2F5.0+(Macintosh%3B+Intel+Mac+OS+X+10_15_5)+AppleWebKit%2F537.36+(KHTML,+like+Gecko)+Chrome%2F84.0.4147.105+Safari%2F537.36&cookie_enabled=true&screen_width=1536&screen_height=960&browser_language=en-US&browser_platform=MacIntel&browser_name=Mozilla&browser_version=5.0+(Macintosh%3B+Intel+Mac+OS+X+10_15_5)+AppleWebKit%2F537.36+(KHTML,+like+Gecko)+Chrome%2F84.0.4147.105+Safari%2F537.36&browser_online=true&timezone_name=America%2FLos_Angeles&priority_region=&appId=1233&region=US&appType=m&isAndroid=false&isMobile=false&isIOS=false&OS=mac&did=\(self.defaults.string(forKey: "web_id")!)&count=50&id=\(self.defaults.string(forKey: "uid")!)&type=1&secUid=&maxCursor=0&minCursor=0&sourceType=8&language=en&verifyFp=\(self.defaults.string(forKey: "verify")!)&_signature=\(self.defaults.string(forKey: "signature")!)"
                                                
                                                sleep(UInt32(2))
                                                
                                                // create get request
                                                let url = URL(string: getUrl)!
                                                var request = URLRequest(url: url)
                                                request.httpMethod = "GET"

                                                request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
                                                request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1", forHTTPHeaderField: "User-Agent")
                                                
                                                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                                                    guard let data = data, error == nil else {
                                                        print(error?.localizedDescription ?? "No data")
                                                        return
                                                    }
                                                    
                                                    let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                                                    if let responseJSON = responseJSON as? [String:Any] {
                                                        
                                                        print(responseJSON)
                                                        
                                                        if responseJSON["items"] != nil {
                                                            let videos = responseJSON["items"]! as! NSArray
                                                            self.defaults.set(videos, forKey: "videos")
                                                            
                                                            DispatchQueue.main.async {
                                                                self.hud.dismiss()
                                                                self.activityIndicator.stopAnimating()
                                                                
                                                                self.done = true
          
                                                                self.collectionView!.reloadData()
                                                                
                                                                
                                                            }
                                                        } else {
                                                            print(self.defaults.string(forKey: "verify")!)
                                                            DispatchQueue.main.async {
                                                                
                                                                self.clean()
                                                                
                                                                self.hud.textLabel.text = "Retrying (\(self.progressCounter))"
                                                                
                                                                self.progressCounter += 1
                                                                
                                                                let url = URL(string: ("https://www.tiktok.com/@\(self.defaults.string(forKey: "username")!)").trimmingCharacters(in: .whitespaces))!
                                                                self.webView.load(URLRequest(url: url))
                                                            }
                                                        }
                                                        

                                                    }
                                                    
                                                }
                                                
                                                task.resume()
                                                
                                            } else {
                                                
                                                print(error!)
                                                
                                            }
                                        }
                                        
                                        break
                                        
                                    }
                                }
                                    
                            }
                            
                        }
                        
                    } else {
                        
                        DispatchQueue.main.async {
                            
                            let config = WKWebViewConfiguration()

                            self.webView = WKWebView(frame:  UIScreen.main.bounds, configuration: config)

                            self.webView.navigationDelegate = self
                            self.webView.uiDelegate = self

                            let url = URL(string: ("https://www.tiktok.com/@\(self.defaults.string(forKey: "username")!)").trimmingCharacters(in: .whitespaces))!
                            self.webView.load(URLRequest(url: url))
                            self.webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1"
                            self.webView.allowsBackForwardNavigationGestures = true
                            self.webView.evaluateJavaScript("window.open = function(open) { return function (url, name, features) { window.location.href = url; return window; }; } (window.open);", completionHandler: nil)
                            
                        }
                                  
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func clean() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        print("[WebCacheCleaner] All cookies deleted")
        
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                print("[WebCacheCleaner] Record \(record) deleted")
            }
        }
    }
                                

    // MARK: UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if defaults.array(forKey: "videos") != nil {
            return defaults.array(forKey: "videos")!.count
        } else {
            return 0
        }
    }
    
    var videoDictionary : Dictionary<String,NSArray>? = [:]
    var videoIDArray : [String] = []
    var selectedArray : [IndexPath] = []

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! tiktokVideosCollectionViewCell
                
        // Configure the cell
        let videos = defaults.array(forKey: "videos")
        let fullContentDictionary = videos![indexPath.row] as! Dictionary<String, Any>
        let videoContentDictionary = fullContentDictionary["video"] as! Dictionary<String, Any>
        let videoCoverURL = videoContentDictionary["cover"] as! String
        let videoPlayAddr = videoContentDictionary["playAddr"] as! String

        let videoID = fullContentDictionary["id"] as! String
        
        if !videoIDArray.contains(videoID) {
            videoIDArray.append(videoID)
            
            videoDictionary![videoID] = [videoCoverURL, videoPlayAddr]
        }
        
        if selectedArray.contains(indexPath) {
            
            cell.videoImageView.alpha = 0.5
            cell.backgroundColor = .lightGray
            cell.checkMarkImage.isHidden = false
            
        } else {
            
            cell.videoImageView.alpha = 1
            cell.backgroundColor = .black
            cell.checkMarkImage.isHidden = true
                
        }

        let url = URL(string: videoCoverURL)!

        cell.videoImageView.af.setImage(withURL: url)
        
        cell.videoImageView.contentMode = .scaleAspectFit
        
        
                

    
        return cell
    }
    
    let hud2 = JGProgressHUD(style: .dark)
    
    @IBAction func addTapped(_ sender: Any) {
        
        if defaults.bool(forKey: "proPurchased") == false {
        
            if defaults.integer(forKey: "tokens") >= savedVideosURL.count * 10 {
                
                let alert = UIAlertController(title: "Are you sure?", message: "You are about to spend \(savedVideosURL.count * 10) tokens!", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                    
                }))
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                            
                    self.hud2.textLabel.text = "Loading"
                    self.hud2.show(in: self.view)
                            
                    var dictionaryCounter = 0
                    
                    while dictionaryCounter != self.savedVideosURL.count {
                        
                        self.savedVideosDictionary[self.savedVideosURL[dictionaryCounter]] = self.savedVideosThumb[dictionaryCounter]
                        
                        dictionaryCounter += 1
                        
                    }
                    
                    let fileManager = FileManager.default
                    let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                        let path = documentDirectory.appending("/tiktoks.plist")
                        print(path)
                    
                    if (!fileManager.fileExists(atPath: path)) || fileManager.fileExists(atPath: path) {
                        
                        var savingCounter = 0
                        print(self.savedVideosURL)
                        var fileNames : [String] = []
                        
                        for tiktok in self.savedVideosDictionary {
                            
                            let randomName = UUID().uuidString

                            DispatchQueue.global(qos: .background).async {
                                
                                if let url = URL(string: tiktok.key),
                                    let urlData = NSData(contentsOf: url) {
                                    DispatchQueue.main.async {
                                        
                                        let success : Bool = urlData.write(toFile: "\(documentDirectory)/\(randomName).mp4", atomically: true)

                                        if !success {
                                            self.hud2.textLabel.text = "Error"
                                            self.hud2.indicatorView = JGProgressHUDErrorIndicatorView()
                                            self.hud2.dismiss(afterDelay: 1.0)
                                        } else {
                                            fileNames.append(randomName)
                                            savingCounter += 1
                                            
                                            self.hud2.textLabel.text = "\(savingCounter)/\(self.savedVideosDictionary.count)"
                                            
                                            if savingCounter == self.savedVideosURL.count {
                                                
                                                if fileManager.fileExists(atPath: path) {
                                                           
                                                    var plistArray = (NSArray(contentsOfFile: path) as? [String])!
                                                    
                                                    plistArray.append(contentsOf: fileNames)
                                                    
                                                    let something = plistArray as NSArray
                                                    
                                                    something.write(toFile: path, atomically: true)
                                                           
                                                } else {
                                                    
                                                    let contents = fileNames as NSArray
                                                    
                                                    contents.write(toFile: path, atomically: true)
                                                    
                                                }
                                                
                                                self.defaults.set(self.defaults.integer(forKey: "tokens") - self.savedVideosURL.count * 10, forKey: "tokens")
                                                self.hud2.textLabel.text = "Success"
                                                let nc = NotificationCenter.default
                                                nc.post(name: Notification.Name("needReload"), object: nil)
                                                self.hud2.indicatorView = JGProgressHUDSuccessIndicatorView()
                                                self.hud2.dismiss(afterDelay: 1.0, animated: true)
                                                sleep(UInt32(3.5))
                                                self.navigationController?.popViewController(animated: true)
                                            } else if savingCounter > self.savedVideosURL.count {
                                                print("error")
                                            }
                                            
                                        }

                                        
                                    }
                                }
                                
                                if let url = URL(string: tiktok.value),
                                    let urlData = NSData(contentsOf: url) {
                                    DispatchQueue.main.async {
                                        
                                        let success : Bool = urlData.write(toFile: "\(documentDirectory)/\(randomName).png", atomically: true)

                                        if !success {
                                            savingCounter += 1
                                            self.hud2.textLabel.text = "Error"
                                            self.hud2.indicatorView = JGProgressHUDErrorIndicatorView()
                                            self.hud2.dismiss(afterDelay: 1.0)
                                        }
                                        
                                    }
                                }
                                
                            }
                            
                            
                        }
                              
                    } else {
                        
                        self.hud.textLabel.text = "Error"
                        self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                        self.hud.dismiss(afterDelay: 1.0)

                        
                    }
                    
                }))
                
                self.present(alert, animated: true)
                
            } else {
                
                let alert = UIAlertController(title: "Not Enough Tokens!", message: "You need \((savedVideosURL.count * 10) - defaults.integer(forKey: "tokens")) more tokens to download these videos", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { action in
                    
                }))
                alert.addAction(UIAlertAction(title: "Get More", style: .default, handler: { action in
                    self.navigationController?.popViewController(animated: true)
                    self.tabBarController!.selectedIndex = 0
                }))
                
                self.present(alert, animated: true)
                
            }
            
        } else {
            
            self.hud2.textLabel.text = "Loading"
            self.hud2.show(in: self.view)
                    
            var dictionaryCounter = 0
            
            while dictionaryCounter != self.savedVideosURL.count {
                
                self.savedVideosDictionary[self.savedVideosURL[dictionaryCounter]] = self.savedVideosThumb[dictionaryCounter]
                
                dictionaryCounter += 1
                
            }
            
            let fileManager = FileManager.default
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                let path = documentDirectory.appending("/tiktoks.plist")
                print(path)
            
            if (!fileManager.fileExists(atPath: path)) || fileManager.fileExists(atPath: path) {
                
                var savingCounter = 0
                print(self.savedVideosURL)
                var fileNames : [String] = []
                
                for tiktok in self.savedVideosDictionary {
                    
                    let randomName = UUID().uuidString

                    DispatchQueue.global(qos: .background).async {
                        
                        if let url = URL(string: tiktok.key),
                            let urlData = NSData(contentsOf: url) {
                            DispatchQueue.main.async {
                                
                                let success : Bool = urlData.write(toFile: "\(documentDirectory)/\(randomName).mp4", atomically: true)

                                if !success {
                                    self.hud2.textLabel.text = "Error"
                                    self.hud2.indicatorView = JGProgressHUDErrorIndicatorView()
                                    self.hud2.dismiss(afterDelay: 1.0)
                                } else {
                                    fileNames.append(randomName)
                                    savingCounter += 1
                                    
                                    self.hud2.textLabel.text = "\(savingCounter)/\(self.savedVideosDictionary.count)"
                                    
                                    if savingCounter == self.savedVideosURL.count {
                                        
                                        if fileManager.fileExists(atPath: path) {
                                                   
                                            var plistArray = (NSArray(contentsOfFile: path) as? [String])!
                                            
                                            plistArray.append(contentsOf: fileNames)
                                            
                                            let something = plistArray as NSArray
                                            
                                            something.write(toFile: path, atomically: true)
                                                   
                                        } else {
                                            
                                            let contents = fileNames as NSArray
                                            
                                            contents.write(toFile: path, atomically: true)
                                            
                                        }
                                        self.hud2.textLabel.text = "Success"
                                        let nc = NotificationCenter.default
                                        nc.post(name: Notification.Name("needReload"), object: nil)
                                        self.hud2.indicatorView = JGProgressHUDSuccessIndicatorView()
                                        self.hud2.dismiss(afterDelay: 1.0, animated: true)
                                        sleep(UInt32(3.5))
                                        self.navigationController?.popViewController(animated: true)
                                    } else if savingCounter > self.savedVideosURL.count {
                                        print("error")
                                    }
                                    
                                }

                                
                            }
                        }
                        
                        if let url = URL(string: tiktok.value),
                            let urlData = NSData(contentsOf: url) {
                            DispatchQueue.main.async {
                                
                                let success : Bool = urlData.write(toFile: "\(documentDirectory)/\(randomName).png", atomically: true)

                                if !success {
                                    savingCounter += 1
                                    self.hud2.textLabel.text = "Error"
                                    self.hud2.indicatorView = JGProgressHUDErrorIndicatorView()
                                    self.hud2.dismiss(afterDelay: 1.0)
                                }
                                
                            }
                        }
                        
                    }
                    
                    
                }
                      
            } else {
                
                self.hud.textLabel.text = "Error"
                self.hud.indicatorView = JGProgressHUDErrorIndicatorView()
                self.hud.dismiss(afterDelay: 1.0)

                
            }
            
        }
        

    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! tiktokVideosCollectionViewCell
        
        if done == true {
                
                let videos = defaults.array(forKey: "videos")
                let fullContentDictionary = videos![indexPath.row] as! Dictionary<String, Any>
                let videoContentDictionary = fullContentDictionary["video"] as! Dictionary<String, Any>
                let currentVideo = fullContentDictionary["id"]
            
                let videoURL = videoDictionary![currentVideo as! String]![1]
                
                print(videoURL)
            
                let videoCoverURL = videoContentDictionary["cover"] as! String
                
                if selectedArray.contains(indexPath) {
                    
                    let itemToRemove = indexPath
                    let videoToRemove = videoURL as! String
                    let thumbToRemove = videoCoverURL

                    while selectedArray.contains(itemToRemove) {
                        if let itemToRemoveIndex = selectedArray.firstIndex(of: itemToRemove) {
                            selectedArray.remove(at: itemToRemoveIndex)
                            cell.checkMarkImage.isHidden = true
                        }
                    }
                    
                    while savedVideosURL.contains(videoToRemove) {
                        if let itemToRemoveIndex = savedVideosURL.firstIndex(of: videoToRemove) {
                            savedVideosURL.remove(at: itemToRemoveIndex)
                        }
                    }
                    
                    while savedVideosThumb.contains(thumbToRemove) {
                        if let itemToRemoveIndex = savedVideosThumb.firstIndex(of: thumbToRemove) {
                            savedVideosThumb.remove(at: itemToRemoveIndex)
                        }
                    }
                    
                    cell.videoImageView.alpha = 1
                    cell.backgroundColor = .black
                    
                } else {
                    
                    selectedArray.append(indexPath)
                    savedVideosThumb.append(videoCoverURL)
                    
                    cell.videoImageView.alpha = 0.5
                    cell.backgroundColor = .lightGray
                    cell.checkMarkImage.isHidden = false
                    
                    savedVideosURL.append(videoURL as! String)
                    print(savedVideosURL)
                        
                }
                
                if selectedArray.count != 0 || savedVideosURL.count != 0 {
                    
                    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(addTapped))
                    
                } else {
                    
                    if let button = self.navigationItem.rightBarButtonItem {
                        button.isEnabled = false
                        button.tintColor = UIColor.clear
                    }
                    
                }
                
                print(videoURL)
                
                print(selectedArray)
                
                defaults.set("no", forKey: "isFirstTime")
                
                
            }
            
        
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
            
            case UICollectionView.elementKindSectionFooter:
            
                let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "adFooter", for: indexPath)
                
                if defaults.bool(forKey: "proPurchased") == false {
                    
                    footerView.backgroundColor = .black
                    return footerView
                    
                } else {
                    
                    footerView.isHidden = true
                    return footerView
                }
            
            case UICollectionView.elementKindSectionHeader:
            
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "uploadHeader", for: indexPath) as! tokenCollectionReusableView
                
                if defaults.bool(forKey: "proPurchased") == false {
                    
                    headerView.tokenLabel.text = "Tokens: \(defaults.integer(forKey: "tokens"))"
                    headerView.backgroundColor = .black
                    
                    return headerView
                    
                } else {
                    
                    headerView.isHidden = true
                    
                    
                    return headerView
                }
            
            default:
            
                fatalError()
            
        }
        
    }
    
    
    // ------------------------------------------------------------ Banner Ads ------------------------------------------------------------ //
    
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
          bannerView.alpha = 1
        })
        print("adViewDidReceiveAd")
    }

    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
        didFailToReceiveAdWithError error: GADRequestError) {
      print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }

    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
      print("adViewWillPresentScreen")
    }

    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
      print("adViewWillDismissScreen")
    }

    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
      print("adViewDidDismissScreen")
    }

    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
      print("adViewWillLeaveApplication")
    }
    
    
}

extension WKWebView {

    private var httpCookieStore: WKHTTPCookieStore  { return WKWebsiteDataStore.default().httpCookieStore }

    func getCookies(for domain: String? = nil, completion: @escaping ([String : Any])->())  {
        var cookieDict = [String : AnyObject]()
        httpCookieStore.getAllCookies { cookies in
            for cookie in cookies {
                if let domain = domain {
                    if cookie.domain.contains(domain) {
                        cookieDict[cookie.name] = cookie.properties as AnyObject?
                    }
                } else {
                    cookieDict[cookie.name] = cookie.properties as AnyObject?
                }
            }
            completion(cookieDict)
        }
    }
}
