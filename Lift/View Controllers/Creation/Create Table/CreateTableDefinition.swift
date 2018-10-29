//
//  TableDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/17/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class CreateTableDefinition: NSObject {
    @objc dynamic var tableName: String = "" {
        willSet {
            willChangeValue(for: \.hasValidName)
        }
        didSet {
            didChangeValue(for: \.hasValidName)
        }
    }
    @objc dynamic var databaseName: String?

    @objc dynamic var isTemp = false

    @objc dynamic var withoutRowID = false

    override init() {
        originalDefinition = nil
        super.init()
        tableConstraints = CreateTableConstraintDefinitions(table: self)
    }

    init(existingDefinition: TableDefinition) {
        originalDefinition = existingDefinition
        tableName = existingDefinition.tableName
        databaseName = existingDefinition.databaseName
        isTemp = existingDefinition.isTemp
        withoutRowID = existingDefinition.withoutRowID

        super.init()

        columns = existingDefinition.columns.map { CreateColumnDefinition(definition: $0, table: self)}
        tableConstraints = CreateTableConstraintDefinitions(definitions: existingDefinition.tableConstraints, table: self)

    }

    @objc dynamic var columns = [CreateColumnDefinition]()

    @objc dynamic var tableConstraints: CreateTableConstraintDefinitions!

    @objc dynamic var hasValidName: Bool {
        return !tableName.isEmpty
    }

    public let originalDefinition: TableDefinition?

    public var toDefinition: TableDefinition {
        var definition = TableDefinition()
        definition.tableName = tableName
        definition.withoutRowID = withoutRowID
        definition.databaseName = databaseName
        definition.isTemp = isTemp

        for column in columns {
            definition.columns.append(column.toDefinition)
        }
        definition.tableConstraints = tableConstraints.constraints
        return definition
    }
}
