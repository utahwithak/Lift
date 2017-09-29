//
//  TableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation
class TableConstraint {

    var name: String

    init(named name: String) {
        self.name = name
    }

    static func parseConstraint(from scanner: Scanner) throws -> TableConstraint {
        var name = ""

        if scanner.scanString("constraint", into: nil) {
            name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        }

        let curIndex = scanner.scanLocation
        let nextPart = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        scanner.scanLocation = curIndex
        switch nextPart.lowercased() {
        case "primary":
            return try PrimaryKeyTableConstraint(from: scanner, named: name)
        case "unique":
            return try UniqueTableConstraint(from: scanner, named: name)
        case "check":
            return try CheckTableConstraint(from: scanner, named: name)
        case "foreign":
            return try ForeignKeyTableConstraint(from: scanner, named: name)
        default:
            throw ParserError.unexpectedError("Unexpected table constraint type!")
        }

    }

}
