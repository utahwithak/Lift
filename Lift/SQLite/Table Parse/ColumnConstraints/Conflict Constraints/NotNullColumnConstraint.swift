//
//  NotNullColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class NotNullColumnConstraint: ConflictColumnConstraint {

    override init(with name: SQLiteName?, from scanner: Scanner) throws {
        guard scanner.scanString("NOT", into: nil) else {
            throw ParserError.unexpectedError("Expected not in not null constraint!")
        }
        guard scanner.scanString("NULL", into: nil) else {
            throw ParserError.unexpectedError("Expected null in not null constraint!")
        }

        try super.init(with: name,from: scanner)

    }
}
