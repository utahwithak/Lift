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

    @objc dynamic let name: String

    @objc dynamic let type: String

    @objc dynamic let sql: String

    weak var database: Database?

    @objc dynamic var isEditable: Bool {
        return false
    }

    let columns: [Column]

    var rowCount: Int? {
        didSet {
            NotificationCenter.default.post(name: .TableDidChangeRowCount, object: self)
        }
    }
    public private(set) var refreshingRowCount = false {
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
                throw LiftError.invalidTable
        }

        self.type = type

        let query = try Query(connection: connection, query: "PRAGMA \(database.name.sqliteSafeString()).table_info(\(name.sqliteSafeString()))")
        let columnData = try query.allRows()

        columns = try columnData.compactMap {
            return try Column(rowInfo: $0, connection: connection)
        }

        self.sql = sql
        self.name = name
        self.connection = connection

        super.init()

        refreshTableCount()

    }

    public func refreshTableCount() {

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
        return TableData(provider: self, customSorting: [])
    }

    func drop(refresh: Bool = true) throws -> Bool {
        guard let database = database else {
            throw LiftError.noDatabase
        }

        let statement = "DROP \(type) \(qualifiedNameForQuery);"
        let success = try database.execute(statement: statement)

        if success && refresh {
           database.refresh()
        }

        return success
    }

    enum TransferType {
        case cloneToTemp
        case cloneToMain
        case moveToTemp
        case moveToMain

        var isMove: Bool {
            switch self {
            case .moveToMain, .moveToTemp:
                return true
            default:
                return false
            }
        }
        var isToTemp: Bool {
            switch self {
            case .cloneToTemp, .moveToTemp:
                return true
            default:
                return false
            }
        }

    }

    func transfer(with transferType: TransferType, keepGoing: () -> Bool) throws {

        guard let database = database else {
            throw LiftError.noDatabase
        }

        var success = try database.execute(statement: "SAVEPOINT CLONEDB")

        do {
            var sql = self.sql
            if transferType.isToTemp {
                guard let createRange = sql.range(of: "CREATE ") else {
                    return
                }

                sql.replaceSubrange(createRange, with: "CREATE TEMP ")
            }

            // sqlite_master strips out the tmp bit.
            success = try database.execute(statement: sql)

            if self.type == "table" {
                let intoName = transferType.isToTemp ? "temp" : "main"
                let selectStatement = "SELECT rowID, * FROM \(qualifiedNameForQuery)"
                let query = try Query(connection: connection, query: selectStatement)
                let colNames = ["rowID"] + columns.map { $0.name.sqliteSafeString() }
                let argStatements = (0..<colNames.count).map { "$\($0)" }.joined(separator: ", ")
                let valueStats = colNames.joined(separator: ", ")
                let insertStatement = "INSERT INTO \(intoName).\(name.sqliteSafeString())(\(valueStats)) VALUES (\(argStatements));"
                let insertQuery = try Query(connection: connection, query: insertStatement)
                try insertQuery.processData(from: query, keepGoing: keepGoing)
            }

            if transferType.isMove {
                success = try drop(refresh: false)
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
