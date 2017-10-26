//
//  JumpToRowViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/25/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

protocol JumpDelegate: NSObjectProtocol {
    func jumpView(_ view: JumpToRowViewController, jumpTo: Int?)
}
class JumpToRowViewController: NSViewController {
    
    @IBOutlet weak var jumpToRowField: NSTextField!

    weak var delegate: JumpDelegate?

    @IBAction func jump(_ sender: Any) {
        let rowEntered = Int(jumpToRowField.stringValue)
        delegate?.jumpView(self, jumpTo: rowEntered)
        dismissViewController(self)
    }
}
