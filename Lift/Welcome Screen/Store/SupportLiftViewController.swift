//
//  SupportLiftViewController.swift
//  Lift Free
//
//  Created by Carl Wieland on 10/25/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Cocoa
import StoreKit

class SupportLiftViewController: NSViewController {
    override func viewDidLoad() {
        IAPHelper.shared.load()
    }
    @IBAction func showStore(_ sender: NSButton) {
        if let url = URL(string: "macappstore://itunes.apple.com/app/id1302953963") {
            NSWorkspace.shared.open(url)
        }
        dismiss(self)
    }
    @IBAction func showLocalStore(_ sender: Any) {
        if SKPaymentQueue.canMakePayments() {
            let storyboard = NSStoryboard(name: "Store", bundle: nil)
            if let windowController = storyboard.instantiateInitialController() as? NSWindowController {
                windowController.showWindow(nil)
            }
        }
        dismiss(self)
    }
}
