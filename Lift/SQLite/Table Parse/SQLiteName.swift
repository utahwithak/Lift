//
//  ColumnName.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class SQLiteName: NSObject {

    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    var isEmpty: Bool {
        return rawValue.isEmpty
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
