//
//  NSTabView+Additions.swift
//  Lift
//
//  Created by Carl Wieland on 10/26/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

extension NSTabView {
    func removeTabViewItem(at index: Int) {
        let item = tabViewItem(at: index)
        removeTabViewItem(item)
    }

    func removeAllItems() {
        while let first = tabViewItems.first {
            removeTabViewItem(first)
        }
    }
}

