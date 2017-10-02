//
//  ColumnDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation


class ColumnDefinition {

    public var name: SQLiteName

    public var type: SQLiteName?

    public var columnConstraints = [ColumnConstraint]()

    init?(from scanner: Scanner) throws {

        name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        if name.isEmpty {
            return nil
        }

        type = try ColumnDefinition.parseType(from: scanner)

        while let constraint = try ColumnConstraint.parseConstraint(from: scanner) {
            columnConstraints.append(constraint)
        }

        
    }


    private static func parseType(from scanner: Scanner) throws -> SQLiteName? {

        var type: SQLiteName?

        var lastWhiteSpace: String?

        var buffer: NSString?

        let openParenChars = CharacterSet.whitespaces.union(CharacterSet(charactersIn: "("))
        while !scanner.isAtEnd {

            let curIndex = scanner.scanLocation

            let nextPart = try SQLiteCreateTableParser.parseStringOrName(from: scanner)

            switch nextPart.rawValue.lowercased() {

            case "constraint", "primary", "not", "unique", "check", "default", "collate", "foreign":
                scanner.scanLocation = curIndex
                return type
            default:

                if nextPart.isEmpty {
                    return type
                }

                if let whiteSpace = lastWhiteSpace, let curType = type {
                    type = SQLiteName(rawValue: curType.rawValue + whiteSpace)
                }

                if let curType = type {
                    type = SQLiteName(rawValue: curType.rawValue + nextPart.rawValue)
                } else {
                    type = nextPart
                }

            }

            let prev = scanner.charactersToBeSkipped
            scanner.charactersToBeSkipped = nil

            buffer = nil

            if var name = type, scanner.scanCharacters(from: openParenChars, into: &buffer), (buffer?.hasSuffix("(") ?? false)  {
                name = name + (buffer as String? ?? "")

                scanner.scanUpTo(")", into: &buffer)
                name = name + (buffer as String? ?? "")

                if !scanner.scanString(")", into: &buffer) {
                    throw ParserError.unexpectedError("No close paren")
                }

                return name + (buffer as String? ?? "")


            } else {
                if buffer == nil {
                    scanner.scanCharacters(from: CharacterSet.whitespaces, into: &buffer)
                    lastWhiteSpace = buffer as String?
                } else {
                    lastWhiteSpace = buffer as String?
                }

            }
            scanner.charactersToBeSkipped = prev

        }
        return type
    }

}


