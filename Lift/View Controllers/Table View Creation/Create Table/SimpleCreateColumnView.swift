//
//  SimpleCreateColumnView.swift
//  Lift
//
//  Created by Carl Wieland on 4/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Cocoa

class SimpleCreateColumnView: NSTableCellView {

    @IBOutlet weak var columnOptions: NSSegmentedControl!

    @IBAction func selectedIndexChanged(_ sender: NSSegmentedControl) {
        checkPrimaryKey()
        checkUnique()
        checkNonNull()
    }

    override var objectValue: Any? {
        set {
            super.objectValue = newValue
            guard let column = column else {
                return
            }
            if column.constraints.primaryKey != nil {
                columnOptions.setSelected(true, forSegment: 0)
            } else if let contains = column.table.tableConstraints.primaryKey?.contains(column), contains {
                columnOptions.setSelected(true, forSegment: 0)
            } else {
                columnOptions.setSelected(false, forSegment: 0)
            }

            if column.constraints.unique != nil {
                columnOptions.setSelected(true, forSegment: 1)
            } else if let contains = column.table.tableConstraints.unique?.contains(column), contains {
                columnOptions.setSelected(true, forSegment: 1)
            } else {
                columnOptions.setSelected(false, forSegment: 1)
            }

            columnOptions.setSelected(column.constraints.nonNull != nil, forSegment: 2)

        }
        get {
            return super.objectValue
        }
    }

    var column: CreateColumnDefinition? {
        return objectValue as? CreateColumnDefinition
    }

    private func checkPrimaryKey() {
        guard let column = column else {
            return
        }

        let table = column.table

        if columnOptions.isSelected(forSegment: 0) {
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
        guard let column = column else {
            return
        }

        let table = column.table

        if columnOptions.isSelected(forSegment: 0) {
            // ensure it is added to the primary key table constraint as well as any other columns that may have column constraints
            if let tablePrimary = table.tableConstraints.primaryKey {
                tablePrimary.add(column: column)
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
        guard let column = column else {
            return
        }
        if columnOptions.isSelected(forSegment: 2) {
            column.constraints.nonNull = CreateColumnConstraintDefinitions.CreateNonNull()
        } else {
            column.constraints.nonNull = nil
        }
    }
}
