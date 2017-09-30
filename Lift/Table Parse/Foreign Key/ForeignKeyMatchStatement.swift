//
//  ForeignKeyMatchStatement.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class ForeignKeyMatchStatement: Equatable {

    let name: SQLiteName

    init(from scanner: Scanner) throws {
        let rawName = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        name = SQLiteName(rawValue: rawName)
    }

    init(name: String) {
        self.name = SQLiteName(rawValue: name)
    }
    
}

func ==(lhs: ForeignKeyMatchStatement, rhs: ForeignKeyMatchStatement) -> Bool {
    return lhs.name == rhs.name
}
