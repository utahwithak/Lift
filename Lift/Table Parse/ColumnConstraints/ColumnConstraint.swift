//
//  ColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class ColumnConstraint {
    var constraintName: String

    init(name: String) {
        constraintName = name
    }

    static func parseConstraint(from scanner: Scanner) throws -> ColumnConstraint? {
        var name = ""

        if scanner.scanString("constraint", into: nil) {
            name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        }

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
        case "foreign":
            return try ForeignKeyColumnConstraint(with: name, from: scanner)
        default:
            return nil
        }

    }
    
    
}
