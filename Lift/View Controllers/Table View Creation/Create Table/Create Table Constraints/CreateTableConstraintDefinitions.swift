//
//  CreateTableConstraintDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/17/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

protocol CreateTableConstraint: class {
    var toDefinition: TableConstraint { get }
}

class CreateTableConstraintDefinitions: NSObject {

    let existingDefinitions: [TableConstraint]

    unowned let table: CreateTableDefinition

    @objc public var primaryKey: CreatePrimaryKey?

    @objc public var unique: CreateUnique?

    init(table: CreateTableDefinition) {
        existingDefinitions = []
        self.table = table
    }

    init(definitions: [TableConstraint], table: CreateTableDefinition) {
        self.table = table
        existingDefinitions = definitions
        if let pk = existingDefinitions.compactMap({ $0 as? PrimaryKeyTableConstraint}).first {
            primaryKey = CreatePrimaryKey(existing: pk, in: table)
        }
    }

    var constraints: [TableConstraint] {
        var constraints = [TableConstraint]()

        if let primary = primaryKey {
            constraints.append(primary.toDefinition)
        }

        if let unique = unique {
            constraints.append(unique.toDefinition)
        }

        return constraints
    }
}
