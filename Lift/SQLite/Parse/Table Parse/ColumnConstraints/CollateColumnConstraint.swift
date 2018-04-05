//
//  CollateColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class CollateColumnConstraint: ColumnConstraint {

    let collationName: SQLiteName

    init(with name: SQLiteName?, from scanner: Scanner) throws {

        guard scanner.scanString("COLLATE", into: nil) else {
            throw ParserError.unexpectedError("Expecting to parse default col const")
        }

        collationName = try SQLiteCreateTableParser.parseStringOrName(from: scanner)

        super.init(name: name)
    }

    override var sql: String {
        var builder = ""
        if let name = constraintName {
            builder += "CONSTRAINT \(name) "
        }

        return builder + "COLLATE \(collationName.sql)"
    }

    private init(copying: CollateColumnConstraint) {
        collationName = copying.collationName.copy
        super.init(name: copying.constraintName)
    }

    override func copy() -> ColumnConstraint {
        return CollateColumnConstraint(copying: self)
    }
}
