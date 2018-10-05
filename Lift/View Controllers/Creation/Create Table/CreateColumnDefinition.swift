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
}

extension CreateColumnDefinition: ColumnNameProvider {}
