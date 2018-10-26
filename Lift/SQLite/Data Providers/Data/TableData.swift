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
    func tableData(_ data: TableData, didRemoveRows indexSet: IndexSet)
}

struct CustomTableStart {
    let query: String
    let args: [SQLiteData]
}

enum SimpleUpdateType {
    case null
    case current_time
    case current_date
    case current_timestamp
    case defaultValue
    case argument(String)
    case rawData(SQLiteData)

    static let allVals: [SimpleUpdateType] = [.null, .current_time, .current_date, .current_timestamp, .defaultValue]

    var title: String {
        switch  self {
        case .null:
            return NSLocalizedString("NULL", comment: "set to null")
        case .current_time:
            return NSLocalizedString("Current Time", comment: "set to current time")
        case .current_date:
            return NSLocalizedString("Current Date", comment: "set to current date")
        case .current_timestamp:
            return NSLocalizedString("Current Timestamp", comment: "set to current timestamp")
        case .defaultValue:
            return NSLocalizedString("Default Value", comment: "set to default value")
        case .argument:
            return NSLocalizedString("Custom Value", comment: "set to a Custom value")
        case .rawData:
            return ""
        }
    }
}

struct ColumnSort {
    let column: String
    var asc: Bool

    func queryStatement(flipped: Bool) -> String {
        let order = flipped ? !asc : asc

        return column.querySafeString() + (order ? " ASC" : " DESC")
    }
}

final class TableData: NSObject {

    private let baseQuery: String

    public var pageSize = 10000

    public private(set) var finishedLoadingAfter = false

    public private(set) var finishedLoadingPrevious = false

    private var data = [RowData]()

    private var currentQuery: Query?

    public weak var delegate: TableDataDelegate?

    private let provider: DataProvider

    private var loadingNextPage = false
    private var loadingPreviousPage = false

    let customOrdering: [ColumnSort]

    // used for smart paging
    //
    public let smartPaging: Bool
    private var sortColumns: String
    public let sortCount: Int
    private let argString: String
    private var lastValues: ArraySlice<SQLiteData>?
    private var firstValues: ArraySlice<SQLiteData>?

    public private(set) var columnNames: [String]?

    init(provider: DataProvider, customQuery: String? = nil, customSorting: [ColumnSort] = []) {
        self.provider = provider

        self.customOrdering = customSorting

        let name = provider.qualifiedNameForQuery

        if customSorting.isEmpty && customQuery == nil, let table = provider as? Table {
            smartPaging =  provider is Table
            if table.definition?.withoutRowID ?? false {
                let primaryKeys =  table.columns.filter { $0.isPrimaryKey }
                sortCount = primaryKeys.count
                sortColumns = primaryKeys.map { $0.name.sqliteSafeString() }.joined(separator: ", ")
                argString = (0..<primaryKeys.count).map { "$\($0)"}.joined(separator: ", ")

            } else {
                sortColumns = "rowid"
                argString = "$0"
                sortCount = 1
            }
            baseQuery = "SELECT \(sortColumns),* FROM \(name)"
        } else {
            if let table = provider as? Table, table.definition?.withoutRowID ?? false {
                let primaryKeys =  table.columns.filter { $0.isPrimaryKey }
                sortCount = primaryKeys.count
                sortColumns = primaryKeys.map { $0.name.sqliteSafeString() }.joined(separator: ", ")
                argString = (0..<primaryKeys.count).map { "$\($0)"}.joined(separator: ", ")
                smartPaging = false
                if let query = customQuery {
                    baseQuery = "SELECT \(sortColumns),* FROM \(name) WHERE \(query)"
                } else {
                    baseQuery = "SELECT \(sortColumns),* FROM \(name)"
                }
            } else {
                sortColumns = "rowid"
                argString = "$0"
                sortCount = 1
                smartPaging = false
                if let query = customQuery {
                    baseQuery = "SELECT \(sortColumns),* FROM \(name) WHERE \(query)"
                } else {
                    baseQuery = "SELECT \(sortColumns),* FROM \(name)"
                }
            }

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

    func customSortOrdering(forNext: Bool) -> String {
        return customOrdering.map({ $0.queryStatement(flipped: !forNext) }).joined(separator: ", ")
    }

    private func buildNextQuery() -> String {

        if smartPaging {
            var builder = baseQuery

            if let lastValues = lastValues, !lastValues.isEmpty {
                builder += " WHERE (\(sortColumns)) > (\(argString))"
            }

            builder += " LIMIT \(pageSize)"

            return builder
        } else {
            var builder = baseQuery

            let customOrder = customSortOrdering(forNext: true)
            if !customOrder.isEmpty {
                builder += " ORDER BY \(customOrder)"
            }

            return builder + " LIMIT \(pageSize) OFFSET \(data.count)"
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
        finishedLoadingPrevious = false
        finishedLoadingAfter = false
        lastValues = nil
        firstValues = nil

        let query = try Query(connection: provider.connection, query: buildInitialQuery(customQuery: customStart?.query))

        if let args = customStart?.args {
            try query.bindArguments(args)
        }

        columnNames = query.statement.columnNames

        data = try query.allRows().map { RowData(row: $0) }

        delegate?.tableDataDidPageNextIn(self, count: data.count)

        if smartPaging {
            lastValues = data.last?.first(sortCount) ?? []
            firstValues = data.first?.first(sortCount) ?? []
        }

        if customStart == nil {
            finishedLoadingPrevious = true
            if count < pageSize {
                finishedLoadingAfter = true
            }
        }

    }

    public func loadToRowVisible(_ row: Int, completion: @escaping () -> Void, keepGoing: @escaping() -> Bool ) -> Bool {
        guard !loadingNextPage && !finishedLoadingAfter else {
            return false
        }

        if row < data.count {
            return false
        }

        var queryString = baseQuery
        let loadSize = row - data.count
        if smartPaging {

            if lastValues != nil {
                queryString += " WHERE (\(sortColumns)) > (\(argString))"
            }

            queryString += " ORDER BY \(sortColumns) LIMIT \(loadSize)"

        } else {
            queryString  += " LIMIT \(loadSize) OFFSET \(data.count)"
        }

        loadingNextPage = true
        do {
            let query = try Query(connection: provider.connection, query: queryString)

            if let args = lastValues {
                try query.bindArguments(args)
            }
            query.processInBackground(completion: { (rowData, _) in

                if rowData.count < loadSize && keepGoing() {
                    self.finishedLoadingAfter = true
                }

                if self.smartPaging, let last = rowData.last {
                    self.lastValues = last[0..<self.sortCount]
                }

                self.data.append(contentsOf: rowData.map { RowData(row: $0) })
                completion()

                self.loadingNextPage = false

            }, keepGoing: keepGoing)

        } catch {
            print("Failed to create query:\(error)")
            return false
        }

        return true

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
            if let args = lastValues, !args.isEmpty {
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
                lastValues = last[0..<sortCount]
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
                firstValues = last[0..<sortCount]
            }

            self.data.insert(contentsOf: data.reversed().map { RowData(row: $0) }, at: 0)
            delegate?.tableDataDidPagePreviousIn(self, count: data.count)

        case .failure(let error):
            print("Failed to load previous page: \(error)")
        }

        loadingPreviousPage = false

    }

    enum UpdateResult {
        case updated
        case removed
        case failed
    }

    func rowdata(at row: Int) -> RowData {
        return data[row]
    }

    func dropSelection(_ selectionBox: SelectionBox, keepGoing: () -> Bool) throws {

        let queryTemplate = "DELETE FROM \(provider.qualifiedNameForQuery) WHERE (\(sortColumns)) = (\(argString))"
        let deleteStatement = try Statement(connection: provider.connection, text: queryTemplate)
        for row in selectionBox.startRow...selectionBox.endRow {

            try deleteStatement.bind(rowdata(at: row).data[0..<sortCount])
            guard try deleteStatement.step() else {
                print("INVALID DROP!")
                return
            }

            if !keepGoing() {
                return
            }
            deleteStatement.reset()
        }
        if keepGoing() {
            DispatchQueue.main.async {
                self.data.removeSubrange(selectionBox.startRow...selectionBox.endRow)
                self.delegate?.tableData(self, didRemoveRows: IndexSet(selectionBox.startRow...selectionBox.endRow))
            }
        }
    }

    func set(row: Int, column: Int, to value: SimpleUpdateType) throws -> UpdateResult {
        guard let columnName = columnNames?[column] else {
            return .failed
        }

        var args = [String: SQLiteData]()

        var query = "UPDATE \(provider.qualifiedNameForQuery) SET \(columnName.sqliteSafeString())="
        switch value {
        case .null:
            query += "NULL"
        case .current_date:
            query += "CURRENT_DATE"
        case .current_time:
            query += "CURRENT_TIME"
        case .current_timestamp:
            query += "CURRENT_TIMESTAMP"
        case .defaultValue:
            query += provider.columns[column - sortCount].defaultValue ?? "NULL"
        case .argument(let argVal):
            query += "$arg"
            args["$arg"] = .text(argVal)
        case .rawData(let data):
            query += "$arg"
            args["$arg"] = data
        }

        let rowData = data[row]
        query += " WHERE (\(sortColumns)) = (\(argString))"

        let updateStatement = try Statement(connection: provider.connection, text: query)

        for i in 0..<sortCount {
            args["$\(i)"] = rowData.data[i]
        }
        try updateStatement.bind(args)

        guard try updateStatement.step() else {
            return .failed
        }

        let rowQuery = baseQuery + " WHERE (\(sortColumns)) = (\(argString))"

        let selectQuery = try Query(connection: provider.connection, query: rowQuery)
        try selectQuery.bindArguments(rowData.data[0..<sortCount])

        let allRows = try selectQuery.allRows()

        if allRows.count == 1 {
            data[row] = RowData(row: allRows[0])
            return .updated
        } else if allRows.count == 0 {
            data.remove(at: row)
            return .removed
        } else {
            print("Got more than 1 rows back!?")
            return .failed
        }
    }

    func json(inSelection sel: SelectionBox, map: [Int: Int], keepGoingCheck: (() -> Bool)? = nil) -> String? {

        guard let names = columnNames else {
            return nil
        }

        var holder = [Any]()
        for row in sel.startColumn...sel.endRow {
            var curRow = [String: Any]()
            for rawCol in sel.startColumn...sel.endColumn {
                let col = map[rawCol]!
                switch data[row].data[col] {
                case .text(let text):
                    curRow[names[col]] = text
                case .integer(let intVal):
                    curRow[names[col]] = intVal
                case .float(let dVal):
                    curRow[names[col]] = dVal
                case .null:
                    break
                case .blob(let data):
                   curRow[names[col]] = data.hexEncodedString()
                }

                if let check = keepGoingCheck, !check() {
                    return nil
                }

            }
            holder.append(curRow)
        }

        let objForJSON: Any
        if holder.count == 1 {
            objForJSON = holder[0]
        } else {
            objForJSON = holder
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: objForJSON, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Failed to conver to JSON")
            return nil
        }

    }

    func csv(inSelection sel: SelectionBox, map: [Int: Int], keepGoingCheck: (() -> Bool)? = nil ) -> String? {

        var writer = ""
        let separator = ","
        let lineEnding = "\n"

        for row in sel.startRow...sel.endRow {
            for rawCol in sel.startColumn...sel.endColumn {
                let col = map[rawCol]!

                let rawData = data[row].data[col]
                switch rawData {
                case .text(let text):
                    writer.append(text.CSVFormattedString(qouted: false, separator: separator))
                case .integer(let intVal):
                    writer.append(intVal.description)
                case .float(let dVal):
                    writer.append(dVal.description)
                case .null:
                    break
                case .blob(let data):
                    writer.write("<\(data.hexEncodedString())>")
                }
                if rawCol < sel.endColumn {
                    writer.write(separator)
                }

                if let check = keepGoingCheck, !check() {
                    return nil
                }
            }
            if row < sel.endRow {
                writer.write(lineEnding)
            }

        }
        return writer
    }

    func addDefaultValues() throws -> Bool {
        guard let table = provider as? Table, table.isEditable else {
            return false
        }

        let success = try table.addDefaultValues()

        if success && finishedLoadingAfter {
            finishedLoadingAfter = false
            loadNextPage()
        }

        return success
    }

}
