//
//  IndexedTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

protocol IndexedTableConstraint: TableConstraint {

    var indexedColumns: [IndexedColumn] { get set }

    var conflictClause: ConflictClause? { get set }
}

extension IndexedTableConstraint {
    public static func parseIndexColumns(from scanner: Scanner) throws -> [IndexedColumn] {
        var columns = [IndexedColumn]()
        guard let first = try IndexedColumn(from: scanner) else {
            throw ParserError.unexpectedError("No indexColumn found!")
        }

        columns.append(first)
        var hasMore = scanner.scanString(",", into: nil)
        while hasMore {
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
