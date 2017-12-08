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

    @objc dynamic let sql: String

    let columnNames: [String]

    init(statement: Statement) {
        self.columnNames = statement.columnNames
        self.query = Query(statement: statement)
        self.sql = statement.sql

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
            try query.processRows(handler: { rawData in
                self.rows.append(RowData(row: rawData))
            }, keepGoing: keepGoing)

        } catch {
            self.error = error
        }

    }

}
