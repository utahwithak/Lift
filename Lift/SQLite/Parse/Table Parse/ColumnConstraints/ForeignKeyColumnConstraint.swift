//
//  ForeignKeyColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct ForeignKeyColumnConstraint: ColumnConstraint {
    let constraintName: String?
    let clause: ForeignKeyClause

    init(name: String?, clause: ForeignKeyClause) {
        self.constraintName = name
        self.clause = clause
    }

    init(with name: SQLiteName?, from scanner: Scanner) throws {
        clause = try ForeignKeyClause(from: scanner)
        constraintName = name
    }

    var sql: String {
        var builder = ""
        if let name = constraintName {
            builder += "CONSTRAINT \(name) "
        }

        return builder + clause.sql
    }

}
