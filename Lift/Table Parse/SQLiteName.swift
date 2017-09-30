//
//  ColumnName.swift
//  Lift
//
//  Created by Carl Wieland on 9/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct SQLiteName: Equatable {
    let rawValue: String


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
