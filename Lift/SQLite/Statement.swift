//
//  Query.swift
//  Lift
//
//  Created by Carl Wieland on 10/5/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

let SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class Statement {
    let statement: OpaquePointer!

    let sql: String

    let columnCount: Int

    let columnNames: [String]

    let connection : sqlite3

    var bindIndex: Int32 = 1

    let parameterCount: Int

    init(connection: sqlite3, text: String) throws {

        self.connection = connection

        var stmt: OpaquePointer?

        let rc = sqlite3_prepare_v3(connection, text, -1, 0, &stmt, nil)

        guard rc == SQLITE_OK else {
            throw SQLiteError(connection: connection, code: rc, sql: text)
        }

        statement = stmt

        sql = String(cString: sqlite3_sql(statement))

        columnCount = Int(sqlite3_column_count( statement ))

        columnNames = (0..<columnCount).map { String(cString: sqlite3_column_name(stmt, Int32($0))) }
        parameterCount = Int(sqlite3_bind_parameter_count(statement))
    }

    init(connection: sqlite3, statement: OpaquePointer) {

        self.connection = connection
        self.statement = statement

        if let val = sqlite3_sql(statement) {
            sql = String(cString: val)
        } else {
            print("Unable to get actual SQL!")
            sql = ""
        }

        columnCount = Int(sqlite3_column_count( statement ))
        columnNames = (0..<columnCount).map { String(cString: sqlite3_column_name(statement, Int32($0))) }
        parameterCount = Int(sqlite3_bind_parameter_count(statement))

    }

    deinit {
        finalize()
    }

    private func finalize() {
        reset()
        if sqlite3_finalize(statement) != SQLITE_OK {
            let str = String(cString:sqlite3_errmsg(connection))
            print("ERROR ON FINALIZE:\(str)")
        }
    }

    func reset() {

        sqlite3_clear_bindings(statement)
        sqlite3_reset(statement)

        bindIndex = 1
    }


    /// step through the statement. Calling `sqlite3_step` with this statement.
    ///
    /// - Returns: Whether the statement has finished. `true` meaning it is done, `false` there is more data.
    /// - Throws: If the return code is not OK, DONE or ROW it will throw the return code
    func step() throws -> Bool {

        let rc = sqlite3_step(statement)

        switch  rc {
        case SQLITE_OK, SQLITE_DONE:
            return true
        case SQLITE_ROW:
            return false
        default:
            
            throw SQLiteError(connection: connection, code: rc, sql:"Step Error")
        }

    }

    func index(of field: String) -> Int? {
        return columnNames.index(of: field)
    }

    private func object(at index: Int) -> SQLiteData {

        switch sqlite3_column_type( statement, Int32(index) ) {
        case SQLITE_INTEGER:
            return .integer(integer(at: index))
        case SQLITE_FLOAT:
            return .float(double(at: index))
        case SQLITE_BLOB:
            return .blob(blob(at: index))
        case SQLITE_TEXT:
            return .text(string(at: index))
        default:
            /*case SQLITE_NULL*/
            return .null
        }
    }

    private func object(for key: String) -> SQLiteData {
        guard let index = self.index(of: key) else {
            fatalError("Asking for row thats not there!")
        }

        return object(at: index)
    }

    func string(at index: Int) -> String {
        guard let val = sqlite3_column_text(statement, Int32(index)) else {
            return ""
        }
        return String(cString: val)
    }

    func integer(at index: Int) -> Int {
        return Int(sqlite3_column_int64( statement, Int32(index)))
    }

    func double(at index: Int) -> Double {
        return sqlite3_column_double( statement, Int32(index) );
    }

    func blob(at index: Int) -> Data {
        guard let ptr = sqlite3_column_blob(statement, Int32(index)) else {
            return Data()
        }
        let size = sqlite3_column_bytes(statement, Int32(index))
        return Data(bytes: ptr, count: Int(size))
    }


    func argumentName(for index: Int) -> String {
        let name = columnNames[index].replacingOccurrences(of: " ", with: "")
        return "$\(name)\(index)"
    }

    func argumentName(for column: String) -> String {
        guard let index = index(of: column) else {
            fatalError("Asking for arugmentname where column isn't there")
        }
        return argumentName(for: index)
    }

    var columnsAsArguments: [String] {
        return (0..<columnCount).map({ argumentName(for: $0) })
    }

    var numericArguments: [String] {
        return (0..<columnCount).map({"?\($0 + 1)"})
    }

    func fill(_ dict: inout [String: SQLiteData]) {
        for key in dict.keys {
            dict[key] = object(for: key)
        }
    }

    func fill(_ array: inout [SQLiteData]) {
        for i in 0..<columnCount {
            array[i] = object(at: i)
        }
    }

    private func bindIndex(for i: Int? = nil) -> Int32 {
        let index: Int32
        if let i = i {
            index = Int32(i)
        } else {
            index = bindIndex
            bindIndex += 1

        }

        assert(parameterCount >= index, "Bind index out of bounds!")

        return index
    }


    private func checkedOperation(on connection: sqlite3? = nil, operation: () -> Int32) throws {
        let rc = operation()
        guard rc == SQLITE_OK else {
            throw SQLiteError(connection: connection, code: rc)
        }

    }

    func bind(text: String, at i: Int? = nil) throws {
        try checkedOperation(on: connection) {
            sqlite3_bind_text( statement, bindIndex(for: i), text, -1, SQLITE_TRANSIENT )

        }
    }

    func bind(float: Double, at i: Int? = nil) throws {
        try checkedOperation(on: connection) {
            sqlite3_bind_double( statement, bindIndex(for: i), float )

        }
    }

    func bind(integer: Int, at i: Int? = nil) throws {
        try checkedOperation(on: connection) {
            sqlite3_bind_int64( statement, bindIndex(for: i), sqlite_int64(integer))

        }
    }

    func bind(blob: Data, at i: Int? = nil) throws {
        try blob.withUnsafeBytes { ptr in
            try checkedOperation(on: connection) {
                sqlite3_bind_blob( statement, bindIndex(for: i), ptr, Int32(blob.count), SQLITE_TRANSIENT)

            }
        }
    }

    func bindNull(at i: Int? = nil) throws {
        try checkedOperation(on: connection) { sqlite3_bind_null( statement, bindIndex(for: i)) }
    }

    func bind(data: SQLiteData, at i: Int? = nil) throws {
        switch data {
        case .blob(let data):
            try bind(blob: data, at: i)
        case .text(let text):
            try bind(text: text, at: i)
        case .integer(let int):
            try bind(integer: int, at: i)
        case .float(let flt):
            try bind(float: flt, at: i)
        case .null:
            try bindNull(at: i)
        }
    }

    func bind(data: SQLiteData, for key: String) throws {
        let index = Int(sqlite3_bind_parameter_index(statement, key))
        guard index > 0 else {
            throw NSError(domain: "SQLITE QUERY", code: -1, userInfo:[NSLocalizedDescriptionKey: NSLocalizedString("Attempting to bind an argument thats not there!", comment: " Error when attempting to bind an argument thats not there")])
        }
        try bind(data: data, at: index)
    }

    func bind(_ values: [SQLiteData]) throws {
        for value in values {
            try bind(data: value)
        }
    }
    func bind(_ values: ArraySlice<SQLiteData>) throws {
        for value in values {
            try bind(data: value)
        }
    }

    func bind(_ values: [String: SQLiteData], areColumns: Bool = false) throws {
        for (key, value) in values {
            let name = areColumns ? argumentName(for: key) : key
            try bind(data: value, for: name)
        }

    }

    func processData(from query: Query) throws {
        var rowData = [SQLiteData](repeating: .null, count: query.statement.columnCount)

        try query.processQuery {
            query.statement.fill(&rowData)
            try bind(rowData)
            _ = try step()

            reset()
        }
    }


}
