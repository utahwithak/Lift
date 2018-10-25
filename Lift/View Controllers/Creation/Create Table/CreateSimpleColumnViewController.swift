//
//  CreateSimpleColumnViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/24/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class CreateSimpleColumnViewController: NSViewController {
    @objc dynamic var column: CreateColumnDefinition! {
        didSet {
            columnName = column.name
            type = column.type
            defaultValue = column.defaultExpression
            isPrimary = column.isPrimary
            isUnique = column.isUnique
            isNonNull = column.isNonNull
        }
    }

    @objc dynamic var columnName: String = ""
    @objc dynamic var type: String?
    @objc dynamic var defaultValue: String?
    @objc dynamic var isPrimary = false
    @objc dynamic var isUnique = false
    @objc dynamic var isNonNull = false

    weak var delegate: SimpleCreateColumnDelegate?

    @IBAction func doneEditing(_ sender: Any) {
        checkPrimaryKey()
        checkUnique()
        checkNonNull()
        delegate?.didFinishEditing(definition: column)
        dismiss(self)
    }

    private func checkPrimaryKey() {
        let table = column.table

        if isPrimary {
            // ensure it is added to the primary key table constraint as well as any other columns that may have column constraints
            if let tablePrimary = table.tableConstraints.primaryKey {
                tablePrimary.add(column: column)
            } else {
                //get any existing primary key constraint
                let newConstraint = CreateTableConstraintDefinitions.CreatePrimaryKey()
                if let existingPrimaryKey = table.columns.filter({ $0.constraints.primaryKey != nil }).first {
                    newConstraint.add(column: existingPrimaryKey)
                    existingPrimaryKey.constraints.primaryKey = nil
                }
                newConstraint.add(column: column)
                table.tableConstraints.primaryKey = newConstraint
            }

        } else {
            column.constraints.primaryKey = nil

            if let tablePrimary = table.tableConstraints.primaryKey {
                tablePrimary.remove(column: column)
                if tablePrimary.columns.isEmpty {
                    table.tableConstraints.primaryKey = nil
                }
            }
        }
    }
    private func checkUnique() {

        let table = column.table

        if isUnique {
            if let tableUnique = table.tableConstraints.unique {
                tableUnique.add(column: column)
            } else {
                //get any existing primary key constraint
                let newConstraint = CreateTableConstraintDefinitions.CreateUnique()
                for existingUnique in table.columns.filter({ $0.constraints.unique != nil }) {
                    newConstraint.add(column: existingUnique)
                    existingUnique.constraints.unique = nil
                }

                newConstraint.add(column: column)
                table.tableConstraints.unique = newConstraint
            }

        } else {
            column.constraints.unique = nil
            if let constraints = table.tableConstraints.unique {
                constraints.remove(column: column)
                if constraints.columns.isEmpty {
                    table.tableConstraints.unique = nil
                }
            }
        }
    }

    private func checkNonNull() {

        if isNonNull {
            column.constraints.nonNull = CreateColumnConstraintDefinitions.CreateNonNull()
        } else {
            column.constraints.nonNull = nil
        }
    }
}


protocol SimpleCreateColumnDelegate: class {
    func didFinishEditing(definition: CreateColumnDefinition)
}
