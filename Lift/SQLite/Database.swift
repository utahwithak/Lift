//
//  SQLiteDatabase.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

enum DatabaseType {
    case inMemory(name: String)
    case disk(path: URL, name: String)
}

typealias sqlite3 = OpaquePointer


class Database {
    private static var inMemoryCount = 0

    convenience init(type: DatabaseType) throws {
        switch  type {
        case .inMemory(name: let name):
            let dbName = "file:memdb\(Database.inMemoryCount)?mode=memory&cache=shared"
            var db: sqlite3?
            let ret = sqlite3_open(dbName, &db)
            guard ret == SQLITE_OK, let connection = db else {
                throw SQLiteError(connection: db, code: ret, sql: "Opening with: \(dbName)")
            }
            self.init(connection: connection, name: name)
            Database.inMemoryCount += 1
        case .disk(path:let path, name:let name):
            var db: sqlite3?
            let ret = sqlite3_open(path.path, &db)
            guard ret == SQLITE_OK, let connection = db else {
                throw SQLiteError(connection: db, code: ret, sql: "Opening path:\(path.path)")
            }

            self.init(connection: connection, name: name)
        }

    }

    public let connection: sqlite3
    public let name: String

    public private(set) var tables = [Table]()
    public private(set) var views = [View]()


    private init(connection: sqlite3, name: String) {
        self.connection = connection
        self.name = name

        refresh()

    }


    func refresh() {

        refreshAttachedDatabases()

        do {
            let clearedName = SQLiteName(rawValue: name)
            let refreshDBQuery = try Query(connection: self.connection, query: "SELECT * from \(clearedName.rawValue).sqlite_master where type in ('table', 'view');")

            try refreshDBQuery.processRows { (data) in
                //type|name|tbl_name|rootpage|sql
                guard case .text(let type) = data[0],
                      case .text(let name) = data[1] else {
                    return
                }

                if type  == "table" {
                    tables.append(try Table(name: name, connection: connection))
                } else {
                    views.append(try View(name: name, connection: connection))
                }

            }

        } catch {
            print("Failed to refresh:\(error)")
        }

    }

    public func refreshAttachedDatabases() {
        guard name == "main" else {
            return
        }

        attachedDatabases.removeAll()
        attachedDatabases.append(Database(connection: connection, name: "temp"))

        do {
            let query = try Query(connection: connection, query: "PRAGMA database_list")
            try query.processRows(handler: { row in
                if (row[0].intValue ?? 0) <= 1 { //skip the main and temp databases
                    return
                }

                guard case .text(let name) = row[1] else {
                    return
                }

                attachedDatabases.append(Database(connection: self.connection, name: name))

            })

        } catch {
            print("Failed to refresh database list:\(error)")
        }
    }

    var attachedDatabases = [Database]()

    var allDatabases: [Database] {
        return attachedDatabases + [self]
    }

    public func execute(statement: String) throws -> Bool {
        let statement = try Statement(connection: connection, text: statement)
        return try statement.step()
    }

    public func executeStatementInBackground(_ statement: String, completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            var returnError: Error?

            do {
                let statement = try Statement(connection: self.connection, text: statement)
                let rc = try statement.step()

                if !rc {
                    print("INVALID USAGE! SHOULD NOT BE EXPECTING ROWS HERE!")
                    returnError = NSError(domain: "com.datumapps.lift", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid usage!"])
                }

            } catch {
                returnError = error
            }

            DispatchQueue.main.async {
                completion(returnError)
            }
        }
    }


    public func attachDatabase(at path: URL, with name: String, completion:  @escaping (Error?) -> Void) {
        let cleanedName = SQLiteName(rawValue: name)
        let cleanedPath = path.path.replacingOccurrences(of: "\"", with: "\"\"")
        let sql = "ATTACH DATABASE \(cleanedPath) AS \(cleanedName.sql)"
        executeStatementInBackground(sql, completion: completion)

    }

}
