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


        let currentTable = TableDefinition()

        if stringScanner.scanString("TEMPORARY ", into: nil) || stringScanner.scanString("TEMP ", into: nil) {
            currentTable.isTemp = true
        }

        guard stringScanner.scanString("TABLE ", into: nil) else {
            throw ParserError.notATableStatement
        }

        currentTable.tableName = try SQLiteCreateTableParser.parseStringOrName(from: stringScanner)

        guard stringScanner.scanString("(", into: nil) else {
            throw ParserError.noDefinitions
        }

        guard let initialColumn = try ColumnDefinition(from: stringScanner) else {
            throw ParserError.noDefinitions
        }

        currentTable.columns.append(initialColumn)

        var parsedAConstraint = false

        var parsingColumns = stringScanner.scanString(",", into: nil)
        while parsingColumns {

            stringScanner.scanCharacters(from: CharacterSet.whitespacesAndNewlines, into: nil)

            let currentLocation = stringScanner.scanLocation

            do {
                let nextName = try parseStringOrName(from: stringScanner)
                stringScanner.scanLocation = currentLocation
                switch nextName.rawValue.lowercased() {
                case "constraint", "primary", "unique", "check", "foreign":
                    let constraint = try TableConstraint.parseConstraint(from: stringScanner)
                    currentTable.tableConstraints.append(constraint)
                    parsedAConstraint = true
                default:
                    if parsedAConstraint {
                        throw ParserError.unexpectedError("Column after table constraint, that is invalid!")
                    }
                    guard let column = try ColumnDefinition(from: stringScanner) else {
                        parsingColumns = false
                        continue
                    }
                    currentTable.columns.append(column)
                }
            } catch {
                parsingColumns = false
            }

            parsingColumns = stringScanner.scanString(",", into: nil)

        }

        guard stringScanner.scanString(")", into: nil) else {
            throw ParserError.unexpectedError("Expected end of definitions, not found!:\(String(statement.dropFirst(stringScanner.scanLocation)))")
        }

        currentTable.withoutRowID = stringScanner.scanString("WITHOUT ROWID", into: nil)

        return currentTable
    }

    private static let qouteCharacters = CharacterSet(charactersIn: "\"'`")

    public static func parseStringOrName(from scanner: Scanner) throws -> SQLiteName {
        let skipChars = scanner.charactersToBeSkipped
        scanner.charactersToBeSkipped = nil

        defer {
            scanner.charactersToBeSkipped = skipChars
        }

        scanner.scanCharacters(from:CharacterSet.whitespacesAndNewlines, into: nil)

        var buffer: NSString?

        var name = ""

        // scanned off the start portion of start


        if scanner.scanCharacters(from: qouteCharacters, into: &buffer) {

            guard let openingChars = buffer as String?, let firstChar = openingChars.first else {
                throw ParserError.unexpectedError("unexpectedly unable to get first part of string")
            }
            let quoteChar = String(firstChar)

            name = openingChars
            if name.count > 1 && name.balancedQoutedString() {
               return SQLiteName(rawValue: name)
            }

            // scan till the end of "
            while !scanner.isAtEnd {
                let scannedPart = scanner.scanUpTo(quoteChar, into: &buffer)

                if !scannedPart {
                    var quoteCount = 0

                    while scanner.scanString(quoteChar, into: &buffer) {

                        quoteCount += 1

                        guard let str = buffer as String? else {
                            throw ParserError.unexpectedError("Unable to parse column name!")
                        }

                        name += str

                    }

                    guard quoteCount >= 1 else {
                        throw ParserError.unexpectedError("Unable to parse column name with double qoutes!")
                    }

                    // we finished
                    if quoteCount % 2 == 1 {
                        return SQLiteName(rawValue: name)
                    }

                } else {

                    guard let str = buffer as String? else {
                        throw ParserError.unexpectedError("Unable to parse column name!")
                    }

                    name += str

                }


            }
        } else if scanner.scanString("[", into: &buffer) {
            guard let openingChars = buffer as String? else {
                throw ParserError.unexpectedError("unexpectedly unable to get first part of string")
            }
            name = openingChars

            scanner.scanUpTo("]", into: &buffer)
            guard let remaining = buffer as String? else {
                throw ParserError.unexpectedError("unexpectedly unable to get first part of string")
            }
            name += remaining
            guard scanner.scanString("]", into: &buffer), let endchar = buffer as String? else {
                throw ParserError.unexpectedError("unexpectedly unable to get end of string")
            }
            name += endchar
            return SQLiteName(rawValue:name)


        }

        var validChars = CharacterSet.alphanumerics
        validChars.insert("_")

        while !scanner.isAtEnd {

            let scannedPortions = scanner.scanCharacters(from: validChars , into: &buffer)

            if !scannedPortions {
                return SQLiteName(rawValue: name)
            }

            guard let str = buffer as String? else {
                throw ParserError.unexpectedError("Unable to parse column name!")
            }

            name += str
        }

        return SQLiteName(rawValue: name)

    }

    static func parseExp(from scanner: Scanner) throws -> String {
        var buffer: NSString?
        var moreToParse = true
        var fullExpression = ""

        let skipChars = scanner.charactersToBeSkipped
        scanner.charactersToBeSkipped = nil

        defer {
            scanner.charactersToBeSkipped = skipChars
        }

        while moreToParse {
            scanner.scanUpTo(")", into: &buffer)
            guard let exp = buffer as String? else {
                throw ParserError.unexpectedError("Unable to parse check expression")
            }

            fullExpression += exp

            guard scanner.scanString(")", into: &buffer), let endingParen = buffer as String? else {
                throw ParserError.unexpectedError("expected Ending Paren!")
            }
            fullExpression += endingParen
            moreToParse = !fullExpression.isBalanced()
        }

        fullExpression = fullExpression.trimmingCharacters(in: CharacterSet.whitespaces)
        if fullExpression.isEmpty {
            throw ParserError.unexpectedError("Empty check expression!?")
        }
        return fullExpression

    }

 
    
}
