//
//  CreateTable.ForeignKeyTable.swift
//  Lift
//
//  Created by Carl Wieland on 10/26/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
extension CreateTableConstraintDefinitions {

    class CreateForeignKeyConstraint: NSObject {

        @objc dynamic var enabled = false

        @objc dynamic let table: CreateTableDefinition

        @objc dynamic var name: String?
        @objc dynamic var columns = [ColumnPairing]()

        @objc dynamic var useOnDelete = false
        @objc dynamic var onDeleteIndex = 0
        @objc dynamic var useOnUpdate = false
        @objc dynamic var onUpdateIndex = 0

        @objc dynamic var useMatchName = false
        @objc dynamic var matchName: String?

        @objc dynamic var useDeferrable = false
        @objc dynamic var deferrableIndex = 0
        @objc dynamic var deferrableTypeIndex = 0

        @objc dynamic var selectedToTable: Table?

        init(existing: ForeignKeyTableConstraint, table: CreateTableDefinition) {
            enabled = true
            self.table = table
            self.name = existing.name
            for actionStatement in existing.clause.actionStatements {
                switch actionStatement.type {
                case .delete:
                    useOnDelete = true
                    onDeleteIndex = actionStatement.result.rawValue
                case .update:
                    useOnUpdate = true
                    onUpdateIndex = actionStatement.result.rawValue
                }
            }
            useMatchName = !existing.clause.matchStatements.isEmpty
            matchName = existing.clause.matchStatements.map({ $0.name }).joined(separator: ", ")
            if let deferable = existing.clause.deferStatement {
                useDeferrable = true
                deferrableIndex = deferable.isDeferrable ? 0 : 1
                deferrableTypeIndex = deferable.type.rawValue
            }
            selectedToTable = table.database.tables.first(where: { $0.name.cleanedVersion == existing.clause.foreignTable.cleanedVersion })

            for column in existing.fromColumns {
                let pairing = ColumnPairing(table: table)
                if let def = table.columns.first(where: { $0.name == column }) {
                    pairing.from = def.name
                }
                columns.append(pairing)
            }

            for (index, toColumn) in existing.clause.toColumns.enumerated() {
                columns[index].to = toColumn
            }
        }

        init(table: CreateTableDefinition) {
            self.table = table
            selectedToTable = table.database.tables.first
        }

        var toDefinition: ForeignKeyTableConstraint? {
            guard enabled else {
                return nil
            }
            var clause = ForeignKeyClause(destination: selectedToTable?.name ?? "", columns: columns.compactMap { $0.to })

            if useDeferrable {
                clause.deferStatement = ForeignKeyDeferStatement(deferrable: deferrableIndex == 0, type: DeferType(rawValue: deferrableTypeIndex)!)
            }

            if useOnUpdate {
                clause.actionStatements.append(ForeignKeyActionStatement(type: .update, result: ActionResult(rawValue: onUpdateIndex)!))
            }

            if useOnDelete {
                clause.actionStatements.append(ForeignKeyActionStatement(type: .delete, result: ActionResult(rawValue: onDeleteIndex)!))
            }

            if useMatchName, let name = matchName, !name.isEmpty {
                clause.matchStatements = name.components(separatedBy: ", ").map({ ForeignKeyMatchStatement(name: $0)})
            }

            let constraint = ForeignKeyTableConstraint(name: name, fromColumns: columns.map({ $0.from }), clause: clause)
            return constraint
        }

        @objc func addColumn() {
            columns.append(ColumnPairing(table: table))
        }
    }

    class ColumnPairing: NSObject {
        let fromTable: CreateTableDefinition

        init(table: CreateTableDefinition) {
            self.fromTable = table
        }

        @objc dynamic var from: String {
            set {
                if let column = fromTable.columns.first(where: { $0.name == newValue }) {
                    customValue = ""
                    fromDefinition = column
                } else {
                    fromDefinition = nil
                    customValue = newValue
                }
            }
            get {
                return fromDefinition?.name ?? customValue
            }
        }

        private var customValue: String = ""
        private var fromDefinition: CreateColumnDefinition?
        @objc dynamic var to: String?
    }
}
