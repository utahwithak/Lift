//
//  IndexedTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class IndexedTableConstraint: TableConstraint {

    var indexedColumns: [IndexedColumn]

    var conflictClause: ConflictClause?

    init(with name: SQLiteName?, from scanner: Scanner) throws {
        indexedColumns = try IndexedTableConstraint.parseIndexColumns(from: scanner)

        guard scanner.scanString(")", into: nil) else {
            throw ParserError.unexpectedError("Failed to correctly parse index columns for an indexed table constraint!")
        }

        conflictClause = try ConflictClause(from: scanner)

        super.init(name: name)


    }
    private static func parseIndexColumns(from scanner: Scanner) throws -> [IndexedColumn] {
        var columns = [IndexedColumn]()
        guard let first = try IndexedColumn(from: scanner) else {
            throw ParserError.unexpectedError("No indexColumn found!")
        }

        columns.append(first)
        var hasMore = scanner.scanString(",", into: nil)
        while hasMore  {
            do {
                if let nextColumn = try IndexedColumn(from: scanner) {
                    columns.append(nextColumn)
                    hasMore = scanner.scanString(",", into: nil)
                } else {
                    hasMore = false
                }
            } catch {
                hasMore = false
            }
        }

        return columns
    }

}
