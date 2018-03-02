//
//  SQLiteCreateViewParser.swift
//  Lift
//
//  Created by Carl Wieland on 2/28/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class SQLiteCreateViewParser {
    private init() {

    }

    //https://www.sqlite.org/lang_createview.html
    public static func parse(sql: String) throws -> ViewDefinition {
        let stringScanner = Scanner(string: sql)
        stringScanner.caseSensitive = false


        guard stringScanner.scanString("CREATE ", into: nil) else {
            throw ParserError.notCreateStatement
        }

        let def = ViewDefinition()

        if stringScanner.scanString("TEMPORARY ", into: nil) || stringScanner.scanString("TEMP ", into: nil) {
            def.isTemp = true
        }

        guard stringScanner.scanString("VIEW ", into: nil) else {
            throw ParserError.notAViewStatement
        }

        def.name = try SQLiteCreateTableParser.parseStringOrName(from: stringScanner)

        if stringScanner.scanString("(", into: nil) {
            def.specifyColumns = true
            
            let initialColumn = try SQLiteCreateTableParser.parseStringOrName(from: stringScanner)
            def.columns.append(initialColumn)

            var parsingColumns = stringScanner.scanString(",", into: nil)
            while parsingColumns {

                stringScanner.scanCharacters(from: CharacterSet.whitespacesAndNewlines, into: nil)

                let nextName = try SQLiteCreateTableParser.parseStringOrName(from: stringScanner)
                def.columns.append(nextName)
                parsingColumns = stringScanner.scanString(",", into: nil)
            }

            guard stringScanner.scanString(")", into: nil) else {
                throw ParserError.unexpectedError("Expected end of definitions, not found!:\(String(sql.dropFirst(stringScanner.scanLocation)))")
            }
        }
        stringScanner.scanCharacters(from: CharacterSet.whitespacesAndNewlines, into: nil)
        guard stringScanner.scanString("AS", into: nil) else {
            throw ParserError.unexpectedError("No AS statement!")
        }
        stringScanner.scanCharacters(from: CharacterSet.whitespacesAndNewlines, into: nil)
        def.selectStatement = String(sql.dropFirst(stringScanner.scanLocation)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return def
    }

}
