//
//  CreateColumnDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/17/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class CreateColumnDefinition: NSObject {

    let originalDefinition: ColumnDefinition?

    unowned let table: CreateTableDefinition

    @objc dynamic var type: String?

    @objc dynamic var name: String

    @objc dynamic let constraints: CreateColumnConstraintDefinitions

    @objc dynamic public var defaultExpression: String? {
        get {
            return constraints.defaultConstraint?.value
        }
        set {
            if let value = newValue {
                if constraints.defaultConstraint == nil {
                    constraints.defaultConstraint = CreateColumnConstraintDefinitions.CreateDefaultValue(value: value)
                } else {
                    constraints.defaultConstraint?.value = value
                }
            } else {
                constraints.defaultConstraint = nil
            }
        }
    }

    @objc dynamic var isPrimary: Bool {
        get {
            return constraints.primaryKey != nil || table.tableConstraints.primaryKey?.contains(self) == true
        }
        set {
            if newValue {
                // ensure it is added to the primary key table constraint as well as any other columns that may have column constraints
                if let tablePrimary = table.tableConstraints.primaryKey {
                    tablePrimary.add(column: self)
                } else {
                    //get any existing primary key constraint
                    let newConstraint = CreateTableConstraintDefinitions.CreatePrimaryKey()
                    if let existingPrimaryKey = table.columns.filter({ $0.constraints.primaryKey != nil }).first {
                        newConstraint.add(column: existingPrimaryKey)
                        existingPrimaryKey.constraints.primaryKey = nil
                    }
                    newConstraint.add(column: self)
                    table.tableConstraints.primaryKey = newConstraint
                }

            } else {
                constraints.primaryKey = nil

                if let tablePrimary = table.tableConstraints.primaryKey {
                    tablePrimary.remove(column: self)
                    if tablePrimary.columns.isEmpty {
                        table.tableConstraints.primaryKey = nil
                    }
                }
            }
        }
    }

    @objc dynamic var isUnique: Bool {
        get {
            return constraints.unique != nil || table.tableConstraints.uniques.first(where: {$0.contains(self)}) != nil
        }
        set {
            if newValue {
                if let tableUnique = table.tableConstraints.uniques.first {
                    tableUnique.add(column: self)
                } else {
                    //get any existing primary key constraint
                    let newConstraint = CreateTableConstraintDefinitions.CreateUnique()
                    for existingUnique in table.columns.filter({ $0.constraints.unique != nil }) {
                        newConstraint.add(column: existingUnique)
                        existingUnique.constraints.unique = nil
                    }

                    newConstraint.add(column: self)
                    table.tableConstraints.uniques.append(newConstraint)
                }

            } else {
                constraints.unique = nil
                if let constraint = table.tableConstraints.uniques.first(where: {$0.contains(self)}) {
                    constraint.remove(column: self)
                    if constraint.columns.isEmpty {
                        table.tableConstraints.uniques.removeAll(where: { $0 === constraint })
                    }
                }
            }
        }
    }

    @objc dynamic var isNonNull: Bool {
        get {
            return constraints.nonNull != nil
        }
        set {
            if newValue {
                constraints.nonNull = CreateColumnConstraintDefinitions.CreateNonNull()
            } else {
                constraints.nonNull = nil
            }
        }
    }

    init(name: String, table: CreateTableDefinition) {
        originalDefinition = nil
        self.name = name
        self.table = table
        constraints = CreateColumnConstraintDefinitions(constraints: [])
    }

    init(definition: ColumnDefinition, table: CreateTableDefinition) {
        name = definition.name
        self.table = table
        self.originalDefinition = definition
        type = definition.type
        constraints = CreateColumnConstraintDefinitions(constraints: definition.columnConstraints)
    }

    var toDefinition: ColumnDefinition {
        var def = ColumnDefinition(name: name)
        def.type = type
        def.columnConstraints = constraints.columnConstraints
        return def
    }

    @objc dynamic var sql: String {
        return toDefinition.creationStatement
    }
}

extension CreateColumnDefinition: ColumnNameProvider {}
