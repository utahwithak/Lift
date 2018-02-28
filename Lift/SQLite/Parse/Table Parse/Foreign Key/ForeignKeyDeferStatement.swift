//
//  ForeignKeyDeferStatement.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation


enum DeferType {
    case notSpecified
    case initiallyDeferred
    case initiallyImmediate
}

class ForeignKeyDeferStatement: Equatable {

    var isDeferrable = true
    var type = DeferType.notSpecified

    init(deferrable: Bool = true, type: DeferType = .notSpecified) {
        isDeferrable = deferrable
        self.type = type
    }

    init(from scanner: Scanner) throws {
        if scanner.scanString("not", into: nil) {
            isDeferrable = false
        }

        guard scanner.scanString("deferrable", into: nil) else {
            throw ParserError.unexpectedError("Expecting a defer statement, but it doesn't match!")
        }

        if scanner.scanString("initially", into: nil) {
            if scanner.scanString("deferred", into: nil) {
                type = .initiallyDeferred
            } else if scanner.scanString("immediate", into: nil) {
                type = .initiallyImmediate
            } else {
                throw ParserError.unexpectedError("Parsing defer statement and didn't get immediate or deferred!?")
            }
        }
        
    }
    var sql: String {
        var builder = isDeferrable ? "DEFERRABLE" : "NOT DEFERRABLE"
        switch type {
        case .initiallyDeferred:
            builder += " INITIALLY DEFERRED"
        case .initiallyImmediate:
            builder += " INITIALLY IMMEDIATE"
        case .notSpecified:
            break
        }

        return builder
    }
}

func ==(lhs: ForeignKeyDeferStatement, rhs: ForeignKeyDeferStatement) -> Bool {
    return lhs.isDeferrable == rhs.isDeferrable && lhs.type == rhs.type
}
