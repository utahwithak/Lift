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

    private let baseQuery: String


    public var pageSize = 1000

    public private(set) var finishedLoadingAfter = false

    public private(set) var finishedLoadingPrevious = false

    private var data = [RowData]()

    private var currentQuery: Query?

    public var delegate: TableDataDelegate?

    private let provider: DataProvider

    private var loadingNextPage = false
    private var loadingPreviousPage = false


    // used for smart paging
    //
    public let smartPaging: Bool
    private var sortColumns: String
    public let sortCount: Int
    private let argString: String
    private var lastValues: ArraySlice<SQLiteData>?
    private var firstValues: ArraySlice<SQLiteData>?


    public private(set) var columnNames: [String]?

    init(provider: DataProvider) {
        self.provider = provider

        let name = provider.qualifiedNameForQuery

        if let table = provider as? Table {
            smartPaging =  provider is Table
            if table.definition.withoutRowID {
                let primaryKeys =  table.columns.filter { $0.primaryKey }
                sortCount = primaryKeys.count
                sortColumns = primaryKeys.map { $0.name.sqliteSafeString() }.joined(separator: ", ")
                argString = (0..<sortColumns.count).map { "$\($0)"}.joined(separator: ", ")

            } else {
                sortColumns = "rowid"
                argString = "$0"
                sortCount = 1
            }


            baseQuery = "SELECT \(sortColumns),* FROM \(name)"

        } else {
            sortCount = 0
            argString = ""
            sortColumns = ""
            smartPaging = false
            baseQuery = "SELECT * FROM \(name)"

        }

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

        if smartPaging {
            var builder = baseQuery

            if lastValues != nil {
                builder += " WHERE (\(sortColumns)) > (\(argString))"
            }

            builder += " ORDER BY \(sortColumns) LIMIT \(pageSize)"

            return builder
        } else {
            return baseQuery + " LIMIT \(pageSize) OFFSET \(data.count)"
        }

    }

    private func buildPreviousQuery() -> String {
        if !smartPaging {
            print("should not be able to go backwards!")
        }

        var builder = baseQuery

        if firstValues != nil {
            builder += " WHERE \(sortColumns) < \(argString)"
        }

        builder += " ORDER BY \(sortColumns) DESC LIMIT \(pageSize)"

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

        if smartPaging {
            lastValues = data.last?.last(sortCount) ?? []
            firstValues = data.first?.last(sortCount) ?? []
        }

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

            if let args = firstValues {
                try query.bindArguments(args)
            }

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
            if let args = lastValues {
                try query.bindArguments(args)
            }
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

            if smartPaging, let last = data.last {
                lastValues = last.dropFirst(last.count - sortCount)
            }


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
            if smartPaging, let last = data.last {
                firstValues = last.dropFirst(last.count - sortCount)
            }

            self.data.insert(contentsOf: data.reversed().map { RowData(row: $0) }, at: 0)
            delegate?.tableDataDidPagePreviousIn(self, count: data.count)

        case .failure(let error):
            print("Failed to load previous page: \(error)")
        }

        loadingPreviousPage = false

    }


}
