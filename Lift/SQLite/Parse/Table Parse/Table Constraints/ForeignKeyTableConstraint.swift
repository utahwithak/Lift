//
//  ForeignKeyTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct ForeignKeyTableConstraint: TableConstraint {

    let fromColumns: [SQLiteName]

    let clause: ForeignKeyClause

    let name: SQLiteName?

    init(name: String?, fromColumns: [String], clause: ForeignKeyClause) {
        self.name = name
        self.fromColumns = fromColumns
        self.clause = clause
    }

    init(with name: SQLiteName?, from scanner: Scanner) throws {
        if !scanner.scanString("foreign", into: nil) || !scanner.scanString("key", into: nil) || !scanner.scanString("(", into: nil) {
            throw ParserError.unexpectedError("Invalid table check")
        }

        var columns = [String]()
        repeat {
            let name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
            guard !name.isEmpty else {
                throw ParserError.unexpectedError("Invalid foreign key ")
            }
            columns.append(name)

        } while (scanner.scanString(",", into: nil))

        self.fromColumns = columns

        guard !fromColumns.isEmpty else {
            throw ParserError.unexpectedError("Empty from columns in fk table constraint parsing!")
        }

        guard scanner.scanString(")", into: nil) else {
            throw ParserError.unexpectedError("Invalid end of foreigh key column definition")
        }

        clause = try ForeignKeyClause(from: scanner)

        self.name = name

    }

    var sql: String {
        var builder = "FOREIGN KEY ("
        builder += fromColumns.map({ $0.sql}).joined(separator: ", ")
        builder += ") " + clause.sql
        return builder
    }

    func sql(with columns: [String]) -> String? {

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

func == (lhs: ForeignKeyTableConstraint, rhs: ForeignKeyTableConstraint) -> Bool {

    if lhs.fromColumns.count != rhs.fromColumns.count {
        return false
    }

    for i in 0..<lhs.fromColumns.count where lhs.fromColumns[i] != rhs.fromColumns[i] {
        return false
    }

    if lhs.name?.cleanedVersion != rhs.name?.cleanedVersion {
        return false
    }

    return lhs.clause == rhs.clause
}
