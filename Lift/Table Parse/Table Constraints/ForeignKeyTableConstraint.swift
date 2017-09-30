//
//  ForeignKeyTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class ForeignKeyTableConstraint: TableConstraint {

    var fromColumns = [SQLiteName]()

    var clause: ForeignKeyClause

    init(from scanner: Scanner, named name: String) throws {
        if !scanner.scanString("foreign", into: nil) || !scanner.scanString("key", into: nil) || !scanner.scanString("(", into: nil) {
            throw ParserError.unexpectedError("Invalid table check")
        }

        repeat {
            let name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
            guard !name.isEmpty else {
                throw ParserError.unexpectedError("Invalid foreign key ")
            }
            fromColumns.append(SQLiteName(rawValue: name))

        } while (scanner.scanString(",", into: nil))

        guard !fromColumns.isEmpty else {
            throw ParserError.unexpectedError("Empty from columns in fk table constraint parsing!")
        }

        guard scanner.scanString(")", into: nil) else {
            throw ParserError.unexpectedError("Invalid end of foreigh key column definition")
        }

        clause = try ForeignKeyClause(from: scanner)

        super.init(named: name)

    }


    init(name: String, columns: [String], clause: ForeignKeyClause) {
        fromColumns = columns.map({ SQLiteName(rawValue: $0)})
        self.clause = clause
        super.init(named: name)
    }

}

func ==(lhs: ForeignKeyTableConstraint, rhs: ForeignKeyTableConstraint) -> Bool {

    if lhs.fromColumns.count != rhs.fromColumns.count {
        return false
    }

    for i in 0..<lhs.fromColumns.count {
        if lhs.fromColumns[i] != rhs.fromColumns[i] {
            return false
        }
    }

    if lhs.name != rhs.name {
        return false
    }


    return lhs.clause == rhs.clause
}





