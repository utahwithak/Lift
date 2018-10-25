//
//  SimpleCreateColumnView.swift
//  Lift
//
//  Created by Carl Wieland on 4/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Cocoa

class SimpleCreateColumnView: NSTableCellView {
    @objc dynamic var column: CreateColumnDefinition? {
        return objectValue as? CreateColumnDefinition
    }
}
