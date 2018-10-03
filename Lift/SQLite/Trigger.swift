//
//  Trigger.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class Trigger: NSObject {

    @objc dynamic let name: String
    let parsedTrigger: TriggerParser.Trigger?

    init(database: Database, data: [SQLiteData], connection: sqlite3) {
        //type|name|tbl_name|rootpage|sql
        if case .text(let sql) = data[4] {
            do {
                parsedTrigger = try TriggerParser.parseTrigger(from: sql)
            } catch {
                parsedTrigger = nil
                print("Failed to parse index sql: \(error)")
            }
        } else {
            parsedTrigger = nil
        }

        if case .text(let name) = data[1] {
            self.name = name
        } else {
            name = ""
        }
    }
}
