//
//  ColumnNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
class ColumnNode: BrowseViewNode {

    weak var provider: DataProvider?
    weak var column: Column?
    init(parent: DataProvider, column: Column) {
        provider = parent
        self.type = column.type
        self.column = column
        super.init(name: column.name)
    }

    @objc dynamic let type: String
}
