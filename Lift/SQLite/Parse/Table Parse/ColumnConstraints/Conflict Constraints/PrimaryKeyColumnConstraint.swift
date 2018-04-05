//
//  PrimaryKeyColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

enum PrimaryKeySortOrder {
    case notSpecified
    case ASC
    case DESC
}

class PrimaryKeyColumnConstraint: ConflictColumnConstraint {

    var autoincrement = false
    var sortOrder: PrimaryKeySortOrder

    override init(with name: SQLiteName?, from scanner: Scanner) throws {
        guard scanner.scanString("primary", into: nil) else {
            throw ParserError.unexpectedError("Expected primary in primary key constraint!")
        }

        guard scanner.scanString("key", into: nil) else {
            throw ParserError.unexpectedError("Expected key in primary key constraint!")
        }

        if scanner.scanString("asc", into: nil) {
            sortOrder = .ASC
        } else if scanner.scanString("desc", into: nil) {
            sortOrder = .DESC
        } else {
            sortOrder = .notSpecified
        }

        try super.init(with: name, from: scanner)

        autoincrement = scanner.scanString("AUTOINCREMENT", into: nil)
    }

    private init(copying: PrimaryKeyColumnConstraint) {
        autoincrement = copying.autoincrement
        sortOrder = copying.sortOrder

        super.init(copying: copying)
    }

    override func copy() -> ColumnConstraint {
        return PrimaryKeyColumnConstraint(copying: self)
    }

    override var sql: String {
        var builder = ""
        if let name = constraintName?.sql {
            builder += "CONSTRAINT \(name) "
        }
        builder += "PRIMARY KEY "
        switch sortOrder {
        case .ASC:
            builder += "ASC "
        case .DESC:
            builder += "DESC "
        case .notSpecified:
            break
        }

        if let conflictClause = conflictClause {
            builder += conflictClause.sql
        }

        if autoincrement {
            builder += "AUTOINCREMENT "
        }

        return builder
    }

}
