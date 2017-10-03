//
//  TableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation
class TableConstraint: NSObject {

    var name: SQLiteName?

    init(name: SQLiteName?) {
        self.name = name
    }

    static func parseConstraint(from scanner: Scanner) throws -> TableConstraint {
        var name: SQLiteName?

        if scanner.scanString("constraint", into: nil) {
            name = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        }

        let curIndex = scanner.scanLocation
        let nextPart = try SQLiteCreateTableParser.parseStringOrName(from: scanner)
        scanner.scanLocation = curIndex
        switch nextPart.rawValue.lowercased() {
        case "primary":
            return try PrimaryKeyTableConstraint(with:name, from: scanner)
        case "unique":
            return try UniqueTableConstraint(with:name, from: scanner)
        case "check":
            return try CheckTableConstraint(with:name, from: scanner)
        case "foreign":
            return try ForeignKeyTableConstraint(with:name, from: scanner)
        default:
            throw ParserError.unexpectedError("Unexpected table constraint type!")
        }

    }

}
