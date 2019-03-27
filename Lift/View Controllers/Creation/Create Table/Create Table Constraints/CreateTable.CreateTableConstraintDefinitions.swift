//
//  CreateTableConstraintDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/17/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

protocol CreateTableConstraint: class {
    var constraintName: String? { get set }
    var toDefinition: TableConstraint { get }
}

class CreateTableConstraintDefinitions: NSObject {

    let existingDefinitions: [TableConstraint]

    unowned let table: CreateTableDefinition

    @objc dynamic public var createConstraints = [CreateTableConstraintRowItem]()

    var primaryKey: CreatePrimaryKey? {

        get {
            return createConstraints.compactMap({ $0.primaryKey }).first
        }
        set {

            createConstraints = createConstraints.filter({$0.primaryKey == nil })
            if let newValue = newValue {
                createConstraints.append(CreateTableConstraintRowItem(primaryKey: newValue, table: table))
            }

        }

    }

    @objc public var uniques: [CreateUnique] {
        return createConstraints.compactMap({ $0.unique })
    }

    func remove(unique: CreateUnique) {
        if let index = createConstraints.firstIndex(where: { $0 === unique}) {
            createConstraints.remove(at: index)
        }
    }

    func add(unique: CreateUnique) {
        createConstraints.append(CreateTableConstraintRowItem(uniqueKey: unique, table: table))
    }

    init(table: CreateTableDefinition) {
        existingDefinitions = []
        self.table = table
    }

    init(definitions: [TableConstraint], table: CreateTableDefinition) {
        self.table = table
        existingDefinitions = definitions

        super.init()

        if let pk = existingDefinitions.compactMap({ $0 as? PrimaryKeyTableConstraint}).first {
            primaryKey = CreatePrimaryKey(existing: pk, in: table)
        }

        let uniques = existingDefinitions.compactMap({ $0 as? UniqueTableConstraint})
        for unique in uniques {
            add(unique: CreateUnique(existing: unique, in: table))
        }

        let checks = existingDefinitions.compactMap({ $0 as? CheckTableConstraint })
        for check in checks {
            createConstraints.append(CreateTableConstraintRowItem(check: CreateCheckConstraint(existing: check), table: table))
        }
        let fkeys = existingDefinitions.compactMap({ $0 as? ForeignKeyTableConstraint })
        for fkey in fkeys {
            createConstraints.append(CreateTableConstraintRowItem(fKey: CreateForeignKeyConstraint(existing: fkey, table: table), table: table))

        }
    }

    var constraints: [TableConstraint] {
        return createConstraints.compactMap { $0.constraint }
    }
}

class CreateTableConstraintRowItem: NSObject {

    enum TableConstraintType: Int {
        case primaryKey
        case unique
        case check
        case foreignKey
    }

    @objc dynamic var type: Int {
        didSet {
            if type != oldValue {
                primaryKey = nil
                unique = nil
                check = nil
                foreignKey = nil
                update(with: TableConstraintType(rawValue: type))

            }
        }
    }

    private func update(with type: TableConstraintType?) {
        guard let type = type else {
            return
        }
        switch type {
        case .primaryKey:
            primaryKey = CreateTableConstraintDefinitions.CreatePrimaryKey(table: table)
        case .unique:
            unique = CreateTableConstraintDefinitions.CreateUnique(table: table)
        case .check:
            check = CreateTableConstraintDefinitions.CreateCheckConstraint()
        case .foreignKey:
            foreignKey = CreateTableConstraintDefinitions.CreateForeignKeyConstraint(table: table)
        }
    }

    @objc dynamic var constraintName: String?

    @objc dynamic public var primaryKey: CreateTableConstraintDefinitions.CreatePrimaryKey?
    @objc dynamic public var unique: CreateTableConstraintDefinitions.CreateUnique?
    @objc dynamic public var check: CreateTableConstraintDefinitions.CreateCheckConstraint?
    @objc dynamic public var foreignKey: CreateTableConstraintDefinitions.CreateForeignKeyConstraint?

    @objc dynamic public let table: CreateTableDefinition

    var constraint: TableConstraint? {
        primaryKey?.name = constraintName
        unique?.name = constraintName
        check?.name = constraintName
        foreignKey?.name = constraintName
        return primaryKey?.toDefinition ?? unique?.toDefinition ?? check?.toDefinition ?? foreignKey?.toDefinition
    }

    init(type: TableConstraintType, table: CreateTableDefinition) {
        self.table = table
        self.type = type.rawValue
        super.init()
        update(with: type)
    }
    init(primaryKey: CreateTableConstraintDefinitions.CreatePrimaryKey, table: CreateTableDefinition) {
        type = TableConstraintType.primaryKey.rawValue
        self.primaryKey = primaryKey
        constraintName = primaryKey.name
        self.table = table
    }

    init(uniqueKey: CreateTableConstraintDefinitions.CreateUnique, table: CreateTableDefinition) {
        self.table = table
        type = TableConstraintType.unique.rawValue
        self.unique = uniqueKey
        constraintName = uniqueKey.name
    }
    init(check: CreateTableConstraintDefinitions.CreateCheckConstraint, table: CreateTableDefinition) {
        self.table = table
        type = TableConstraintType.check.rawValue
        self.check = check
        constraintName = check.name
    }

    init(fKey: CreateTableConstraintDefinitions.CreateForeignKeyConstraint, table: CreateTableDefinition) {
        self.table = table
        type = TableConstraintType.foreignKey.rawValue
        self.foreignKey = fKey
        constraintName = fKey.name
    }
}
