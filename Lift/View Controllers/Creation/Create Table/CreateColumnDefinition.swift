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

    @objc dynamic var isPrimary: Bool {
        get {
            return constraints.primaryKey?.enabled == true || table.tableConstraints.primaryKey?.contains(self) == true
        }
        set {
            if newValue {
                // ensure it is added to the primary key table constraint as well as any other columns that may have column constraints
                if let tablePrimary = table.tableConstraints.primaryKey {
                    tablePrimary.add(column: self)
                } else {
                    //get any existing primary key constraint
                    let newConstraint = CreateTableConstraintDefinitions.CreatePrimaryKey(table: table)

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
            return constraints.unique?.enabled == true || table.tableConstraints.uniques.first(where: {$0.contains(self)}) != nil
        }
        set {
            if newValue {
                if let tableUnique = table.tableConstraints.uniques.first {
                    tableUnique.add(column: self)
                } else {
                    //get any existing primary key constraint
                    let newConstraint = CreateTableConstraintDefinitions.CreateUnique(table: table)
                    for existingUnique in table.columns.filter({ $0.constraints.unique != nil }) {
                        newConstraint.add(column: existingUnique)
                        existingUnique.constraints.unique = nil
                    }

                    newConstraint.add(column: self)
                    table.tableConstraints.add(unique: newConstraint)
                }

            } else {
                constraints.unique = nil
                if let constraint = table.tableConstraints.uniques.first(where: {$0.contains(self)}) {
                    constraint.remove(column: self)
                    if constraint.columns.isEmpty {
                        table.tableConstraints.remove(unique: constraint)
                    }
                }
            }
        }
    }

    init(name: String, table: CreateTableDefinition) {
        originalDefinition = nil
        self.name = name
        self.table = table
        constraints = CreateColumnConstraintDefinitions(constraints: [])

        super.init()
        observeCosntraint()
    }

    init(definition: ColumnDefinition, table: CreateTableDefinition) {
        name = definition.name
        self.table = table
        self.originalDefinition = definition
        type = definition.type
        constraints = CreateColumnConstraintDefinitions(constraints: definition.columnConstraints)

        super.init()
        observeCosntraint()
    }

    private func observeCosntraint() {
        constraints.addObserver(self, forKeyPath: "primaryKey.enabled", options: [], context: nil)
        constraints.addObserver(self, forKeyPath: "unique.enabled", options: [], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "primaryKey.enabled" {
            willChangeValue(for: \.isPrimary)
            didChangeValue(for: \.isPrimary)
        } else if keyPath == "unique.enabled" {
            willChangeValue(for: \.isUnique)
            didChangeValue(for: \.isUnique)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
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
