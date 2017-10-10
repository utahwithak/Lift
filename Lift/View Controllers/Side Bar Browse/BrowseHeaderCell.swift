//
//  BrowseHeaderCell.swift
//  Lift
//
//  Created by Carl Wieland on 10/7/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class BrowseHeaderCell: NSTableCellView {
    
    override func awakeFromNib() {
        textField?.font = NSFont.systemFont(ofSize: 17)
    }
}
