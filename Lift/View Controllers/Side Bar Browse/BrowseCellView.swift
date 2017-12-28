//
//  BrowseViewCell.swift
//  Lift
//
//  Created by Carl Wieland on 12/15/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class BrowseCellView: NSTableCellView {
    @IBOutlet weak var countIndicator: NSProgressIndicator!

    override func awakeFromNib() {
        countIndicator.startAnimation(nil)
    }

    override var objectValue: Any? {
        didSet {
            countIndicator.startAnimation(nil)
        }
    }
}
