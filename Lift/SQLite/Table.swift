//
//  Table.swift
//  Yield
//
//  Created by Carl Wieland on 4/3/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation
import SwiftXLSX

class Table {

    let connection: sqlite3

    let name: String

    var queryAcceptableName: String {
        return "\"\(name.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

//    let columns: [Column]

    init(name: String, connection: sqlite3) throws {
        self.name = name
        self.connection = connection
//
//        let query = try Query(query: "PRAGMA table_info(\"\(name.replacingOccurrences(of: "\"", with: "\"\""))\")", connection: connection)
//        let data = try query.allRows()
//        self.columns = try data.map { try Column(rowInfo: $0, connection: connection) }

    }

}
