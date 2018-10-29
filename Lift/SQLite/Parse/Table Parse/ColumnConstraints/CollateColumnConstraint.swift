//
//  CollateColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct CollateColumnConstraint: ColumnConstraint {
    let constraintName: String?
    let collationName: SQLiteName

    init(name: String?, collationName: String) {
        self.constraintName = name
        self.collationName = collationName
    }

    init(with name: SQLiteName?, from scanner: Scanner) throws {

        guard scanner.scanString("COLLATE", into: nil) else {
            throw ParserError.unexpectedError("Expecting to parse default col const")
        }

        collationName = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        self.constraintName = name
    }

    var sql: String {
        var builder = ""
        if let name = constraintName {
            builder += "CONSTRAINT \(name) "
        }

        return builder + "COLLATE \(collationName.sql)"
    }
}
