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

        activityIndicator?.isIndeterminate = indeterminate
        if !indeterminate {
            activityIndicator.maxValue = 1
            activityIndicator.minValue = 0
            activityIndicator?.doubleValue = value
        }
    }

    @IBAction override func cancelOperation(_ sender: Any?) {
        cancelHandler?()
    }

    public var indeterminate = true {
        didSet {
            activityIndicator?.isIndeterminate = indeterminate
        }
    }

    public var value: Double = 0 {
        didSet {
            activityIndicator.isIndeterminate = false
            activityIndicator?.doubleValue = value
        }
    }



}
