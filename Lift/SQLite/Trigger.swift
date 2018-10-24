//
//  Trigger.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class Trigger: NSObject {

    public private(set) weak var database: Database?

    @objc dynamic let name: String
    let parsedTrigger: TriggerParser.Trigger?
    let sql: String

    init(database: Database, data: [SQLiteData], connection: sqlite3) {
        self.database = database
        //type|name|tbl_name|rootpage|sql
        if case .text(let sql) = data[4] {
            do {
                parsedTrigger = try TriggerParser.parseTrigger(from: sql)
            } catch {
                parsedTrigger = nil
                print("Failed to parse index sql: \(error)")
            }
            self.sql = sql
        } else {
            sql = "NO SQL"
            parsedTrigger = nil
        }

        if case .text(let name) = data[1] {
            self.name = name
        } else {
            name = ""
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

        let statement = "DROP TRIGGER \(qualifiedName);"
        let success = try database.execute(statement: statement)

        if success && refresh {
            database.refresh()
        }

    }
}
