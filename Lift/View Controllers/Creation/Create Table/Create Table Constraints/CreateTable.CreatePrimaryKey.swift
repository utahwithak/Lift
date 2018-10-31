//
//  PrimaryKey.swift
//  Lift
//
//  Created by Carl Wieland on 9/18/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
extension CreateTableConstraintDefinitions {

    class IndexedTableConstraint: NSObject {
        init(title: String) {
            self.title = title
        }
        @objc dynamic var enabled = true
        @objc dynamic var title = "PLACEHOLDER TEXT"
        @objc dynamic var columns = [CreateIndexedColumn]()
        @objc dynamic var useConflictResolution = false
        @objc dynamic var selectedConflictResolution = 0

        var conflictClause: ConflictClause? {
            get {
                guard useConflictResolution, let resolution = ConflictResolution(rawValue: selectedConflictResolution) else {
                    return nil
                }
                return ConflictClause(resolution: resolution)

            }
            set {
                selectedConflictResolution = newValue?.resolution.rawValue ?? 0
                useConflictResolution = newValue != nil
            }
        }
    }

    class CreatePrimaryKey: IndexedTableConstraint {
        @objc dynamic var name: String?

        init(existing: PrimaryKeyTableConstraint, in table: CreateTableDefinition) {
            super.init(title: NSLocalizedString("Primary Key", comment: "check box text for enableing primary key"))
            conflictClause = existing.conflictClause
            for indexColumn in existing.indexedColumns {
                guard let column = table.columns.first(where: { $0.name == indexColumn.nameProvider.name }) else {
                    fatalError("Can't find column!")
                }
                columns.append(CreateIndexedColumn(column: column, collation: indexColumn.collationName, sortOrder: indexColumn.sortOrder))
            }
        }

        init() {
            super.init(title: NSLocalizedString("Primary Key", comment: "check box text for enableing primary key"))
        }

        deinit {
            let tmpColumns = columns
            columns.removeAll()
            tmpColumns.forEach({ $0.column?.willChangeValue(for: \.isPrimary)})
            tmpColumns.forEach({ $0.column?.didChangeValue(for: \.isPrimary)})
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

        var toDefinition: PrimaryKeyTableConstraint? {
            guard enabled && !columns.isEmpty else {
                return nil
            }

            var constraint = PrimaryKeyTableConstraint(name: name)
            for column in columns {
                constraint.indexedColumns.append(column.toIndexedColumn)
            }
            constraint.conflictClause = conflictClause

            return constraint
        }
    }
}
