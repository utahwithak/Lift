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
    var sql: String {
        switch  self {
        case .delete:
            return "DELETE"
        case .update:
            return "UPDATE"
        }
    }
}

enum ActionResult {
    case setNull
    case setDefault
    case cascade
    case restrict
    case noAction

    var sql: String {
        switch self {
        case .setNull:
            return "SET NULL"
        case .setDefault:
            return "SET DEFAULT"
        case .cascade:
            return "CASCADE"
        case .restrict:
            return "RESTRICT"
        case .noAction:
            return "NO ACTION"
        }
    }
}

struct ForeignKeyActionStatement: Equatable {
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

    var sql: String {
        return "ON \(type.sql) \(result.sql) "
    }
}

func == (lhs: ForeignKeyActionStatement, rhs: ForeignKeyActionStatement) -> Bool {
    return lhs.type == rhs.type && lhs.result == rhs.result
}
