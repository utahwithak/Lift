//
//  TableData.swift
//  Lift
//
//  Created by Carl Wieland on 10/8/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

protocol TableDataDelegate: class {
    func tableDataDidChange(_ data: TableData)


}

class TableData: NSObject {

    private var lastValue: SQLiteData?

    private let baseQuery: String

    private let sortColumn: String

    public var pageSize = 1000

    public private(set) var finishedLoading = false

    private var data = [[SQLiteData]]() {
        didSet {
            delegate?.tableDataDidChange(self)
        }
    }

    private var currentQuery: Query?

    public var delegate: TableDataDelegate?

    private let table: Table

    private var loadingNextPage = false

    public private(set) var columnNames: [String]?

    init(table: Table) {
        self.table = table
        if table.definition.withoutRowID {
            guard let pkColumn = table.columns.first( where: { $0.primaryKey}) else {
                fatalError("No primary key on without row id table!")
            }
            sortColumn = pkColumn.name.sqliteSafeString()

        } else {
            sortColumn = "rowid"
        }

        let name = table.qualifiedNameForQuery

        baseQuery = "SELECT *,\(sortColumn) FROM \(name)"

    }

    public var count: Int {
        return data.count
    }

    public func object(at row: Int, column: Int) -> SQLiteData {
        return data[row][column]
    }


    private func buildQuery(customLimit: Int? = nil) -> String {


        let pageSize = customLimit ?? self.pageSize

        var builder = baseQuery

        if let lastValue = lastValue {
            builder += " WHERE \(sortColumn) > \(lastValue.forWhereClause)"
        }
        builder += " ORDER BY \(sortColumn) LIMIT \(pageSize)"

        return builder

    }


    public func loadInitial() throws {

        let query = try Query(connection: table.connection, query: buildQuery())

        columnNames = query.statement.columnNames

        data = try query.allRows()
        lastValue = data.last?.last

        if count < pageSize {
            finishedLoading = true
        }

    }

    public func loadNextPage(to row: Int? = nil) {

        guard !loadingNextPage && !finishedLoading else {
            return
        }

        loadingNextPage = true

        do {
            let expectedSize: Int
            if let passedIn = row {
                expectedSize = passedIn - count
            } else {
                expectedSize = pageSize
            }
            let query = try Query(connection: table.connection, query: buildQuery(customLimit: expectedSize))

            query.loadInBackground { [weak self] result in
                self?.handleResult(result, expectedSize: expectedSize)
            }


        } catch {
            print("Failed to create query:\(error)")
        }
    }

    private func handleResult(_ result: Result<[[SQLiteData]], Error>, expectedSize: Int) {
        loadingNextPage = false

        switch result {
        case .success(let data):
            if data.count < expectedSize {
                finishedLoading = true
            }
            lastValue = data.last?.last

            self.data.append(contentsOf: data)

        case .failure(let error):
            print("Failed to load next page: \(error)")
        }
    }


}
