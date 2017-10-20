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

extension Notification.Name {
    static let DatabaseReloaded = Notification.Name("DatabaseReloaded")
    static let AttachedDatabasesChanged = Notification.Name("AttachedDatabasesChanged")
    
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
    public private(set) var systemTables = [Table]()

    public private(set) var views = [View]()

    private var tempDatabase: Database?

    private init(connection: sqlite3, name: String) {
        self.connection = connection
        self.name = name

        refresh()

        var success: Int32 = 0
        let rc = sqlite3_db_extension(connection, 1, &success)
        if rc != SQLITE_OK || success != 1 {
            print("Failed to enable extension!")
        }

    }


    func refresh() {

        refreshAttachedDatabases()
        refreshTables()
    }

    private func refreshTables() {
        do {
            tables.removeAll(keepingCapacity: true)
            systemTables.removeAll(keepingCapacity: true)
            views.removeAll(keepingCapacity: true)
            let clearedName = SQLiteName(rawValue: name)
            let refreshDBQuery = try Query(connection: self.connection, query: "SELECT * from \(clearedName.rawValue).sqlite_master where type in ('table', 'view') ORDER BY name;")

            try refreshDBQuery.processRows { (data) in
                //type|name|tbl_name|rootpage|sql
                guard case .text(let type) = data[0] else {
                    return
                }

                if type  == "table" {
                    let table = try Table(database: self, data: data, connection: connection)
                    if table.name.hasPrefix("sqlite_") {
                        systemTables.append(table)
                    } else {
                        tables.append(table)
                    }
                } else {
                    views.append(try View(database: self, data: data, connection: connection))
                }

            }

            systemTables.append(try Table(database: self, data: [.text("table"), .text("sqlite_master"),.text("sqlite_master"), .integer(0), .text("CREATE TABLE sqlite_master(type text,name text,tbl_name text, rootpage integer,sql text)")], connection: connection))
        } catch {
            print("Failed to refresh:\(error)")
        }



        NotificationCenter.default.post(name: .DatabaseReloaded, object: self)
    }

    private func refreshAttachedDatabases() {
        guard name == "main" else {
            return
        }

        attachedDatabases.removeAll()
        tempDatabase = Database(connection: connection, name: "temp")
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

    var attachedDatabases = [Database]() {
        didSet {
            NotificationCenter.default.post(name: .AttachedDatabasesChanged, object: self)
        }
    }

    var allDatabases: [Database] {

        guard name == "main" else {
            return []
        }
        
        var dbs = attachedDatabases
        dbs.insert(self, at: 0)
        if let tempDB = tempDatabase {
            dbs.insert(tempDB, at: 1)
        }


        return dbs
    }

    public func table(named name: String) -> Table? {
        return tables.first(where: { $0.name == name })
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


    public func attachDatabase(at path: URL, with name: String) throws -> Bool {

        let cleanedPath = path.path.sqliteSafeString()
        let sql = "ATTACH DATABASE \(cleanedPath) AS \(name.sqliteSafeString())"
        let success = try execute(statement: sql)
        if success {
            DispatchQueue.main.async { [weak self] in
                self?.refreshAttachedDatabases()
            }

        }
        return success

    }

    public func detachDatabase(named name: String) throws -> Bool {
        let sql = "DETACH DATABASE \(name.sqliteSafeString())"
        let success = try execute(statement: sql)
        if success {
            DispatchQueue.main.async { [weak self] in
                self?.refreshAttachedDatabases()
            }

        }
        return success
    }

    public func loadExtension(at path: URL, entryPoint: String? ) throws {
        let zFile = path.path
        var errorMsg: UnsafeMutablePointer<Int8>?
        let rc = sqlite3_load_extension(connection, zFile, entryPoint, &errorMsg)
        guard rc == SQLITE_OK else {
            if let msg = errorMsg {
                let str = String(cString: msg)
                print("Failed to load extension:\(str)")
            }
            throw SQLiteError(connection: connection, code: rc, sql: "sqlite3_load_extension(connection, zFile, entryPoint, &errorMsg)")
        }
    }
}
