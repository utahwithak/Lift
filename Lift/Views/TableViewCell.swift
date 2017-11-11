//
//  TableViewRow.swift
//  Lift
//
//  Created by Carl Wieland on 10/9/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TableViewCell: NSTableCellView {
    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        textField?.isEditable = true
        return textField?.becomeFirstResponder() ?? false
    }

}
