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

    let database: Database

    init(database: Database) {
        self.database = database
        existingConstraints = nil
    }

    init(constraints: [ColumnConstraint], database: Database) {
        self.database = database
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
        if let collate = constraints.compactMap({ $0 as? CollateColumnConstraint}).first {
            self.collate = CreateCollateConstraint(existing: collate)
        }
        if let check = constraints.compactMap({ $0 as? CheckColumnConstraint}).first {
            self.check = CreateCheckConstraint(existing: check)
        }

        let fKeys = constraints.compactMap({ $0 as? ForeignKeyColumnConstraint})
        for fKey in fKeys {
            foreignKeys.append(CreateColumnConstraintDefinitions.CreateForeignKeyConstraint(existing: fKey, database: database))
        }
        foreignKeys.append(CreateForeignKeyConstraint(database: database))

    }

    @objc dynamic var primaryKey: CreatePrimaryKey?

    @objc dynamic var nonNull: CreateNonNull? {
        willSet {
            willChangeValue(for: \.isNonNull)
        }
        didSet {
            didChangeValue(for: \.isNonNull)
        }
    }

    @objc dynamic var unique: CreateUnique?

    @objc dynamic var check: CreateCheckConstraint?

    @objc dynamic var collate: CreateCollateConstraint?

    @objc dynamic var foreignKeys = [CreateForeignKeyConstraint]()

    private var observeContext: NSKeyValueObservation?

    @objc dynamic var defaultConstraint: CreateDefaultValue? {
        willSet {
            observeContext = nil
        }
        didSet {
            if let newConstraint = defaultConstraint {
                observeContext = newConstraint.observe(\.value) { [weak self] (_, _) in
                    self?.willChangeValue(for: \.defaultExpression)
                    self?.didChangeValue(for: \.defaultExpression)
                }
            }
        }
    }

    @objc dynamic public var defaultExpression: String? {
        get {
            return defaultConstraint?.value
        }
        set {
            if let value = newValue {
                if defaultConstraint == nil {
                   defaultConstraint = CreateColumnConstraintDefinitions.CreateDefaultValue(value: value)
                } else {
                   defaultConstraint?.value = value
                }
                defaultConstraint?.enabled = true
            } else {
                defaultConstraint = nil
            }
        }
    }

    @objc dynamic var isNonNull: Bool {
        get {
            return nonNull != nil
        }
        set {
            if newValue {
                nonNull = CreateColumnConstraintDefinitions.CreateNonNull()
                nonNull?.enabled = true
            } else {
                nonNull = nil
            }
        }
    }

    func checkForeignKeys() {
        let allEnabled = foreignKeys.allSatisfy({ $0.enabled })
        if allEnabled {
            foreignKeys.append(CreateForeignKeyConstraint(database: database))
        }
    }

    var columnConstraints: [ColumnConstraint] {

        var constraints = [ColumnConstraint]()
        if let primary = primaryKey, primary.enabled {
            constraints.append(primary.constraint)
        }

        if let nonNull = nonNull, nonNull.enabled {
            constraints.append(nonNull.constraint)
        }

        if let unique = unique, unique.enabled {
            constraints.append(unique.toConstraint)
        }

        if let check = check, check.enabled {
            constraints.append(check.toConstraint)
        }

        if let defaultConstraint = defaultConstraint, defaultConstraint.enabled {
            constraints.append(defaultConstraint.toConstraint)
        }

        if let collate = collate, collate.enabled {
            constraints.append(collate.toConstraint)
        }

        for fkey in foreignKeys where fkey.enabled {
            constraints.append(fkey.toConstraint)
        }

        return constraints
    }

}
