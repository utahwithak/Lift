//
//  ColumnDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation


struct ColumnDefinition {

    public var name = ""


    init(from scanner: Scanner) throws {

        name = try ColumnDefinition.parseColumnName(from: scanner)

        
    }


    private static func parseColumnName(from scanner: Scanner) throws -> String {
        let skipChars = scanner.charactersToBeSkipped
        scanner.charactersToBeSkipped = nil

        defer {
            scanner.charactersToBeSkipped = skipChars
        }

        scanner.scanCharacters(from:CharacterSet.whitespaces, into: nil)

        var buffer: NSString?

        var name = ""

        // scanned off the start portion of start
        if scanner.scanString("\"", into: nil) {
            // scan till the end of "
            while !scanner.isAtEnd {
                let scannedPart = scanner.scanUpTo("\"", into: &buffer)

                if !scannedPart {
                    // try double qoutes
                    if !scanner.scanString("\"\"", into: &buffer) {
                        guard scanner.scanString("\"", into: &buffer) else {
                            throw ParserError.unexpectedError("Unable to parse column name with double qoutes!")
                        }
                    }
                }

                guard let str = buffer as String? else {
                    throw ParserError.unexpectedError("Unable to parse column name!")
                }

                name += str

                if name.count > 1 && name.hasSuffix("\"") && (!name.hasSuffix("\"\"") || name.hasSuffix("\"\"\"")) {

                    return String(name.dropLast())
                }

            }
        }


        var validChars = CharacterSet.alphanumerics
        validChars.insert("_")

        while !scanner.isAtEnd {

            let scannedPortions = scanner.scanCharacters(from: validChars , into: &buffer)

            if !scannedPortions && !scanner.scanString("\"\"", into: &buffer) {
                return name
            }


            guard let str = buffer as String? else {
                throw ParserError.unexpectedError("Unable to parse column name!")
            }

            name += str


        }








//            guard let nameSection = buffer as String? else {
//                throw ParserError.unexpectedError("Unable to parse column name!")
//            }
//
//



        return name



    }



}
