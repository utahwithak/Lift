//
//  CreateUniqueTable.swift
//  Lift
//
//  Created by Carl Wieland on 9/18/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

extension CreateTableConstraintDefinitions {
    class CreateUnique: NSObject {
        @objc dynamic var columns = [CreateIndexedColumn]()
        @objc dynamic var name: String?
        init(existing: PrimaryKeyTableConstraint, in table: CreateTableDefinition) {
            for indexColumn in existing.indexedColumns {
                guard let column = table.columns.first(where: { $0.name == indexColumn.nameProvider.name }) else {
                    fatalError("Can't find column!")
                }
                columns.append(CreateIndexedColumn(column: column, collation: indexColumn.collationName, sortOrder: indexColumn.sortOrder))
            }
        }
        override init() {

        }

        func contains(_ column: CreateColumnDefinition ) -> Bool {
            return columns.contains(where: { $0.column === column })
        }

        func add(column: CreateColumnDefinition) {
            columns.append(CreateIndexedColumn(column: column, collation: nil, sortOrder: .notSpecified))
        }

        func remove(column: CreateColumnDefinition) {
            if let index = columns.index(where: { $0.column === column }) {
                columns.remove(at: index)
            }
        }

        var toDefinition: UniqueTableConstraint {
            var constraint = UniqueTableConstraint(name: name)
            for column in columns {
                constraint.indexedColumns.append(column.toIndexedColumn)
            }

            return constraint
        }
    }
}
