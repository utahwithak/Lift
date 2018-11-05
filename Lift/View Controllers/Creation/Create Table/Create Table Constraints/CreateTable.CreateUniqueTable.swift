//
//  CreateUniqueTable.swift
//  Lift
//
//  Created by Carl Wieland on 9/18/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

extension CreateTableConstraintDefinitions {
    class CreateUnique: IndexedTableConstraint {
        @objc dynamic var name: String?
        init(existing: UniqueTableConstraint, in table: CreateTableDefinition) {
            super.init(title: NSLocalizedString("Unique", comment: "check box text for enableing unique table constraint"), table: table)
            conflictClause = existing.conflictClause
            for indexColumn in existing.indexedColumns {
                guard let column = table.columns.first(where: { $0.name == indexColumn.nameProvider.name }) else {
                    fatalError("Can't find column!")
                }
                columns.append(CreateIndexedColumn(column: column, collation: indexColumn.collationName, sortOrder: indexColumn.sortOrder))
            }
            title = NSLocalizedString("Unique", comment: "check box text for enableing unique table constraint")

        }
        init(table: CreateTableDefinition) {
            super.init(title: NSLocalizedString("Unique", comment: "check box text for enableing unique table constraint"), table: table)
        }

        deinit {
            let tmpColumns = columns
            columns.removeAll()
            tmpColumns.forEach({ $0.column?.willChangeValue(for: \.isUnique)})
            tmpColumns.forEach({ $0.column?.didChangeValue(for: \.isUnique)})
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

        var toDefinition: UniqueTableConstraint? {
            guard enabled && !columns.isEmpty else {
                return nil
            }
            var constraint = UniqueTableConstraint(name: name)
            for column in columns {
                constraint.indexedColumns.append(column.toIndexedColumn)
            }
            constraint.conflictClause = conflictClause
            return constraint
        }
    }
}
