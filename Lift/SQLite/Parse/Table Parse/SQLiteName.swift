//
//  ColumnName.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

typealias SQLiteName = String

extension SQLiteName {

    static let invalidChars: CharacterSet = {
        var set = CharacterSet.alphanumerics.inverted
        set.remove(charactersIn: "_")
        set.insert("-")
        return set
    }()

    var sql: String {
        return sqliteSafeString()
    }

    var cleanedVersion: String {
        if (first == "\"" || first == "'" || first == "`") && balancedQoutedString() {
            return String(dropFirst().dropLast())
        } else if first == "[" && last == "]" {
            return String(dropFirst().dropLast())
        } else {
            return self
        }
    }
}
