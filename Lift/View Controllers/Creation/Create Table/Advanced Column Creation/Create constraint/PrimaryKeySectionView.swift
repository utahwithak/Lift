//
//  PrimaryKeySectionView.swift
//  Lift
//
//  Created by Carl Wieland on 10/26/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Cocoa

class PrimaryKeySectionView: NSTableCellView {

    var primaryKey: PrimaryKeySection? {
        return objectValue as? PrimaryKeySection
    }

    @IBOutlet weak var defaultSortOrder: NSButton!
    @IBOutlet weak var ascSortOrder: NSButton!
    @IBOutlet weak var descSortOrder: NSButton!

    override var objectValue: Any? {
        didSet {
            if let key = primaryKey {
                defaultSortOrder.state =  key.sortOrder == 0 ? .on : .off
                ascSortOrder.state =  key.sortOrder == 1 ? .on : .off
                descSortOrder.state =  key.sortOrder == 2 ? .on : .off
            }
        }
    }

    @IBAction func toggleSortOrder(_ sender: NSButton) {
        if sender == defaultSortOrder {
            primaryKey?.sortOrder = 0
        } else if sender == ascSortOrder {
            primaryKey?.sortOrder = 1
        } else if sender == descSortOrder {
            primaryKey?.sortOrder = 2
        }
    }
}
