//
//  WaitingOperationViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/21/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class WaitingOperationViewController: NSViewController {

    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    @IBOutlet weak var cancelButton: NSButton!
    var cancelHandler: (() -> Void)?

    override func viewDidLoad() {
        if cancelHandler == nil {
           cancelButton.removeFromSuperview()
        }
        activityIndicator.startAnimation(self)
        
    }

    @IBAction override func cancelOperation(_ sender: Any?) {
        cancelHandler?()
    }

}
