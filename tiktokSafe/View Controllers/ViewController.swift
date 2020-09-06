//
//  ViewController.swift
//  tiktokSafe
//
//  Created by Ryan Reid on 8/1/20.
//  Copyright © 2020 Ryan Reid. All rights reserved.
//

import UIKit

@IBDesignable extension UIButton {

    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }

    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}

func print(items: Any..., separator: String = " ", terminator: String = "\n") {

    #if DEBUG

    var idx = items.startIndex
    let endIdx = items.endIndex

    repeat {
        Swift.print(items[idx], separator: separator, terminator: idx == (endIdx - 1) ? terminator : separator)
        idx += 1
    }
    while idx < endIdx

    #endif
}

class ViewController: UIViewController {
    
    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if defaults.bool(forKey: "loggedIn") == true {
            self.performSegue(withIdentifier: "loggedIn", sender: nil)
        }
    }

}

