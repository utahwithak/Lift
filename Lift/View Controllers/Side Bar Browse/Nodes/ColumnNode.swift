//
//  ColumnNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
class ColumnNode: TableChildNode {

    weak var column: Column?
    init(parent: DataProvider, column: Column) {
        self.type = column.type
        self.column = column
        super.init(name: column.name, provider: parent)
    }

    @objc dynamic let type: String
}
