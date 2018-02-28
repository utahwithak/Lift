//
//  ColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class ColumnConstraint {
    var constraintName: SQLiteName?

    init(name: SQLiteName?) {
        constraintName = name
    }

    static func parseConstraint(from scanner: Scanner) throws -> ColumnConstraint? {
        var name: SQLiteName?

        if scanner.scanString("constraint", into: nil) {
            name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        }

        scanner.scanCharacters(from: CharacterSet.whitespacesAndNewlines, into: nil)
        
        let curIndex = scanner.scanLocation
        let nextPart = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        scanner.scanLocation = curIndex
        switch nextPart.rawValue.lowercased() {
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
    
    var sql: String {
        return ""
    }
    
}
