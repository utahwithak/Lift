//
//  ForeignKeyMatchStatement.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct ForeignKeyMatchStatement: Equatable {

    let name: String

    init(from scanner: Scanner) throws {
        name = try SQLiteCreateTableParser.parseStringOrName(from: scanner).rawValue
    }

    init(name: String) {
        self.name = name
    }

    var sql: String {
        return "MATCH \(name.sqliteSafeString()) "
    }
}

func == (lhs: ForeignKeyMatchStatement, rhs: ForeignKeyMatchStatement) -> Bool {
    return lhs.name == rhs.name
}
