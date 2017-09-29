//
//  IndexedColumn.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

enum IndexColumnSortOrder {
    case notSpecified
    case ASC
    case DESC
}

class IndexedColumn {
    var columnName: ColumnName
    var collationName: String
    var sortOrder: IndexColumnSortOrder


    init?(from scanner: Scanner) throws {

        let name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        if name.isEmpty {
            return nil
        }
        columnName = ColumnName(rawValue: name)
        if scanner.scanString("COLLATE", into: nil) {
            collationName = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        } else {
            collationName = ""
        }

        if scanner.scanString("ASC", into: nil) {
            sortOrder = .ASC
        } else if scanner.scanString("DESC", into: nil) {
            sortOrder = .DESC
        } else {
            sortOrder = .notSpecified
        }
    }
}
