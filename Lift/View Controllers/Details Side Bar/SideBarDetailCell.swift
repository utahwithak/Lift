//
//  SideBarDetailCell.swift
//  Lift
//
//  Created by Carl Wieland on 10/24/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Cocoa

class SideBarDetailCell: NSTableCellView {
    @IBOutlet weak var titleLabel: NSTextField?
    @IBOutlet weak var sqlView: SQLiteTextView!
}
