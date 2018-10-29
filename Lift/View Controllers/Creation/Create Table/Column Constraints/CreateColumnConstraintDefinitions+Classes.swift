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
        init(value: String) {
            self.value = value
        }
        init(existing: DefaultColumnConstraint) {
            value = existing.value.sql
            super.init()
            constraintName = existing.constraintName
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
            self.sortOrder = existing.sortOrder.rawValue
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
}
