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

    init(with name: SQLiteName?, from scanner: Scanner) throws {
        if !scanner.scanString("foreign", into: nil) || !scanner.scanString("key", into: nil) || !scanner.scanString("(", into: nil) {
            throw ParserError.unexpectedError("Invalid table check")
        }

        repeat {
            let name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
            guard !name.isEmpty else {
                throw ParserError.unexpectedError("Invalid foreign key ")
            }
            fromColumns.append(name)

        } while (scanner.scanString(",", into: nil))

        guard !fromColumns.isEmpty else {
            throw ParserError.unexpectedError("Empty from columns in fk table constraint parsing!")
        }

        guard scanner.scanString(")", into: nil) else {
            throw ParserError.unexpectedError("Invalid end of foreigh key column definition")
        }

        clause = try ForeignKeyClause(from: scanner)

        super.init(name: name)

    }

    init(name: SQLiteName?, columns: [String], clause: ForeignKeyClause) {
        fromColumns = columns.map({ SQLiteName(rawValue: $0)})
        self.clause = clause
        super.init(name: name)
    }

    override var sql: String {
        var builder = "FOREIGN KEY ("
        builder += fromColumns.map({ $0.sql}).joined(separator: ", ")
        builder += ") " + clause.sql
        return builder
    }

    override func sql(with columns: [String]) -> String? {

        var clauseCopy = clause

        var cleanedFrom = [SQLiteName]()

        for i in (0..<fromColumns.count).reversed() {
            if !columns.contains(fromColumns[i].cleanedVersion) {
                clauseCopy.toColumns.remove(at: i)
            } else {
                cleanedFrom.insert(fromColumns[i], at: 0)
            }
        }
        if fromColumns.isEmpty {
            return nil
        }

        var builder = ""
        if let name = name?.sql {
            builder += "CONSTRAINT \(name) "
        }
        builder += "FOREIGN KEY ("

        builder += cleanedFrom.map({ $0.sql}).joined(separator: ", ")
        builder += ") " + clauseCopy.sql
        return builder

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

    if lhs.name?.cleanedVersion != rhs.name?.cleanedVersion {
        return false
    }

    return lhs.clause == rhs.clause
}
