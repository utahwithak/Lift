//
//  Query.swift
//  Lift
//
//  Created by Carl Wieland on 10/5/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation


class Query {

    static func executeQueries(from text: String, on connection:sqlite3, handler: (Result<ExecuteQueryResult, Error>, Double) -> Bool, keepGoing: ()-> Bool  ) {
        let len = Double(text.utf8.count)
        text.withCString {

            var cur: UnsafePointer<Int8>? = $0
            var next = cur

            var bail = false
            repeat {
                var stmt: OpaquePointer?
                cur = next
                var progress: Double = 0
                if let cur = cur {
                    progress = Double($0.distance(to: cur)) / len
                }

                let rc = sqlite3_prepare_v3(connection, cur, -1, 0, &stmt, &next)
                if rc != SQLITE_OK {
                    // on a parse error fail always
                    bail = !handler(.failure(SQLiteError(connection: connection, code: rc)), progress)
                } else if let statement = stmt {

                    let statement = Statement(connection: connection, statement: statement)
                    let result = ExecuteQueryResult(statement: statement)
                    result.load(keepGoing: keepGoing)
                    bail = !handler(.success(result), progress)

                }

            } while !bail && (cur != next)
        }
    }


    let statement: Statement

    var columnCount: Int {
        return statement.columnCount
    }

    init(connection: sqlite3, query: String) throws {
        statement = try Statement(connection: connection, text: query)
    }

    init(statement: Statement) {
        self.statement = statement
    }

    func allRows() throws -> [[SQLiteData]] {
        var results = [[SQLiteData]]()
        var rowData = [SQLiteData](repeating: .null, count: statement.columnCount)

        while try !statement.step() {
            
            statement.fill(&rowData)
            results.append(rowData)
        }
        return results
    }

    func processQuery( handler: () throws -> Void) throws {
        while try !statement.step() {
            try handler()
        }
    }

    func processQuery( handler: () throws -> Void, keepGoing: () -> Bool ) throws {
        while keepGoing(), try !statement.step() {
            try handler()
        }
    }

    func processRows( handler: ([SQLiteData]) throws -> Void) throws {

        var rowData = [SQLiteData](repeating: .null, count: statement.columnCount)

        while try !statement.step() {
            statement.fill(&rowData)
            try handler(rowData)
        }
    }

    func processRows( handler: ([SQLiteData]) throws -> Void, keepGoing: () -> Bool ) throws {

        var rowData = [SQLiteData](repeating: .null, count: statement.columnCount)

        while try !statement.step() {
            statement.fill(&rowData)
            try handler(rowData)
            if !keepGoing() {
                throw LiftError.userCanceled
            }
        }
    }


    func loadInBackground(completion: @escaping (Result<[[SQLiteData]],Error>) -> Void ) {
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let data = try self.allRows()
                DispatchQueue.main.async {
                    completion(.success(data))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }

    }

    func processInBackground(completion: @escaping ([[SQLiteData]],Error?) -> Void , keepGoing: @escaping () -> Bool ) {
        DispatchQueue.global(qos: .userInteractive).async {

            var data = [[SQLiteData]]()
            var rowData = [SQLiteData](repeating: .null, count: self.statement.columnCount)
            do {
                while keepGoing(), try !self.statement.step() {
                    self.statement.fill(&rowData)
                    data.append(rowData)
                }

                DispatchQueue.main.async {
                    completion(data, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(data, error)
                }
            }
        }

    }

    func bindArguments(_ args: [SQLiteData]) throws {
        try statement.bind(args)
    }

    func bindArguments(_ args: ArraySlice<SQLiteData>) throws {
        try statement.bind(args)
    }

    func processData(from query: Query, keepGoing: (()-> Bool)) throws {
        var rowData = [SQLiteData](repeating: .null, count: query.statement.columnCount)

        try query.processQuery(handler: {
            query.statement.fill(&rowData)
            try statement.bind(rowData)
            _ = try statement.step()

            statement.reset()
        }, keepGoing: keepGoing)
    }

    func processData(from query: Query) throws {
        var rowData = [SQLiteData](repeating: .null, count: query.statement.columnCount)

        try query.processQuery(handler: {
            query.statement.fill(&rowData)
            try statement.bind(rowData)
            _ = try statement.step()

            statement.reset()
        })
    }

    func argumentName(for index: Int) -> String {
        return statement.argumentName(for: index)
    }

    func argumentName(for column: String) -> String {
        return statement.argumentName(for: column)
    }

    var columnsAsArguments: [String] {
        return statement.columnsAsArguments
    }

    var numericArguments: [String] {
        return statement.numericArguments
    }

}
