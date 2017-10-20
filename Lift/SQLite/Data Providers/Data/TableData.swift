//
//  TableData.swift
//  Lift
//
//  Created by Carl Wieland on 10/8/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

protocol TableDataDelegate: class {
    func tableDataDidPageNextIn(_ data: TableData, count: Int)
    func tableDataDidPagePreviousIn(_ data: TableData, count: Int)


}

struct CustomTableStart {
    let query: String
    let args: [SQLiteData]
}

class TableData: NSObject {

    private var lastValue: SQLiteData?
    private var firstValue: SQLiteData?

    private let baseQuery: String

    private let sortColumn: String

    public var pageSize = 1000

    public private(set) var finishedLoadingAfter = false

    public private(set) var finishedLoadingPrevious = false

    private var data = [RowData]()

    private var currentQuery: Query?

    public var delegate: TableDataDelegate?

    private let provider: DataProvider

    private var loadingNextPage = false
    private var loadingPreviousPage = false
    public let allowsPaging: Bool

    public private(set) var columnNames: [String]?

    init(provider: DataProvider) {
        self.provider = provider

        allowsPaging =  provider is Table

        if let table = provider as? Table, table.definition.withoutRowID {
            guard let pkColumn = table.columns.first( where: { $0.primaryKey}) else {
                fatalError("No primary key on without row id table!")
            }
            sortColumn = pkColumn.name.sqliteSafeString()

        } else {
            sortColumn = "rowid"
        }

        let name = provider.qualifiedNameForQuery

        baseQuery = "SELECT *,\(sortColumn) FROM \(name)"

    }

    public var count: Int {
        return data.count
    }

    public func object(at row: Int, column: Int) -> CellData {
        return data[row][column]
    }

    public func rawData(at row: Int, column: Int) -> SQLiteData {
        return data[row].data[column]
    }


    private func buildNextQuery() -> String {

        var builder = baseQuery

        if let lastValue = lastValue {
            builder += " WHERE \(sortColumn) > \(lastValue.forWhereClause)"
        }

        builder += " ORDER BY \(sortColumn) LIMIT \(pageSize)"

        return builder

    }

    private func buildPreviousQuery() -> String {
        var builder = baseQuery

        if let firstVal = firstValue {
            builder += " WHERE \(sortColumn) < \(firstVal.forWhereClause)"
        }

        builder += " ORDER BY \(sortColumn) DESC LIMIT \(pageSize)"

        return builder
    }

    private func buildInitialQuery(customQuery: String?) -> String {
        if let custom = customQuery {
            var builder = baseQuery
            builder += " " + custom
            return builder

        } else {
            return buildNextQuery()
        }
    }



    public func loadInitial(customStart: CustomTableStart? = nil) throws {

        let query = try Query(connection: provider.connection, query: buildInitialQuery(customQuery: customStart?.query))

        if let args = customStart?.args {
            try query.bindArguments(args)
        }

        columnNames = query.statement.columnNames

        data = try query.allRows().map { RowData(row: $0) }

        delegate?.tableDataDidPageNextIn(self, count: data.count)

        lastValue = data.last?.last
        firstValue = data.first?.last

        if customStart == nil {
            finishedLoadingPrevious = true
            if count < pageSize {
                finishedLoadingAfter = true
            }
        }
    }

    public func loadPreviousPage() {
        guard !loadingPreviousPage && !finishedLoadingPrevious else {
            return
        }

        loadingPreviousPage = true
        print("load previous page")
        do {
            let query = try Query(connection: provider.connection, query: buildPreviousQuery())

            query.loadInBackground { [weak self] result in
                self?.handlePreviousResult(result)
            }


        } catch {
            print("Failed to create query:\(error)")
        }
    }

    public func loadNextPage() {

        guard !loadingNextPage && !finishedLoadingAfter else {
            return
        }

        loadingNextPage = true
        print("Load next page")
        do {
            let query = try Query(connection: provider.connection, query: buildNextQuery())

            query.loadInBackground { [weak self] result in
                self?.handleNextResult(result)
            }
        } catch {
            print("Failed to create query:\(error)")
        }
    }

    private func handleNextResult(_ result: Result<[[SQLiteData]], Error>) {

        switch result {
        case .success(let data):
            if data.count < pageSize {
                finishedLoadingAfter = true
            }
            lastValue = data.last?.last

            self.data.append(contentsOf: data.map { RowData(row: $0) })
            delegate?.tableDataDidPageNextIn(self, count: data.count)

        case .failure(let error):
            print("Failed to load next page: \(error)")
        }

        loadingNextPage = false

    }


    private func handlePreviousResult(_ result: Result<[[SQLiteData]], Error>) {

        switch result {
        case .success(let data):
            if data.count < pageSize {
                finishedLoadingPrevious = true
            }
            firstValue = data.last?.last

            self.data.insert(contentsOf: data.reversed().map { RowData(row: $0) }, at: 0)
            delegate?.tableDataDidPagePreviousIn(self, count: data.count)

        case .failure(let error):
            print("Failed to load previous page: \(error)")
        }

        loadingPreviousPage = false

    }


}
