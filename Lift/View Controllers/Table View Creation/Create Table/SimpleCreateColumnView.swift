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
            if let column = column, let table = column.table {
                if let primaryTable = table.tableConstraints.first(where: { $0 is PrimaryKeyTableConstraint}) as? PrimaryKeyTableConstraint {
                    columnOptions.setSelected(primaryTable.contains(column), forSegment: 0)
                }
                if let unique = table.tableConstraints.first(where: { $0 is UniqueTableConstraint}) as? UniqueTableConstraint {
                    columnOptions.setSelected(unique.contains(column), forSegment: 1)
                }

                columnOptions.setSelected(column.columnConstraints.contains(where: { $0 is NotNullColumnConstraint}), forSegment: 2)
            }
        }
        get {
            return super.objectValue
        }
    }

    var column: ColumnDefinition? {
        return objectValue as? ColumnDefinition
    }

    private func checkPrimaryKey() {
        guard let column = column, let table = column.table else {
            return
        }

        let pkeyIndex = table.tableConstraints.index(where: { $0 is PrimaryKeyTableConstraint})
        if columnOptions.isSelected(forSegment: 0) {
            if let index = pkeyIndex, let primaryTableConstraint = table.tableConstraints[index] as? PrimaryKeyTableConstraint {
                primaryTableConstraint.addColumn(named: column)
            } else {
                let newConstrant = PrimaryKeyTableConstraint(initialColumn: column)
                table.tableConstraints.append(newConstrant)
            }
        } else if let index = pkeyIndex, let primaryTableConstraint = table.tableConstraints[index] as? PrimaryKeyTableConstraint {
            primaryTableConstraint.removeColumn(named: column)
            if primaryTableConstraint.indexedColumns.isEmpty {
                table.tableConstraints.remove(at: index)
            }
        }
    }

    private func checkUnique() {
        guard let column = column, let table = column.table else {
            return
        }

        let pkeyIndex = table.tableConstraints.index(where: { $0 is UniqueTableConstraint})
        if columnOptions.isSelected(forSegment: 1) {
            if let index = pkeyIndex, let constraint = table.tableConstraints[index] as? UniqueTableConstraint {
                constraint.addColumn(named: column)
            } else {
                let newConstrant = UniqueTableConstraint(initialColumn: column)
                table.tableConstraints.append(newConstrant)
            }
        } else if let index = pkeyIndex, let constraint = table.tableConstraints[index] as? UniqueTableConstraint {
            constraint.removeColumn(named: column)
            if constraint.indexedColumns.isEmpty {
                table.tableConstraints.remove(at: index)
            }
        }
    }

    private func checkNonNull() {
        guard let column = column else {
            return
        }

        if columnOptions.isSelected(forSegment: 2) {
            guard column.columnConstraints.index(where: { $0 is NotNullColumnConstraint}) == nil else {
                return
            }
            column.columnConstraints.append(NotNullColumnConstraint())
        } else if let index = column.columnConstraints.index(where: { $0 is NotNullColumnConstraint}) {
            column.columnConstraints.remove(at: index)
        }
    }
}
