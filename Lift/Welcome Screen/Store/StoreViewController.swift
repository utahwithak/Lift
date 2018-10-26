//
//  StoreViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/25/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit
import StoreKit

class StoreViewController: NSViewController {
    override func viewDidLoad() {
    }
    @objc dynamic var helper: IAPHelper {
        return IAPHelper.shared
    }

    @IBAction func finished(_ sender: NSButton) {
        view.window?.orderOut(sender)
    }
}
