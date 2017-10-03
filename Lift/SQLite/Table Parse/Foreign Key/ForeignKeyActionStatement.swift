//
//  ForeignKeyActionStatement.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

enum ActionType {
    case delete
    case update
}

enum ActionResult {
    case setNull
    case setDefault
    case cascade
    case restrict
    case noAction
}

class ForeignKeyActionStatement: Equatable {
    var type: ActionType
    var result: ActionResult

    init(type: ActionType, result: ActionResult) {
        self.type = type
        self.result = result
    }

    init(from scanner: Scanner) throws {
        if scanner.scanString("delete", into: nil) {
            type = .delete
        } else if scanner.scanString("update", into: nil) {
            type = .update
        } else {
            throw ParserError.unexpectedError("Unknown action type in foreign key table constraint")
        }

        if scanner.scanString("set", into: nil) {
            if scanner.scanString("null", into: nil) {
                result = .setNull
            } else if scanner.scanString("default", into: nil) {
                result = .setDefault
            } else {
                throw ParserError.unexpectedError("Unable to parse result, got Set but not null or default!")
            }
        } else if scanner.scanString("cascade", into: nil) {
            result = .cascade
        } else if scanner.scanString("restrict", into: nil) {
            result = .restrict
        } else if scanner.scanString("No", into: nil) {
            if scanner.scanString("Action", into: nil) {
                result = .noAction
            } else {
                throw ParserError.unexpectedError("Unable to parse result, got No but not action!")
            }
        } else {
            throw ParserError.unexpectedError("Unable to parse result, got No but not action!")
        }
    }
}

func ==(lhs: ForeignKeyActionStatement, rhs: ForeignKeyActionStatement) -> Bool {
    return lhs.type == rhs.type && lhs.result == rhs.result
}
