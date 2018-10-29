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

    @objc public var createConstraints = [CreateTableConstraintRowItem]()

    var primaryKey: CreatePrimaryKey? {

        get {
            return createConstraints.compactMap({ $0.primaryKey }).first
        }
        set {
            willChangeValue(for: \.createConstraints)

            createConstraints = createConstraints.filter({$0.primaryKey == nil })
            if let newValue = newValue {
                createConstraints.append(CreateTableConstraintRowItem(primaryKey: newValue))
            }
            didChangeValue(for: \.createConstraints)

        }

    }

    @objc public var uniques: [CreateUnique] {
        return createConstraints.compactMap({ $0.unique })
    }

    func remove(unique: CreateUnique) {
        if let index = createConstraints.index(where: { $0 === unique}) {
            createConstraints.remove(at: index)
        }
    }

    func add(unique: CreateUnique) {
        createConstraints.append(CreateTableConstraintRowItem(uniqueKey: unique))
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
                let columns = primaryKey?.columns
                columns?.forEach({ $0.column.willChangeValue(for: \.isPrimary)})
                primaryKey = nil
                columns?.forEach({ $0.column.didChangeValue(for: \.isPrimary)})
                unique = nil
                check = nil
                foreignKey = nil

                switch TableConstraintType(rawValue: type)! {
                case .primaryKey:
                    primaryKey = CreateTableConstraintDefinitions.CreatePrimaryKey()
                case .unique:

                    unique = CreateTableConstraintDefinitions.CreateUnique()
                case .check:
                    check = CreateTableConstraintDefinitions.CreateCheckConstraint()
                case .foreignKey:
                    foreignKey = CreateTableConstraintDefinitions.CreateForeignKeyConstraint()
                }
            }
        }
    }

    @objc dynamic var enabled = false

    @objc dynamic var constraintName: String?

    @objc dynamic public var primaryKey: CreateTableConstraintDefinitions.CreatePrimaryKey?
    @objc dynamic public var unique: CreateTableConstraintDefinitions.CreateUnique?
    @objc dynamic public var check: CreateTableConstraintDefinitions.CreateCheckConstraint?
    @objc dynamic public var foreignKey: CreateTableConstraintDefinitions.CreateForeignKeyConstraint?

    var constraint: TableConstraint? {
        guard enabled else {
            return nil
        }
        primaryKey?.name = constraintName
        unique?.name = constraintName
        check?.name = constraintName
        foreignKey?.name = constraintName
        return primaryKey?.toDefinition ?? unique?.toDefinition ?? check?.toDefinition ?? foreignKey?.toDefinition
    }

    init(type: TableConstraintType) {
        self.type = type.rawValue
        switch type {
        case .primaryKey:
            primaryKey = CreateTableConstraintDefinitions.CreatePrimaryKey()
        case .unique:
            unique = CreateTableConstraintDefinitions.CreateUnique()
        case .check:
            check = CreateTableConstraintDefinitions.CreateCheckConstraint()
        case .foreignKey:
            foreignKey = CreateTableConstraintDefinitions.CreateForeignKeyConstraint()
        }
    }
    init(primaryKey: CreateTableConstraintDefinitions.CreatePrimaryKey) {
        enabled = true
        type = TableConstraintType.primaryKey.rawValue
        self.primaryKey = primaryKey
    }

    init(uniqueKey: CreateTableConstraintDefinitions.CreateUnique) {
        enabled = true
        type = TableConstraintType.unique.rawValue
        self.unique = uniqueKey
    }
}
