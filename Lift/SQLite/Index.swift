//
//  Index.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class Index: NSObject {

    let name: String
    let parsedIndex: SQLiteIndexParser.Index?

    init(database: Database, data: [SQLiteData], connection: sqlite3) {
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
    }
}
