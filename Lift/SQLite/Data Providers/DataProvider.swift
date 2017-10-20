//
//  DataProvider.swift
//  Lift
//
//  Created by Carl Wieland on 10/19/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class DataProvider: NSObject {
    let connection: sqlite3

    let name: String

    @objc dynamic let sql: String

    weak var database: Database?

    let columns: [Column]

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

        let query = try Query(connection: connection, query:  "PRAGMA \(database.name.sqliteSafeString()).table_info(\(name.sqliteSafeString()))")
        let columnData = try query.allRows()

        columns = try columnData.flatMap {
            return try Column(rowInfo: $0, connection: connection)
        }

        self.sql = sql
        self.name = name
        self.connection = connection

        super.init()

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
        return TableData(provider: self)
    }


}
