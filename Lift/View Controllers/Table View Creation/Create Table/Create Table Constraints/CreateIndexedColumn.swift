//
//  CreateIndexedColumn.swift
//  Lift
//
//  Created by Carl Wieland on 9/18/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

extension CreateTableConstraintDefinitions {

    class CreateIndexedColumn: NSObject {
        @objc dynamic var column: CreateColumnDefinition
        @objc dynamic var collationName: String?
        @objc dynamic var sortOrder: Int = 0

        init(column: CreateColumnDefinition, collation: String?, sortOrder: IndexColumnSortOrder) {
            self.column = column
            collationName = collation
            self.sortOrder = sortOrder.rawValue
        }

        var toIndexedColumn: IndexedColumn {
            var index = IndexedColumn(provider: self.column)
            index.sortOrder = IndexColumnSortOrder(rawValue: sortOrder) ?? .notSpecified
            index.collationName = collationName
            return index
        }
    }

}
