//
//  View.swift
//  Lift
//
//  Created by Carl Wieland on 10/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class View: DataProvider {
    public private(set) var definition: ViewDefinition?

    override init(database: Database, data: [SQLiteData], connection: sqlite3) throws {
        try super.init(database: database, data: data, connection: connection)
        definition = try? SQLiteCreateViewParser.parse(sql: sql)
    }
    
}
