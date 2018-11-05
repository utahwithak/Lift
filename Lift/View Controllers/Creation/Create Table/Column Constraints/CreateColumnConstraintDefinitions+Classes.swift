//
//  CreateColumnConstraintDefinitions+Classes.swift
//  Lift
//
//  Created by Carl Wieland on 10/29/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
extension CreateColumnConstraintDefinitions {

    class CreateColumnConstraint: NSObject {
        @objc dynamic var constraintName: String?
        @objc dynamic var enabled: Bool = false
    }

    class CreateConflictConstraint: CreateColumnConstraint {
        @objc dynamic var useConflictClause = false
        @objc dynamic var selectedConflictResolution = 0
        var conflictClause: ConflictClause? {
            get {
                guard useConflictClause, let resolution = ConflictResolution(rawValue: selectedConflictResolution) else {
                    return nil
                }
                return ConflictClause(resolution: resolution)

            }
            set {
                selectedConflictResolution = newValue?.resolution.rawValue ?? 0
                useConflictClause = newValue != nil
            }
        }
    }

    class CreateDefaultValue: CreateColumnConstraint {
        @objc dynamic var value: String
        @objc dynamic var isEditingDefaultValue = false
        init(value: String) {
            self.value = value
        }
        init(existing: DefaultColumnConstraint) {
            value = existing.value.sql
            super.init()
            constraintName = existing.constraintName
            enabled = true
        }
        var toConstraint: DefaultColumnConstraint {
            return DefaultColumnConstraint(name: constraintName, value: value)
        }
    }

    class CreatePrimaryKey: CreateConflictConstraint {
        @objc dynamic var useSortOrder = false {
            willSet {
                willChangeValue(for: \.canUseAutoIncrement)
            }
            didSet {
                didChangeValue(for: \.canUseAutoIncrement)
            }
        }
        @objc dynamic var autoincrement = false
        @objc dynamic var sortOrder = 0 {
            willSet {
                willChangeValue(for: \.canUseAutoIncrement)
            }
            didSet {
                didChangeValue(for: \.canUseAutoIncrement)
            }
        }

        @objc dynamic var canUseAutoIncrement: Bool {
            if useSortOrder && sortOrder == 1 {
                return false
            }
            return true
        }

        override init() {}

        init(existing: PrimaryKeyColumnConstraint) {
            self.autoincrement = existing.autoincrement
            self.sortOrder = existing.sortOrder.rawValue - 1
            useSortOrder = existing.sortOrder != .notSpecified
            super.init()
            self.conflictClause = existing.conflictClause
            self.constraintName = existing.constraintName
            enabled = true
        }
        var constraint: PrimaryKeyColumnConstraint {
            let sortOrder = useSortOrder ? (PrimaryKeySortOrder(rawValue: self.sortOrder + 1) ?? .notSpecified) : .notSpecified
            return PrimaryKeyColumnConstraint(name: constraintName, sortOrder: sortOrder, autoincrement: canUseAutoIncrement && autoincrement, conflict: conflictClause)
        }
    }

    class CreateNonNull: CreateConflictConstraint {
        init(existing: NotNullColumnConstraint) {
            super.init()
            conflictClause = existing.conflictClause
            enabled = true
            constraintName = existing.constraintName

        }
        override init() {}
        var constraint: NotNullColumnConstraint {
            return NotNullColumnConstraint(name: constraintName, conflict: conflictClause)
        }
    }

    class CreateUnique: CreateConflictConstraint {
        override init() {}

        init(existing: UniqueColumnConstraint) {
            super.init()
            conflictClause = existing.conflictClause
            enabled = true
            constraintName = existing.constraintName
        }
        var toConstraint: UniqueColumnConstraint {
            return UniqueColumnConstraint(name: constraintName, conflict: conflictClause)
        }
    }

    class CreateCheckConstraint: CreateColumnConstraint {

        @objc dynamic var expression = ""

        init(existing: CheckColumnConstraint) {
            self.expression = existing.checkExpression
            super.init()
            enabled = true
            self.constraintName = existing.constraintName

        }

        override init() {
        }

        var toConstraint: CheckColumnConstraint {
            return CheckColumnConstraint(name: constraintName, expression: expression)
        }
    }

    class CreateCollateConstraint: CreateColumnConstraint {
        @objc dynamic var collationName = ""

        init(existing: CollateColumnConstraint) {
            self.collationName = existing.collationName
            super.init()
            enabled = true
            self.constraintName = existing.constraintName

        }

        override init() {
        }

        var toConstraint: CollateColumnConstraint {
            return CollateColumnConstraint(name: constraintName, collationName: collationName)
        }
    }

    class CreateForeignKeyConstraint: CreateColumnConstraint {

        init(existing: ForeignKeyColumnConstraint) {
            super.init()
            enabled = true
            constraintName = existing.constraintName
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
//            if let database = table.database {
//                selectedToTable = database.tables.first(where: { $0.name.cleanedVersion == existing.clause.foreignTable.cleanedVersion })
//            }
//
//            for column in existing.fromColumns {
//                let pairing = ColumnPairing(table: table)
//                if let def = table.columns.first(where: { $0.name == column }) {
//                    pairing.from = def.name
//                }
//                columns.append(pairing)
//            }
//
//            for (index, toColumn) in existing.clause.toColumns.enumerated() {
//                columns[index].to = toColumn
//            }
        }

        override init() {
            super.init()
            enabled = false
        }

        @objc dynamic var database: Database?

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
        @objc dynamic var destinationColumn: String?

        var toConstraint: ForeignKeyColumnConstraint {
            var clause = ForeignKeyClause(destination: selectedToTable?.name ?? "", columns: [destinationColumn ?? ""])

            if useOnUpdate {
                clause.actionStatements.append(ForeignKeyActionStatement(type: .update, result: ActionResult(rawValue: onUpdateIndex)!))
            }

            if useOnDelete {
                clause.actionStatements.append(ForeignKeyActionStatement(type: .delete, result: ActionResult(rawValue: onDeleteIndex)!))
            }

            if useMatchName, let name = matchName, !name.isEmpty {
                clause.matchStatements.append(contentsOf: name.components(separatedBy: ",").map({ForeignKeyMatchStatement(name: $0)}))
            }
            if useDeferrable {
                clause.deferStatement = ForeignKeyDeferStatement(deferrable: deferrableIndex == 0, type: DeferType(rawValue: deferrableTypeIndex)!)
            }

            return ForeignKeyColumnConstraint(name: constraintName, clause: clause)

        }

    }
}
