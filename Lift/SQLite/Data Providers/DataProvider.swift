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

    let type: String

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
        guard case .text(let type) = data[0],
            case .text(let sql) = data[4],
            case .text(let name) = data[1] else {
                throw NSError(domain: "com.dataumapps.lift", code: -3, userInfo: [NSLocalizedDescriptionKey:"INAVALID table data row!"])
        }

        self.type = type
        
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

    func drop() throws -> Bool {
        guard let database = database else {
            throw NSError(domain: "com.datumapps.lift", code: -7, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("No Database!", comment: "No database to drop")])
        }

        let statement = "DROP \(type) \(qualifiedNameForQuery);"
        let success = try database.execute(statement: statement)

        if success {
           database.refresh()
        } else {
            print("Failed to refersh")
        }

        return success
    }

    enum CloneType {
        case toTemp
        case toMain
    }

    func cloneToDB(_ cloneType: CloneType, keepGoing: ()-> Bool) throws {
        
        guard let database = database else {
            throw NSError(domain: "com.datumapps.lift", code: -7, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("No Database!", comment: "No database error")])
        }

        var success = try database.execute(statement: "SAVEPOINT CLONEDB")

        do {
            var sql = self.sql
            if cloneType == .toTemp {
                guard let createRange = sql.range(of: "CREATE ") else {
                    return
                }

                sql.replaceSubrange(createRange, with: "CREATE TEMP ")
            }

            // sqlite_master strips out the tmp bit.
            success = try database.execute(statement: sql)

            if self.type == "table" {
                let intoName = cloneType == .toMain ? "main" : "temp"
                let selectStatement = "SELECT rowID, * FROM \(qualifiedNameForQuery)"
                let query = try Query(connection: connection, query: selectStatement)
                let colNames = ["rowID"] + columns.map { $0.name.sqliteSafeString() }
                let argStatements = (0..<colNames.count).map { "$\($0)" }.joined(separator: ", ")
                let valueStats = colNames.joined(separator: ", ")
                let insertStatement = "INSERT INTO \(intoName).\(name.sqliteSafeString())(\(valueStats)) VALUES (\(argStatements));"
                let insertQuery = try Query(connection: connection, query: insertStatement)
                try insertQuery.processData(from: query, keepGoing: keepGoing)
            }
            if keepGoing() {
                success = try database.execute(statement: "RELEASE SAVEPOINT CLONEDB")
            } else {
                success = try database.execute(statement: "ROLLBACK TRANSACTION TO SAVEPOINT CLONEDB")
            }
        } catch {
            success = try database.execute(statement: "ROLLBACK TRANSACTION TO SAVEPOINT CLONEDB")
            throw error
        }


        if success {
            DispatchQueue.main.async {
                (database.mainDB ?? database).refresh()
            }
        } else {
            print("Failed to clone")
        }
    }

}
