//
//  CheckColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct CheckColumnConstraint: ColumnConstraint {
    let constraintName: SQLiteName?
    let checkExpression: String

    init(with name: SQLiteName?, from scanner: Scanner) throws {

        if !scanner.scanString("check", into: nil) {
            throw ParserError.unexpectedError("Invalid table check")
        }

        checkExpression = try SQLiteCreateTableParser.parseExp(from: scanner)
        self.constraintName = name
    }

    var sql: String {
        var builder = ""
        if let name = constraintName {
            builder += "CONSTRAINT \(name) "
        }
        return builder + "CHECK \(checkExpression)"
    }
}
