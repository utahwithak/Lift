//
//  ForeignKeyColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class ForeignKeyColumnConstraint: ColumnConstraint {

    var clause: ForeignKeyClause

    init(with name: SQLiteName?, from scanner: Scanner) throws {
        clause = try ForeignKeyClause(from: scanner)
        super.init(name: name)
    }

    override var sql: String {
        var builder = ""
        if let name = constraintName {
            builder += "CONSTRAINT \(name) "
        }

        return builder + clause.sql
    }

    private init(copying: ForeignKeyColumnConstraint) {
        clause = copying.clause
        super.init(name: copying.constraintName)
    }

    override func copy() -> ColumnConstraint {
        return ForeignKeyColumnConstraint(copying: self)
    }
}
