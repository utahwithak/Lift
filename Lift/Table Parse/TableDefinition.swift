//
//  TableDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class TableDefinition {
    public var isTemp = false
    public var withoutRowID = false
    public var databaseName = ""
    public var tableName = ""

    public var columns = [ColumnDefinition]()

    public var tableConstraints = [TableConstraint]()


    func parseTableName(from scanner: Scanner) throws {
        let skipChars = scanner.charactersToBeSkipped
        scanner.charactersToBeSkipped = nil
        tableName = ""
        var parsedName = false
        var buffer: NSString?
        while !parsedName {

            let scannedTo = scanner.scanUpTo("(", into: &buffer)

            if !scannedTo && tableName.hasPrefix("\"") {
                guard scanner.scanString("(", into: &buffer) else {
                    throw ParserError.unexpectedError("Unable to parse an expected (")
                }
            }

            guard let namePart = buffer as String? else {
                throw ParserError.unexpectedError("Unable to parse name correctly")
            }

            tableName += namePart

            if tableName.hasPrefix("\""){
                //if we end with a plain " we've got it all
                if tableName.count > 1 && tableName.hasSuffix("\"") && (!tableName.hasSuffix("\"\"") || tableName.hasSuffix("\"\"\"")) {
                    parsedName = true
                    tableName = String(tableName.dropFirst().dropLast())
                }
            } else {
                let trimmed = tableName.trimmingCharacters(in: CharacterSet.whitespaces)
                guard !trimmed.isEmpty else {
                    throw ParserError.noTableName
                }

                parsedName = true
                tableName = trimmed
            }

        }

        scanner.charactersToBeSkipped = skipChars

    }

}
