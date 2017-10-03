//
//  UniqueTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class UniqueTableConstraint: IndexedTableConstraint {
    override init(with name: SQLiteName?,from scanner: Scanner) throws {
        if !scanner.scanString("unique", into: nil) || !scanner.scanString("(", into: nil) {
            throw ParserError.unexpectedError("Invalid table Unique key")
        }
        try super.init(with: name, from: scanner)
    }
}
