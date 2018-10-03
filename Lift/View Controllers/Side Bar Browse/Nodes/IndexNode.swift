//
//  IndexNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
class IndexNode: TableChildNode {

    weak var index: Index?
    init(parent: DataProvider, index: Index) {
        self.index = index
        super.init(name: index.name, provider: parent)

    }
}
