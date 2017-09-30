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
}
