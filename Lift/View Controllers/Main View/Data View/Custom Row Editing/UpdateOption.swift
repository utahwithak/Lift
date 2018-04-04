//
//  UpdateOption.swift
//  Lift
//
//  Created by Carl Wieland on 4/3/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

enum UpdateOption: Int {
    case update
    case updateOrRollBack
    case updateOrAbort
    case updateOrReplace
    case updateOrFail
    case updateOrIgnore

    init(type: NSNumber) {
        self.init(rawValue: type.intValue % 6)!
    }

    var sql: String {
        switch self {
        case .update:
            return "UPDATE"
        case .updateOrRollBack:
            return "UPDATE OR ROLLBACK"
        case .updateOrAbort:
            return "UPDATE OR ABORT"
        case .updateOrReplace:
            return "UPDATE OR REPLACE"
        case .updateOrFail:
            return "UPDATE OR FAIL"
        case .updateOrIgnore:
            return "UPDATE OR IGNORE"
        }
    }

    static var updateOptions: [String] {
        return [NSLocalizedString("Update", comment: "Update option type"),
                NSLocalizedString("Update or rollback", comment: "Update option type"),
                NSLocalizedString("Update or abort", comment: "Update option type"),
                NSLocalizedString("Update or replace", comment: "Update option type"),
                NSLocalizedString("Update or fail", comment: "Update option type"),
                NSLocalizedString("Update or ignore", comment: "Update option type")]
    }
}
