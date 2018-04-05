//
//  ConflictClause.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

enum ConflictResolution {
    case rollback
    case abort
    case fail
    case ignore
    case replace
    var sql: String {
        switch self {
        case .rollback:
            return "ROLLBACK"
        case .abort:
            return "ABORT"
        case .fail:
            return "FAIL"
        case .ignore:
            return "IGNORE"
        case .replace:
            return "REPLACE"
        }
    }
}

class ConflictClause {

    let resolution: ConflictResolution

    init?(from scanner: Scanner) throws {
        if !scanner.scanString("ON", into: nil) {
            return nil
        }

        guard scanner.scanString("conflict", into: nil) else {
            throw ParserError.unexpectedError("Invalid conflict clause, exptected CONFLICT after ON")
        }

        if scanner.scanString("rollback", into: nil) {
            resolution = .rollback
        } else if scanner.scanString("abort", into: nil) {
            resolution = .abort
        } else if scanner.scanString("fail", into: nil) {
            resolution = .fail
        } else if scanner.scanString("ignore", into: nil) {
            resolution = .ignore
        } else if scanner.scanString("replace", into: nil) {
            resolution = .replace
        } else {
            throw ParserError.unexpectedError("Unexpected resolution string!")
        }
    }

    var sql: String {
        return "ON CONFLICT \(resolution.sql) "
    }
    private init(copying: ConflictClause) {
        self.resolution = copying.resolution
    }

    var copy: ConflictClause {
        return ConflictClause(copying: self)
    }
}
