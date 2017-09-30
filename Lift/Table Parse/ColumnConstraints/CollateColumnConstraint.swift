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

    init(with name: String, from scanner: Scanner) throws {

        guard scanner.scanString("COLLATE", into: nil) else {
            throw ParserError.unexpectedError("Expecting to parse default col const")
        }

        let rawName = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        collationName = SQLiteName(rawValue: rawName)
        super.init(name: name)
    }
}
