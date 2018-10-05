//
//  Index.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class Index: NSObject {

    @objc dynamic let name: String
    @objc dynamic let tableName: String

    let parsedIndex: SQLiteIndexParser.Index?
    weak var database: Database?

    init(database: Database, data: [SQLiteData], connection: sqlite3) {
        self.database = database
        //type|name|tbl_name|rootpage|sql
        if case .text(let sql) = data[4] {
            do {
                parsedIndex = try SQLiteIndexParser.parse(sql: sql)
            } catch {
                parsedIndex = nil
                print("Failed to parse index sql: \(error)")
            }
        } else {
            parsedIndex = nil
        }

        if case .text(let name) = data[1] {
            self.name = name
        } else {
            name = ""
        }

        if case .text(let tbl_name) = data[2] {
            tableName = tbl_name
        } else {
            tableName = ""
        }
    }

    var qualifiedName: String {
        if let schemaName = database?.name {
            let dbname = schemaName
            return "\(dbname.sql).\(name.sqliteSafeString())"
        } else {
            return name.sqliteSafeString()
        }
    }

    public func drop(refresh: Bool = true) throws {
        guard let database = database else {
            throw LiftError.noDatabase
        }

        let statement = "DROP INDEX \(qualifiedName);"
        let success = try database.execute(statement: statement)

        if success && refresh {
            database.refresh()
        }

    }
}
