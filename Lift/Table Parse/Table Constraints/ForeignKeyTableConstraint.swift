//
//  ForeignKeyTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class ForeignKeyTableConstraint: TableConstraint {
    init(from scanner: Scanner, named name: String) throws {
        if !scanner.scanString("foreign", into: nil) || !scanner.scanString("key", into: nil) || !scanner.scanString("(", into: nil) {
            throw ParserError.unexpectedError("Invalid table check")
        }
        

        super.init(named: name)

    }
}
