//
//  ColumnDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

protocol ColumnNameProvider {
    var name: SQLiteName { get }
}

extension SQLiteName: ColumnNameProvider {
    var name: SQLiteName {
        return self
    }
}

struct ColumnDefinition {

    public var name: SQLiteName

    public var type: SQLiteName?

    public var columnConstraints = [ColumnConstraint]()

    init?(from scanner: Scanner) throws {
        name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        if name.isEmpty {
            return nil
        }

        type = try ColumnDefinition.parseType(from: scanner)

        while let constraint = try ColumnDefinition.parseColumnConstraint(from: scanner) {
            columnConstraints.append(constraint)
        }

    }

    init() {
        self.name = "New Column"
    }

    init(name: String) {
        self.name = name
    }

    private static func parseType(from scanner: Scanner) throws -> SQLiteName? {

        var type: SQLiteName?

        var lastWhiteSpace: String?

        var buffer: NSString?

        let openParenChars = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "("))
        while !scanner.isAtEnd {

            let curIndex = scanner.scanLocation

            let nextPart = try SQLiteCreateTableParser.parseStringOrName(from: scanner)

            switch nextPart.lowercased() {

            case "constraint", "primary", "not", "unique", "check", "default", "collate", "foreign":
                scanner.scanLocation = curIndex
                return type
            default:

                if nextPart.isEmpty {
                    return type
                }

                if let whiteSpace = lastWhiteSpace, let curType = type {
                    type = curType + whiteSpace
                }

                if let curType = type {
                    type = curType + nextPart
                } else {
                    type = nextPart
                }

            }

            let prev = scanner.charactersToBeSkipped
            scanner.charactersToBeSkipped = nil

            buffer = nil

            if var name = type, scanner.scanCharacters(from: openParenChars, into: &buffer), (buffer?.hasSuffix("(") ?? false) {
                name += (buffer as String? ?? "")

                scanner.scanUpTo(")", into: &buffer)
                name += (buffer as String? ?? "")

                if !scanner.scanString(")", into: &buffer) {
                    throw ParserError.unexpectedError("No close paren")
                }
                scanner.charactersToBeSkipped = prev
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

    static func parseColumnConstraint(from scanner: Scanner) throws -> ColumnConstraint? {
        var name: SQLiteName?

        if scanner.scanString("constraint", into: nil) {
            name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        }

        scanner.scanCharacters(from: CharacterSet.whitespacesAndNewlines, into: nil)

        let curIndex = scanner.scanLocation
        let nextPart = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        scanner.scanLocation = curIndex
        switch nextPart.lowercased() {
        case "primary":
            return try PrimaryKeyColumnConstraint(with: name, from: scanner)
        case "not":
            return try NotNullColumnConstraint(with: name, from: scanner)
        case "unique":
            return try UniqueColumnConstraint(with: name, from: scanner)
        case "check":
            return try CheckColumnConstraint(with: name, from: scanner)
        case "default":
            return try DefaultColumnConstraint(with: name, from: scanner)
        case "collate":
            return try CollateColumnConstraint(with: name, from: scanner)
        case "references":
            return try ForeignKeyColumnConstraint(with: name, from: scanner)
        default:
            return nil
        }
    }

    var creationStatement: String {

        var builder = "\(name.sql)"
        if let includedType = type {
            builder += " \(includedType)"
        }
        let constrantText = columnConstraints.map({ $0.sql}).joined(separator: " ")

        if !constrantText.isEmpty {
            builder += " \(constrantText)"
        }

        return builder
    }

}

extension ColumnDefinition: ColumnNameProvider {
}
