//
//  BrowseViewNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class BrowseViewNode: NSObject {

    @objc dynamic let name: String

    init(name: String) {
        self.name = name
    }

    @objc dynamic var children = [BrowseViewNode]() {
        willSet {
            willChangeValue(for: \.childCount)
        }
        didSet {
            didChangeValue(for: \.childCount)
        }
    }

    @objc dynamic var childCount: Int {
        return children.count
    }

    @objc dynamic var canDrop: Bool {
        return false
    }
}
