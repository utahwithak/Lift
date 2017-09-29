//
//  UniqueTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class UniqueTableConstraint: IndexedTableConstraint {
    override init(from scanner: Scanner,named  name: String) throws {
        if !scanner.scanString("unique", into: nil) || !scanner.scanString("(", into: nil) {
            throw ParserError.unexpectedError("Invalid table Unique key")
        }
        try super.init(from: scanner, named: name)
    }
}
