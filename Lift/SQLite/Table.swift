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

class Table {

    let connection: sqlite3

    let name: String

    let columns: [Column]

    let foreignKeys: [ForeignKeyConnection]

    let definition: TableDefinition

    weak var database: Database?

    var rowCount: Int? {
        didSet {
            NotificationCenter.default.post(name: .TableDidChangeRowCount, object: self)
        }
    }
    private var refreshingRowCount = false {
        didSet {
            if refreshingRowCount {
                NotificationCenter.default.post(name: .TableDidBeginRefreshingRowCount, object: self)
            } else {
                NotificationCenter.default.post(name: .TableDidEndRefreshingRowCount, object: self)
            }
        }
    }

    init(database: Database, data: [SQLiteData], connection: sqlite3) throws {
        self.database = database
        //type|name|tbl_name|rootpage|sql
        guard case .text(let sql) = data[4],
            case .text(let name) = data[1] else {
            throw NSError(domain: "com.dataumapps.lift", code: -3, userInfo: [NSLocalizedDescriptionKey:"INAVALID table data row!"])
        }
        self.name = name

        let definition = try SQLiteCreateTableParser.parseSQL(sql)
        self.connection = connection

        // Columns
        
        let query = try Query(connection: connection, query:  "PRAGMA \(database.name.sqliteSafeString()).table_info(\(name.sqliteSafeString()))")
        let data = try query.allRows()

        columns = try data.flatMap {

            guard case .text(let name) = $0[1], let def = definition.columns.first(where: {
                $0.name.cleanedVersion == name

            }) else {
                return nil
            }

            return try Column(rowInfo: $0, definition: def, connection: connection)
        }
        self.definition = definition

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

        columns.forEach{ $0.table = self }


        refreshTableCount()

    }


    private func refreshTableCount() {

        guard !refreshingRowCount else {
            return
        }

        do {
            refreshingRowCount = true
            var query: Query? = try Query(connection: connection, query: "SELECT COUNT(*) FROM \(qualifiedNameForQuery)")
            query?.loadInBackground(completion: { [weak self] (result) in

                defer {
                    query = nil
                }
                var rowCount: Int?
                if case .success(let data) = result, let firstRow = data.first, let firstData = firstRow.first {
                    if case .integer(let num) = firstData {
                        rowCount = num
                    }
                }

                self?.rowCount = rowCount
                self?.refreshingRowCount = false

            })
        } catch {
            print("Failed to get row co:\(error)")
        }
    }

    var qualifiedNameForQuery: String {
        if let schemaName = database?.name {
            let dbname = SQLiteName(rawValue: schemaName)
            return "\(dbname.sql).\(name.sqliteSafeString())"
        } else {
            return name.sqliteSafeString()
        }
    }

    var basicData: TableData {
        return TableData(table: self)
    }

}
