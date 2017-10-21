//
//  Query.swift
//  Lift
//
//  Created by Carl Wieland on 10/5/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation


class Query {

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

    func processRows( handler: ([SQLiteData]) throws -> Void) throws {

        var rowData = [SQLiteData](repeating: .null, count: statement.columnCount)

        while try !statement.step() {
            statement.fill(&rowData)
            try handler(rowData)
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

    func bindArguments(_ args: [SQLiteData]) throws {
        try statement.bind(args)
    }

    func bindArguments(_ args: ArraySlice<SQLiteData>) throws {
        try statement.bind(args)
    }

}
