//
//  CheckTableConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class CheckTableConstraint: TableConstraint {

    var checkExpression: String

    init(from scanner: Scanner,named name: String) throws {

        if !scanner.scanString("check", into: nil) {
            throw ParserError.unexpectedError("Invalid table check")
        }
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

        fullExpression = String(fullExpression.trimmingCharacters(in: CharacterSet.whitespaces).dropFirst().dropLast()).trimmingCharacters(in: CharacterSet.whitespaces)
        if fullExpression.isEmpty {
            throw ParserError.unexpectedError("Empty check expression!?")
        }

        //drop the ( and )

        checkExpression = fullExpression


        super.init(named: name)
    }
}
