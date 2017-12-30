//
//  ProgressViewController.swift
//  Yield
//
//  Created by Carl Wieland on 4/11/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Cocoa

class ProgressViewController: NSViewController {

    @objc dynamic var operation = ""
    @objc dynamic var progress = NSNumber(value: 0)
    @objc dynamic var indeterminant = false

    @IBOutlet weak var indicator: NSProgressIndicator!

    func setOperationText(to value: String) {
        operation = value
    }
    
    func updateProgress(to value: Double) {
        progress = NSNumber(value: value)
    }

    override func viewDidLoad() {
        if indeterminant {
            indicator.startAnimation(nil)
        }
    }
}
