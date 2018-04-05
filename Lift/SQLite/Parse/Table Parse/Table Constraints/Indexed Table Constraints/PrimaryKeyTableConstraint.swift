//
//  PrimaryKeyTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class PrimaryKeyTableConstraint: IndexedTableConstraint {

    override init(with name: SQLiteName?, from scanner: Scanner) throws {
        if !scanner.scanString("primary", into: nil) || !scanner.scanString("key", into: nil) || !scanner.scanString("(", into: nil) {
            throw ParserError.unexpectedError("Invalid table primary key")
        }

        try super.init(with: name, from: scanner)
    }

    override init(initialColumn name: ColumnNameProvider) {
        super.init(initialColumn: name)

    }

    override var sql: String {
        var builder = ""
        if let name = name?.sql {
            builder += "CONSTRAINT \(name) "
        }
        builder += "PRIMARY KEY ("
        builder += indexedColumns.map({ $0.sql}).joined(separator: ", ")
        builder += ") "
        if let conflict = conflictClause {
            builder += conflict.sql
        }
        return builder
    }

    override func sql(with columns: [String]) -> String? {

        let cleanedIndexed = indexedColumns.filter { (index) -> Bool in
            return columns.contains(index.nameProvider.columnName.cleanedVersion)
        }

        if cleanedIndexed.isEmpty {
            return nil
        }

        var builder = ""
        if let name = name?.sql {
            builder += "CONSTRAINT \(name) "
        }
        builder += "PRIMARY KEY ("
        builder += cleanedIndexed.map({$0.sql}).joined(separator: ", ")
        builder += ")"
        if let conflict = conflictClause?.sql, !conflict.isEmpty {
            builder += " " + conflict
        }
        return builder

    }
}
