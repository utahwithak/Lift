//
//  InsertionOption.swift
//  Lift
//
//  Created by Carl Wieland on 4/3/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation
enum InsertOption: Int {
    case insert
    case replace
    case insertOrReplace
    case insertOrRollback
    case insertOrAbort
    case insertOrFail
    case insertOrIgnore
    init(type: NSNumber) {
        self.init(rawValue: type.intValue % 7)!
    }
    var sql: String {
        switch self {
        case .insert:
            return "INSERT"
        case .replace:
            return "REPLACE"
        case .insertOrReplace:
            return "INSERT OR REPLACE"
        case .insertOrRollback:
            return "INSERT OR ROLLBACK"
        case .insertOrAbort:
            return "INSERT OR ABORT"
        case .insertOrFail:
            return "INSERT OR FAIL"
        case .insertOrIgnore:
            return "INSERT OR IGNORE"
        }
    }

    static var insertionOptions: [String] {
        return [NSLocalizedString("Insert", comment: "Insert option type"),
                NSLocalizedString("Replace", comment: "Insert option type"),
                NSLocalizedString("Insert or replace", comment: "Insert option type"),
                NSLocalizedString("Insert or rollback", comment: "Insert option type"),
                NSLocalizedString("Insert or abort", comment: "Insert option type"),
                NSLocalizedString("Insert or fail", comment: "Insert option type"),
                NSLocalizedString("Insert or ignore", comment: "Insert option type")]
    }
}
