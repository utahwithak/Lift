//
//  SQLiteIndexParser.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

final class SQLiteIndexParser {
    private init() {}
    struct Index {
        let unique: Bool
        let indexName: String
        let tableName: String
        let columns: [IndexedColumn]
        let whereExpression: String?
    }

    ///https://www.sqlite.org/lang_createindex.html
    static func parse(sql: String) throws -> SQLiteIndexParser.Index {
        let stringScanner = Scanner(string: sql)
        stringScanner.caseSensitive = false

        guard stringScanner.scanString("CREATE ", into: nil) else {
            throw ParserError.notCreateStatement
        }

        let isUniqueIndex = stringScanner.scanString("UNIQUE ", into: nil)

        guard stringScanner.scanString("INDEX ", into: nil) else {
            throw ParserError.notAIndexStatement
        }

        let indexName = try SQLiteCreateTableParser.parseStringOrName(from: stringScanner)

        guard stringScanner.scanString("ON ", into: nil) else {
            throw ParserError.unexpectedError("EXPECTED ON!")
        }

        let tableName = try SQLiteCreateTableParser.parseStringOrName(from: stringScanner)

        guard stringScanner.scanString("(", into: nil) else {
            throw ParserError.unexpectedError("EXPECTED ( to start table parsing!")
        }

        var columns = [IndexedColumn]()
        repeat {
            if let index = try IndexedColumn(from: stringScanner) {
                columns.append(index)
            }
        } while stringScanner.scanString(",", into: nil)

        guard stringScanner.scanString(")", into: nil) else {
            throw ParserError.unexpectedError("Expected end of definitions, not found!:\(String(sql.dropFirst(stringScanner.scanLocation)))")
        }

        var whereExpression: String?
        if stringScanner.scanString("WHERE ", into: nil) {
            whereExpression = try SQLiteCreateTableParser.parseExp(from: stringScanner)
        }

        return SQLiteIndexParser.Index(unique: isUniqueIndex, indexName: indexName, tableName: tableName, columns: columns, whereExpression: whereExpression)
    }

}
