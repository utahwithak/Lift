//
//  CreateIndexedColumn.swift
//  Lift
//
//  Created by Carl Wieland on 9/18/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

protocol IndexedColumnConverter: class {
    func column(named: String) -> CreateColumnDefinition?
}

extension CreateTableConstraintDefinitions {

    class CreateIndexedColumn: NSObject {

        @objc dynamic var name: String {
            get {
                return column?.name ?? expression ?? ""
            }
            set {
                let oldValue = column
                let newColumn = converter?.column(named: newValue)

                oldValue?.willChangeValue(for: \.isPrimary)
                oldValue?.willChangeValue(for: \.isUnique)
                newColumn?.willChangeValue(for: \.isPrimary)
                newColumn?.willChangeValue(for: \.isUnique)

                column = newColumn
                newColumn?.didChangeValue(for: \.isPrimary)
                oldValue?.didChangeValue(for: \.isPrimary)
                newColumn?.didChangeValue(for: \.isUnique)
                oldValue?.didChangeValue(for: \.isUnique)
                expression = newValue
            }
        }

        weak var converter: IndexedColumnConverter?
        @objc dynamic var column: CreateColumnDefinition?
        @objc dynamic var expression: String?
        @objc dynamic var collationName: String?
        @objc dynamic var sortOrder: Int = 0

        override init() {

        }

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
