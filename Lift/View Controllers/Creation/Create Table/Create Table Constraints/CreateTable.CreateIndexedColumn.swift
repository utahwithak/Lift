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

        @objc dynamic var name: String {
            get {
                return column?.name ?? expression ?? ""
            }
            set {
                shouldUseColumn = false
                expression = newValue
            }
        }

        @objc dynamic var shouldUseColumn = true
        @objc dynamic var column: CreateColumnDefinition?
        @objc dynamic var expression: String?
        @objc dynamic var collationName: String?
        @objc dynamic var sortOrder: Int = 0

        init(column: CreateColumnDefinition, collation: String?, sortOrder: IndexColumnSortOrder) {
            self.column = column
            collationName = collation
            self.sortOrder = sortOrder.rawValue
        }

        var toIndexedColumn: IndexedColumn {
            var index = IndexedColumn(provider: column ?? expression ?? "" )
            index.sortOrder = IndexColumnSortOrder(rawValue: sortOrder) ?? .notSpecified
            index.collationName = collationName
            return index
        }
    }

}
