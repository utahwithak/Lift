//
//  UniqueTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class UniqueTableConstraint: IndexedTableConstraint {
    override init(with name: SQLiteName?,from scanner: Scanner) throws {
        if !scanner.scanString("unique", into: nil) || !scanner.scanString("(", into: nil) {
            throw ParserError.unexpectedError("Invalid table Unique key")
        }
        try super.init(with: name, from: scanner)
    }


    override var sql: String {
        var builder = ""
        if let name = name?.sql {
            builder += "CONSTRAINT \(name) "
        }
        builder += "UNIQUE ("
        builder += indexedColumns.map({ $0.sql}).joined(separator: ", ")
        builder += ") "
        if let conflict = conflictClause {
            builder += conflict.sql
        }
        return builder
    }

    override func sql(with columns: [String]) -> String? {


        let cleanedIndexed = indexedColumns.filter { (index) -> Bool in
            return columns.contains(index.columnName.cleanedVersion)
        }

        if cleanedIndexed.isEmpty {
            return nil
        }

        var builder = ""
        if let name = name?.sql {
            builder += "CONSTRAINT \(name) "
        }
        builder += "UNIQUE ("
        builder += cleanedIndexed.map({ $0.sql}).joined(separator: ", ")
        builder += ") "
        if let conflict = conflictClause {
            builder += conflict.sql
        }
        return builder

    }
}
