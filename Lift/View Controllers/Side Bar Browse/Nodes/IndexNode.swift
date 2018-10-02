//
//  IndexNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
class IndexNode: BrowseViewNode {

    weak var provider: DataProvider?
    weak var index: Index?
    init(parent: DataProvider, index: Index) {
        provider = parent
        self.index = index
        super.init(name: index.name)
    }
}
