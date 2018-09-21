//
//  NotNullColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct NotNullColumnConstraint: ConflictColumnConstraint {

    let constraintName: SQLiteName?

    let conflictClause: ConflictClause?

    init(with name: SQLiteName?, from scanner: Scanner) throws {
        guard scanner.scanString("NOT", into: nil) else {
            throw ParserError.unexpectedError("Expected not in not null constraint!")
        }
        guard scanner.scanString("NULL", into: nil) else {
            throw ParserError.unexpectedError("Expected null in not null constraint!")
        }
        constraintName = name
        conflictClause = try ConflictClause(from: scanner)

    }
    init(name: String?, conflict: ConflictClause?) {
        self.constraintName = name
        self.conflictClause = conflict
    }

    var sql: String {
        var builder = ""
        if let name = constraintName?.sql {
            builder += "CONSTRAINT \(name) "
        }
        builder += "NOT NULL"
        if let conflictClause = conflictClause {
            builder += " \(conflictClause.sql)"
        }
        return builder
    }

}
