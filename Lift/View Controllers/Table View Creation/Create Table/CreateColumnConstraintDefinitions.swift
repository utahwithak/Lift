//
//  CreateColumnConstraintDefinitions.swift
//  Lift
//
//  Created by Carl Wieland on 9/17/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class CreateColumnConstraintDefinitions: NSObject {

    let existingConstraints: [ColumnConstraint]?

    override init() {
        existingConstraints = nil
    }

    init(constraints: [ColumnConstraint]) {
        self.existingConstraints = constraints
        if let defaultConst = constraints.compactMap({ $0 as? DefaultColumnConstraint}).first {
            defaultConstraint = CreateDefaultValue(existing: defaultConst)
        }
        if let primaryKey = constraints.compactMap({ $0 as? PrimaryKeyColumnConstraint}).first {
            self.primaryKey = CreatePrimaryKey(existing: primaryKey)
        }
        if let nonNull = constraints.compactMap({ $0 as? NotNullColumnConstraint}).first {
            self.nonNull = CreateNonNull(existing: nonNull)
        }
        if let unique = constraints.compactMap({ $0 as? UniqueColumnConstraint}).first {
            self.unique = CreateUnique(existing: unique)
        }
    }

    @objc dynamic var defaultConstraint: CreateDefaultValue?

    @objc dynamic var primaryKey: CreatePrimaryKey?

    @objc dynamic var unique: CreateUnique?

    @objc dynamic var nonNull: CreateNonNull?

    class CreateDefaultValue: NSObject {
        @objc dynamic var constraintName: String?
        @objc dynamic var value: String
        init(value: String) {
            self.value = value
        }
        init(existing: DefaultColumnConstraint) {
            constraintName = existing.constraintName
            value = existing.value.sql
        }
        var toConstraint: DefaultColumnConstraint {
            return DefaultColumnConstraint(name: constraintName, value: value)
        }
    }

    class CreatePrimaryKey: NSObject {
        @objc dynamic var constraintName: String?
        @objc dynamic var autoincrement = false
        @objc dynamic var sortOrder: Int = 0
        var conflictClause: ConflictClause?
        override init() {}
        init(existing: PrimaryKeyColumnConstraint) {
            self.constraintName = existing.constraintName
            self.autoincrement = existing.autoincrement
            self.sortOrder = existing.sortOrder.rawValue
            self.conflictClause = existing.conflictClause
        }
        var constraint: PrimaryKeyColumnConstraint {
            return PrimaryKeyColumnConstraint(name: constraintName, sortOrder: PrimaryKeySortOrder(rawValue: sortOrder) ?? .notSpecified, autoincrement: autoincrement, conflict: conflictClause)
        }
    }

    class CreateNonNull: NSObject {
        @objc dynamic var constraintName: String?
        var conflictClause: ConflictClause?
        init(existing: NotNullColumnConstraint) {
            conflictClause = existing.conflictClause
            constraintName = existing.constraintName
        }
        override init() {}
        var constraint: NotNullColumnConstraint {
            return NotNullColumnConstraint(name: constraintName, conflict: conflictClause)
        }
    }

    class CreateUnique: NSObject {
        @objc dynamic var constraintName: String?
        var conflictClause: ConflictClause?

        override init() {}
        init(existing: UniqueColumnConstraint) {
            constraintName = existing.constraintName
            conflictClause = existing.conflictClause
        }
        var toConstraint: UniqueColumnConstraint {
            return UniqueColumnConstraint(name: constraintName, conflict: conflictClause)
        }
    }

    var columnConstraints: [ColumnConstraint] {

        var constraints = [ColumnConstraint]()
        if let primary = primaryKey {
            constraints.append(primary.constraint)
        }

        if let unique = unique {
            constraints.append(unique.toConstraint)
        }

        if let nonNull = nonNull {
            constraints.append(nonNull.constraint)
        }

        if let defaultConstraint = defaultConstraint {
            constraints.append(defaultConstraint.toConstraint)
        }

        return constraints
    }
}
