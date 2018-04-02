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
    var nameProvider: ColumnNameProvider
    var collationName: SQLiteName?
    var sortOrder: IndexColumnSortOrder

    init(provider: ColumnNameProvider) {
        nameProvider = provider
        sortOrder = .notSpecified
    }

    init?(from scanner: Scanner) throws {

        let columnName = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        if columnName.isEmpty {
            return nil
        }

        nameProvider = columnName

        if scanner.scanString("COLLATE", into: nil) {
            collationName = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        } else {
            collationName = nil
        }

        if scanner.scanString("ASC", into: nil) {
            sortOrder = .ASC
        } else if scanner.scanString("DESC", into: nil) {
            sortOrder = .DESC
        } else {
            sortOrder = .notSpecified
        }
    }

    var sql: String {
        var builder = "\(nameProvider.columnName.sql)"
        if let name = collationName {
            builder += " COLLATE \(name.sql)"
        }

        switch sortOrder {
        case .ASC:
            builder += " ASC"
        case .DESC:
            builder += " DESC"
        case .notSpecified:
            break
        }

        return builder



    }
}
