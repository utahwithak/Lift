//
//  CheckTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct CheckTableConstraint: TableConstraint {
    let name: String?

    let checkExpression: String

    init(name: String?, expression: String) {
        self.name = name
        self.checkExpression = expression
    }
    init(with name: SQLiteName?, from scanner: Scanner) throws {

        if !scanner.scanString("check", into: nil) {
            throw ParserError.unexpectedError("Invalid table check")
        }

        checkExpression = try SQLiteCreateTableParser.parseExp(from: scanner)

        self.name = name
    }

    var sql: String {
        var builder = ""
        if let name = name?.sql {
            builder += "CONSTRAINT \(name) "
        }
        return builder + "CHECK \(checkExpression) "
    }

}
