//
//  ConstraintButton.swift
//  Lift
//
//  Created by Carl Wieland on 10/29/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class ConstraintButtonCell: NSButtonCell {

    @objc dynamic var drawAsEnabled = false

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        isEnabled = false || drawAsEnabled
        super.drawInterior(withFrame: cellFrame, in: controlView)
        isEnabled = true || drawAsEnabled
    }

    override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
        isEnabled = false || drawAsEnabled
        super.drawImage(image, withFrame: frame, in: controlView)
        isEnabled = true || drawAsEnabled
    }

    override var isEnabled: Bool {
        get {
            return super.isEnabled
        }
        set {
            super.isEnabled = newValue
        }
    }
}
