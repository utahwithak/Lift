//
//  QueryResult.swift
//  Lift
//
//  Created by Carl Wieland on 11/13/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class ExecuteQueryResult: NSObject {

    private var query: Query?
    public private(set) var rows = [RowData]()
    public private(set) var error: Error?

    public var duration: TimeInterval?

    @objc dynamic let sql: String

    let columnNames: [String]

    init(statement: Statement) {
        self.columnNames = statement.columnNames
        self.query = Query(statement: statement)
        self.sql = statement.sql

    }

    public func object(at row: Int, column: Int) -> CellData {
        return rows[row][column]
    }

    func load(keepGoing: () -> Bool) {
        guard let query = query else {
            error = LiftError.noQueryError
            return
        }

        defer {
            self.query = nil
        }

        do {
            let start = Date()
            try query.processRows(handler: { rawData in
                self.rows.append(RowData(row: rawData))
            }, keepGoing: keepGoing)
            self.duration = Date().timeIntervalSince(start)

        } catch {
            self.error = error
        }

    }

}
