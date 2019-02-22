//
//  ConstraintButton.swift
//  Lift
//
//  Created by Carl Wieland on 10/29/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class ConstraintButton: NSButton {
    override class var cellClass: AnyClass? {
        set { _ = newValue }
        get {
            return ConstraintButtonCell.self
        }
    }

    @objc dynamic var drawAsEnabled = false {
        didSet {
            (cell as? ConstraintButtonCell)?.drawAsEnabled = drawAsEnabled
            setNeedsDisplay()
        }
    }
}
