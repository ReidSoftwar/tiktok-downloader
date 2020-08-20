//
//  savedVideosViewController.swift
//  tiktokSafe
//
//  Created by Ryan Reid on 8/3/20.
//  Copyright © 2020 Ryan Reid. All rights reserved.
//

import UIKit
import AVKit
import Photos
import AVFoundation
import JGProgressHUD

private let reuseIdentifier = "savedVideoCell"

class savedVideosViewController: UICollectionViewController {
    
    let defaults = UserDefaults.standard
    
    var downloadArray : [String] = []
    
    @objc func onDidReceiveData() {
        
        collectionView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        downloadArray = []
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(plusSign))
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        self.view.addGestureRecognizer(longPressRecognizer)
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(onDidReceiveData), name: Notification.Name("needReload"), object: nil)
        
        try! AVAudioSession.sharedInstance().setCategory(.playback)

        let cellSize = CGSize(width:(self.collectionView.frame.size.width - 3)/4 , height:160.5)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = cellSize
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 1.5
        layout.minimumInteritemSpacing = 1
        layout.headerReferenceSize = CGSize(width: 50, height: 50)
        layout.sectionHeadersPinToVisibleBounds = true
        self.collectionView.setCollectionViewLayout(layout, animated: true)
        
        
        
    }
    
    var once : Bool? = false
    var selectAll : Bool? = false
    var buttonCreated : Bool = false
    
    override func viewWillAppear(_ animated: Bool) {
        collectionView.reloadData()
        self.defaults.removeObject(forKey: "videos")
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("needReload"), object: nil)
        
    }
    
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if once == false {
            collectionView.reloadData()
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(selectMenu))
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
            
            self.title = "Select Videos"
            
            
            
            once = true
        }
    }
    
    @objc func selectMenu() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Deselect All", style: .plain, target: self, action: #selector(deselectAll))
        exportView()
        deleteButtonView()
        selectAll = true
        collectionView.reloadData()
        
    }
    
    @objc func cancel() {
        self.title = "Saved Videos"
        
        hideExportButton()
        hideDeleteButton()
        
        once = false
        selectAll = false
        buttonCreated = false
        
        downloadArray = []
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(deselectAll))
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(plusSign))
        
        collectionView.reloadData()
    }
    
    @objc func plusSign() {
        self.performSegue(withIdentifier: "toUpload", sender: nil)
    }
    
    @objc func deselectAll() {
        hideExportButton()
        hideDeleteButton()
        selectAll = false
        buttonCreated = false
        downloadArray = []
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(selectMenu))
        collectionView.reloadData()
    }


    // MARK: UICollectionViewDataSource
    
    var plistArray : [String?] = []
    
    //2
    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        
        let fileManager = FileManager.default
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            let path = documentDirectory.appending("/tiktoks.plist")
        
        if fileManager.fileExists(atPath: path) {
            
            plistArray = (NSArray(contentsOfFile: path) as? [String])!
            
        }

        return plistArray.count
    }
    
    //3
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! savedTiktoksCollectionViewCell
        
        if collectionView.visibleCells.count == 0 {
            noVideosLabelView()
        } else {
            hidenoVideosLabel()
        }
        
        if downloadArray.contains("\(plistArray[indexPath.row]!).mp4") {
            
            cell.videoThumb.alpha = 0.5
            cell.backgroundColor = .lightGray
            cell.checkMark.isHidden = false
            
        } else {
            
            cell.videoThumb.alpha = 1
            cell.backgroundColor = .black
            cell.checkMark.isHidden = true
                
        }
    
        let fileName = "\(plistArray[indexPath.row]!).png"
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let getImagePath = paths.appendingPathComponent(fileName)
        
        cell.videoThumb.image = UIImage(contentsOfFile: getImagePath)
            
        
        cell.videoThumb.contentMode = .scaleAspectFit
        
        if once == true && selectAll == true {
            
            cell.videoThumb.alpha = 0.5
            cell.backgroundColor = .lightGray
            cell.checkMark.isHidden = false
            
            if !downloadArray.contains("\(plistArray[indexPath.row]!).mp4") {
                downloadArray.append("\(plistArray[indexPath.row]!).mp4")
            }

        } else if once == true {
            
            cell.videoThumb.alpha = 1.0
            cell.backgroundColor = .black
            cell.checkMark.isHidden = true
            
        }
        
        
        // Configure the cell
        return cell
        
    }
    
    let w = UIScreen.main.bounds.width
    let h = UIScreen.main.bounds.height
    let width = 275
    let height = 50
    
    var noVideosLabel = UILabel(frame: CGRect(x: 60, y: 100, width: 75, height: 75))
    
    func noVideosLabelView() {
        
        noVideosLabel = UILabel(frame: CGRect(x: (w/2) - (CGFloat(width)/2), y: (h/2) - (CGFloat(height)/2), width: CGFloat(width), height: 75))
        
        self.view.addSubview(noVideosLabel)
        noVideosLabel.textColor = .lightGray
        noVideosLabel.text = "You Don't Have Any Videos"
        noVideosLabel.textAlignment = .center
    }
    
    func hidenoVideosLabel() {
        noVideosLabel.isHidden = true
    }
    
    var customExportView = UIButton(frame: CGRect(x: 60, y: 100, width: 250, height: 100))
    
    func exportView() {
        customExportView = UIButton(frame: CGRect(x: (w/2) - (CGFloat(width)/2), y: h - (h/3.7), width: CGFloat(width), height: CGFloat(height)))
        self.view.addSubview(customExportView)
        customExportView.backgroundColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        customExportView.setTitle("Export to Camera Roll", for: .normal)
        customExportView.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
        customExportView.cornerRadius = 25
        customExportView.isHidden = false
        customExportView.isEnabled = true
    }
    
    func hideExportButton() {
        customExportView.isHidden = true
        customExportView.isEnabled = false
    }
    
    @objc func buttonClicked(_ sender: UIButton) {
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Loading"
        hud.show(in: self.view)
        
        var counter = 0
        
        for video in downloadArray {
            
            let fileName = video
            
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            
            let videoPath = paths.appendingPathComponent(fileName)
            
            let url = URL(fileURLWithPath: videoPath)
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { saved, error in
                if saved {
                    let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                } else {
                    
                    // Allow access for camera roll
                    
                }
            }
            
            counter += 1
            
            hud.textLabel.text = "\(counter)/\(downloadArray.count)"
            
            if counter == downloadArray.count {
                
                hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                hud.dismiss(afterDelay: 1.0, animated: true)
                
                hideExportButton()
                hideDeleteButton()
                downloadArray = []
                cancel()
                
                
            }
            
        }

    }
    
    
    var customDeleteButton = UIButton(frame: CGRect(x: 60, y: 100, width: 250, height: 100))
    
    func deleteButtonView() {
        customDeleteButton = UIButton(frame: CGRect(x: (w/2) - (CGFloat(width)/2), y: h - (h/5), width: CGFloat(width), height: CGFloat(height)))
        self.view.addSubview(customDeleteButton)
        customDeleteButton.backgroundColor = UIColor(red: 234.0/255.0, green: 46.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        customDeleteButton.tintColor = .white
        customDeleteButton.setTitle("Delete from App", for: .normal)
        customDeleteButton.addTarget(self, action: #selector(deleteButtonClicked), for: .touchUpInside)
        customDeleteButton.cornerRadius = 25
        customDeleteButton.isHidden = false
        customDeleteButton.isEnabled = true
    }
    
    func hideDeleteButton() {
        customDeleteButton.isHidden = true
        customDeleteButton.isEnabled = false
    }
    
    @objc func deleteButtonClicked(_ sender: UIButton) {
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Loading"
        hud.show(in: self.view)
        
        var counter = 0
        var deleteArray : [String] = []
        
        do {
        
            for video in downloadArray {
                
                let fileName = video
                
                let fileManager = FileManager.default
                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
                
                var imageTempName = fileName.components(separatedBy: ".")
                
                
                if imageTempName.count > 1 { // If there is a file extension
                  imageTempName.removeLast()
                }
                
                let imageName: String = imageTempName[0] + ".png"
                
                let videoPath = paths.appendingPathComponent(fileName)
                let imagePath = paths.appendingPathComponent(imageName)
                
                try fileManager.removeItem(atPath: videoPath)
                try fileManager.removeItem(atPath: imagePath)
                
                deleteArray.append(imageTempName[0])
      
                counter += 1
                
                hud.textLabel.text = "\(counter)/\(downloadArray.count)"
                
                if counter == downloadArray.count {
                    
                    hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                    hud.dismiss(afterDelay: 1.0, animated: true)
                    
                    let plistArrayPath = paths.appending("/tiktoks.plist")
                    
                    var plistArray2 = (NSArray(contentsOfFile: plistArrayPath) as? [String])!
                    
                    var deleteCounter = 0
                    
                    for name in deleteArray {
                        
                        while plistArray2.contains(name) {
                            if let itemToRemoveIndex = plistArray2.firstIndex(of: name) {
                                plistArray2.remove(at: itemToRemoveIndex)
                                deleteCounter += 1
                            }
                        }
                        
                        if deleteCounter == deleteArray.count {
                            
                            let plistArrayDate = plistArray2 as NSArray
                            
                            plistArrayDate.write(toFile: plistArrayPath, atomically: true)
                            
                            hideExportButton()
                            hideDeleteButton()
                            downloadArray = []
                            cancel()
                            
                            
                            collectionView.reloadData()
                            
                        }
                        
                    }
                    
                    
                }
                
            }
        
        } catch {
            
            hud.textLabel.text = "Error"
            hud.indicatorView = JGProgressHUDErrorIndicatorView()
            hud.dismiss(afterDelay: 1.0)
            print(error)
            
        }

    }

    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let cell = collectionView.cellForItem(at: indexPath) as! savedTiktoksCollectionViewCell
        
        if once == true {
            
            let fileName = "\(plistArray[indexPath.row]!).mp4"
            
            if downloadArray.contains(fileName) {
                
                let itemToRemove = fileName

                while downloadArray.contains(itemToRemove) {
                    if let itemToRemoveIndex = downloadArray.firstIndex(of: itemToRemove) {
                        downloadArray.remove(at: itemToRemoveIndex)
                        cell.checkMark.isHidden = true
                    }
                }
                
                cell.videoThumb.alpha = 1
                cell.backgroundColor = .black
                
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(selectMenu))
                
                if downloadArray.count == 0 {
                    hideExportButton()
                    hideDeleteButton()
                    buttonCreated = false
                }
                
                
            } else {
                
                if buttonCreated == false {
                    
                    exportView()
                    deleteButtonView()
                    
                    buttonCreated = true
                    
                }
                
                downloadArray.append(fileName)
                
                cell.videoThumb.alpha = 0.5
                cell.backgroundColor = .lightGray
                cell.checkMark.isHidden = false
                
                if self.collectionView.visibleCells.count == downloadArray.count {
                    
                    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Deselect All", style: .plain, target: self, action: #selector(deselectAll))
                    selectAll = true
                    self.collectionView.reloadData()
                    
                }
                
            }
            
        } else {
        
            let fileName = "\(plistArray[indexPath.row]!).mp4"
            
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
            let videoPath = paths.appendingPathComponent(fileName)
            
            let player = AVPlayer(url: URL(fileURLWithPath: videoPath))
            
            player.actionAtItemEnd = .none

            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
            
        }
    }
    
    @objc func playerItemDidReachEnd(notification: Notification) {
        if let playerItem = notification.object as? AVPlayerItem {
            playerItem.seek(to: CMTime.zero, completionHandler: nil)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if (kind == UICollectionView.elementKindSectionHeader) {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "tokensHeader", for: indexPath) as! tokensHeaderSavedVideosCollectionReusableView
            
            headerView.tokensLabel.text = "Tokens: \(defaults.integer(forKey: "tokens"))"
            headerView.backgroundColor = .black
            
            
            return headerView
        }
    
        fatalError()
        
    }

}
