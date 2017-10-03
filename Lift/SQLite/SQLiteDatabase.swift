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


class SQLiteDatabase {
    private static var inMemoryCount = 0

    convenience init(type: DatabaseType) throws {
        switch  type {
        case .inMemory(name: let name):
            let dbName = "file:memdb\(SQLiteDatabase.inMemoryCount)?mode=memory&cache=shared"
            var db: sqlite3?
            let ret = sqlite3_open(dbName, &db)
            guard ret == SQLITE_OK, let connection = db else {
                throw SQLiteError(code: ret)
            }
            try self.init(connection: connection, name: name)
            SQLiteDatabase.inMemoryCount += 1
        case .disk(path:let path, name:let name):
            var db: sqlite3?
            let ret = sqlite3_open(path.path, &db)
            guard ret == SQLITE_OK, let connection = db else {
                throw SQLiteError(code: ret)
            }

            try self.init(connection: connection, name: name)


        }

    }

    public let connection: sqlite3
    public let name: String

    private init(connection: sqlite3, name: String) throws {
        self.connection = connection
        self.name = name

        refresh()

    }


    func refresh() {

    }

    var allDatabases: [SQLiteDatabase] {
        return [self]
    }

}
