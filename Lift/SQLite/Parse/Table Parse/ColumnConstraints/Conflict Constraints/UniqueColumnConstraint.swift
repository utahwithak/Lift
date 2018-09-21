//
//  UniqueColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class UniqueColumnConstraint: ConflictColumnConstraint {

    let constraintName: SQLiteName?

    let conflictClause: ConflictClause?

    init(with name: SQLiteName?, from scanner: Scanner) throws {
        guard scanner.scanString("unique", into: nil) else {
            throw ParserError.unexpectedError("Expected Unique column constraint!")
        }
        conflictClause = try ConflictClause(from: scanner)

        constraintName = name
    }

    init(name: SQLiteName?, conflict: ConflictClause?) {
        constraintName = name
        conflictClause = conflict
    }

    var sql: String {
        var builder = ""
        if let name = constraintName?.sql {
            builder += "CONSTRAINT \(name) "
        }
        builder += "UNIQUE "

        if let conflictClause = conflictClause {
            builder += conflictClause.sql
        }

        return builder
    }

}
