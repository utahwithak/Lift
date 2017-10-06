//
//  ColumnName.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class SQLiteName: NSObject {

    @objc dynamic public private(set) var rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    var isEmpty: Bool {
        return rawValue.isEmpty
    }

    static let invalidChars: CharacterSet = {
        var set = CharacterSet.alphanumerics.inverted
        set.remove(charactersIn: "_")
        return set
    }()

    var sql: String {
        if (rawValue.first == "\"" || rawValue.first == "'" || rawValue.first == "`") && rawValue.balancedQoutedString() {
            return rawValue
        }

        if rawValue.rangeOfCharacter(from: SQLiteName.invalidChars) != nil {
            var returnVal = rawValue
            if rawValue.contains("\"") {
                returnVal = rawValue.replacingOccurrences(of: "\"", with: "\"\"")
            }
            return "\"\(returnVal)\""

        } else {
            return rawValue
        }
    }


}

func +(lhs: SQLiteName, rhs: SQLiteName) -> SQLiteName {
    return SQLiteName(rawValue: lhs.rawValue + rhs.rawValue)
}

func +(lhs: SQLiteName, rhs: String) -> SQLiteName {
    return SQLiteName(rawValue: lhs.rawValue + rhs)
}

func == (lhs: SQLiteName, rhs: String) -> Bool {
    return lhs.rawValue == rhs
}

func == (lhs: SQLiteName, rhs: SQLiteName) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

func != (lhs: SQLiteName, rhs: SQLiteName) -> Bool {
    return lhs.rawValue != rhs.rawValue
}
