//
//  DefaultColumnConstraint.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

enum DefaultValue {
    case null
    case current_time
    case current_date
    case current_timestamp
    case literal(SQLiteName)
    case expression(String)
}


class DefaultColumnConstraint: ColumnConstraint {

    var value: DefaultValue

    init(with name: SQLiteName?, from scanner: Scanner) throws {

        guard scanner.scanString("DEFAULT", into: nil) else {
            throw ParserError.unexpectedError("Expecting to parse default col const")
        }

        if scanner.scanString("(", into: nil) {
            //move back to before the exp so balancing works out
            scanner.scanLocation -= 1
            value = .expression(try SQLiteCreateTableParser.parseExp(from: scanner))
        } else if scanner.scanString("NULL", into: nil) {
            value = .null
        } else if scanner.scanString("CURRENT_TIME", into: nil) {
            value = .current_time
        } else if scanner.scanString("CURRENT_DATE", into: nil) {
            value = .current_date
        } else if scanner.scanString("CURRENT_TIMESTAMP", into: nil) {
            value = .current_timestamp
        } else {
            value = .literal(try SQLiteCreateTableParser.parseStringOrName(from: scanner))
        }


        super.init(name: name)
    }
}
