//
//  Table.swift
//  Yield
//
//  Created by Carl Wieland on 4/3/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation
import SwiftXLSX

extension Notification.Name {
    static let TableDidChangeRowCount = NSNotification.Name("TableDidLoadRowCountNotification")
    static let TableDidBeginRefreshingRowCount = NSNotification.Name("TableDidStartRefreshingRowCount")
    static let TableDidEndRefreshingRowCount = NSNotification.Name("TableDidStartRefreshingRowCount")


}

class Table: DataProvider {

    let foreignKeys: [ForeignKeyConnection]

    let definition: TableDefinition


    override init(database: Database, data: [SQLiteData], connection: sqlite3) throws {

        //type|name|tbl_name|rootpage|sql
        guard case .text(let sql) = data[4],
            case .text(let name) = data[1] else {
            throw NSError(domain: "com.dataumapps.lift", code: -3, userInfo: [NSLocalizedDescriptionKey:"INAVALID table data row!"])
        }

        definition = try SQLiteCreateTableParser.parseSQL(sql)

        // Foreign Keys

        let foreignKeyQuery = try Query(connection: connection, query:  "PRAGMA \(database.name.sqliteSafeString()).foreign_key_list(\(name.sqliteSafeString()))")
        var curID = -1
        //id|seq|table|from|to|on_update|on_delete|match
        var curFrom = [String]()
        var curTo = [String]()
        var curToTable = ""
        var connections = [ForeignKeyConnection]()

        try foreignKeyQuery.processRows { rowData in
            guard case .integer(let id) = rowData[0],
                case .text(let toTable) = rowData[2],
                case .text(let fromCol) = rowData[3],
                case .text(let toCol) = rowData[4] else {
                    return
            }

            if id != curID {
                if !curTo.isEmpty {
                    connections.append(ForeignKeyConnection(fromTable: name, fromColumns: curFrom, toTable: curToTable, toColumns: curTo))
                    curFrom.removeAll(keepingCapacity: true)
                    curTo.removeAll(keepingCapacity: true)
                }
                curID = id
                curToTable = toTable
            }
            curFrom.append(fromCol)
            curTo.append(toCol)

        }
        if !curTo.isEmpty {
            connections.append(ForeignKeyConnection(fromTable: name, fromColumns: curFrom, toTable: curToTable, toColumns: curTo))
        }
        
        foreignKeys = connections

        try super.init(database: database, data: data, connection: connection)

        columns.forEach{ $0.table = self }
        for column in columns {
            column.definition = definition.columns.first(where: { $0.name.cleanedVersion == column.name })
        }

    }

    func foreignKeys(from columnName: String) -> [ForeignKeyConnection] {
        return foreignKeys.filter { $0.fromColumns.contains(columnName) }
    }

  
}
