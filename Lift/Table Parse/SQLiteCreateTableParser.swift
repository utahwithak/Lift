//
//  SQLiteCreateTableParser.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

enum ParserError: Error {
    case notCreateStatement
    case notATableStatement
    case noTableName
    case noDefinitions
    case unexpectedError(String)

}

class SQLiteCreateTableParser {

    private init() {}
    
    /// Parses creation found here: http://www.sqlite.org/lang_createtable.html
    ///
    /// - Parameter statement: Table creation SQL, can be retreived from sqlite_master table
    /// - Returns: a table definition for the sql
    /// - Throws: if an error occurs from sql parsing.
    static func parseSQL(_ statement: String) throws -> TableDefinition {

        let stringScanner = Scanner(string: statement)
        stringScanner.caseSensitive = false

        guard stringScanner.scanString("CREATE ", into: nil) else {
            throw ParserError.notCreateStatement
        }


        var currentTable = TableDefinition()

        if stringScanner.scanString("TEMPORARY ", into: nil) || stringScanner.scanString("TEMP ", into: nil) {
            currentTable.isTemp = true
        }

        guard stringScanner.scanString("TABLE ", into: nil) else {
            throw ParserError.notATableStatement
        }


        try currentTable.parseTableName(from: stringScanner)

        guard stringScanner.scanString("(", into: nil) else {
            throw ParserError.noDefinitions
        }

        let initialColumn = try ColumnDefinition(from: stringScanner)
        currentTable.columns.append(initialColumn)


        if stringScanner.scanString("WITHOUT ROWID", into: nil) {
            currentTable.withoutRowID = true
        }
        
        return currentTable
    }

 
    
}
