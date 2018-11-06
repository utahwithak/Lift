//
//  ForeignKeyConnectionViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/5/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class ForeignKeyConnectionViewController: LiftViewController {

    @objc dynamic var foreignKeys = [ForeignKeyRow]()

    override var selectedTable: DataProvider? {
        didSet {
            if let table = selectedTable as? Table {
                refresh(with: table)
            } else {
                clear()
            }
        }
    }

    private func refresh(with table: Table) {
        var fKeys = [ForeignKeyRow]()
        for fKey in table.foreignKeys {
            fKeys.append(ForeignKeyRow(connection: fKey))
        }
        if let db = table.database {
            for otherTable in db.tables {
                let referencingConnections = otherTable.foreignKeys.filter({$0.toTable.cleanedVersion == table.name.cleanedVersion })
                fKeys.append(contentsOf: referencingConnections.map({ ForeignKeyRow(connection: $0)}))
            }
        }
        foreignKeys = fKeys
    }

    private func clear() {
        foreignKeys.removeAll(keepingCapacity: true)
    }

    class ForeignKeyRow: NSObject {

        @objc dynamic var fromTable: String
        @objc dynamic var fromColumns: String
        @objc dynamic var toTable: String
        @objc dynamic var toColumns: String
        init(connection: ForeignKeyConnection) {
            fromTable = connection.fromTable
            fromColumns = connection.fromColumns.joined(separator: ", ")
            toTable = connection.toTable
            toColumns = connection.toColumns?.joined(separator: ", ") ?? ""
        }
    }
}
