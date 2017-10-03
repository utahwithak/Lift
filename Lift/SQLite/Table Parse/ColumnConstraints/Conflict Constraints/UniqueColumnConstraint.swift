//
//  UniqueColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class UniqueColumnConstraint: ConflictColumnConstraint {

    override init(with name: SQLiteName?, from scanner: Scanner) throws {
        guard scanner.scanString("unique", into: nil) else {
            throw ParserError.unexpectedError("Expected Unique column constraint!")
        }

        try super.init(with: name,from: scanner)
        
    }
}