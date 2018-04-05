//
//  ColumnDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

protocol ColumnNameProvider: class {
    var columnName: SQLiteName { get }
}

extension SQLiteName: ColumnNameProvider {
    var columnName: SQLiteName {
        return self
    }
}

class ColumnDefinition: NSObject {

    @objc dynamic public var name: SQLiteName

    @objc dynamic public var type: SQLiteName?

    public weak var table: TableDefinition?

    public var columnConstraints = [ColumnConstraint]()

    @objc dynamic public var defaultExpression: String? {
        get {
            return (columnConstraints.first(where: { $0 is DefaultColumnConstraint}) as? DefaultColumnConstraint)?.value.sql
        }
        set {

            if let defIndex = columnConstraints.index(where: { $0 is DefaultColumnConstraint }), let defaultConstraint = columnConstraints[defIndex] as? DefaultColumnConstraint {
                guard let val = newValue, !val.isEmpty else {
                    columnConstraints.remove(at: defIndex)
                    return
                }
                defaultConstraint.value = DefaultValue(text: val)
            } else if let newValue = newValue, !newValue.isEmpty {
                let newconstraint = DefaultColumnConstraint(value: DefaultValue(text: newValue))
                columnConstraints.append(newconstraint)
            }
        }
    }

    init?(from scanner: Scanner) throws {
        originalColumn = nil
        name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        if name.isEmpty {
            return nil
        }

        type = try ColumnDefinition.parseType(from: scanner)

        while let constraint = try ColumnConstraint.parseConstraint(from: scanner) {
            columnConstraints.append(constraint)
        }

    }

    public let originalColumn: ColumnDefinition?

    override init() {
        self.name = SQLiteName(rawValue: "New Column")
        originalColumn = nil
    }

    init(name: String) {
        self.name = SQLiteName(rawValue: name)
        originalColumn = nil
    }

    private init(copying: ColumnDefinition) {
        self.originalColumn = copying
        name = copying.name.copy
        type = copying.type?.copy
        columnConstraints = copying.columnConstraints.map({ $0.copy() })
    }

    func duplicateForEditing() -> ColumnDefinition {
        return ColumnDefinition(copying: self)
    }

    private static func parseType(from scanner: Scanner) throws -> SQLiteName? {

        var type: SQLiteName?

        var lastWhiteSpace: String?

        var buffer: NSString?

        let openParenChars = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "("))
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

            if var name = type, scanner.scanCharacters(from: openParenChars, into: &buffer), (buffer?.hasSuffix("(") ?? false) {
                name = name + (buffer as String? ?? "")

                scanner.scanUpTo(")", into: &buffer)
                name = name + (buffer as String? ?? "")

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

    var creationStatement: String {

        var builder = "\(name.sql)"
        if let includedType = type {
            builder += " \(includedType.rawValue)"
        }
        let constrantText = columnConstraints.map({ $0.sql}).joined(separator: " ")

        if !constrantText.isEmpty {
            builder += " " + constrantText
        }

        return builder
    }

}

extension ColumnDefinition: ColumnNameProvider {
    var columnName: SQLiteName {
        return name
    }
}
