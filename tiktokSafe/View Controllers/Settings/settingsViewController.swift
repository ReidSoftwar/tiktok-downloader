//
//  settingsViewController.swift
//  tiktokSafe
//
//  Created by Ryan Reid on 8/3/20.
//  Copyright © 2020 Ryan Reid. All rights reserved.
//

import UIKit

class settingsViewController: UIViewController {
    
    let defaults = UserDefaults.standard
    
    let settingsArray = ["Purchase Pro", "Restore Purchase", "Change User Tag", "Share App"]
    let settingsImageArray = [UIImage(named: "proIcon"), UIImage(named: "restoreProIcon"), UIImage(named: "changeUserIcon"), UIImage(named: "shareAppIcon")]

    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.reloadData()
        tableView.isScrollEnabled = false
        self.tableView.tableFooterView = UIView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        tableView.reloadData()
        
    }
    

}

extension settingsViewController: UITableViewDataSource, UITableViewDelegate{

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

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
        }
        
    }
    
    


}
