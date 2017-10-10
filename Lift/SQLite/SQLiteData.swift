//
//  SQLiteData.swift
//  Lift
//
//  Created by Carl Wieland on 10/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

enum SQLiteData {
    case null
    case integer(Int)
    case float(Double)
    case text(String)
    case blob(Data)

    var intValue: Int? {
        switch self {
        case .null:
            return nil
        case .float(let doub):
            return Int(doub)
        case .integer(let int):
            return int
        case .text(let str):
            return Int(str)
        case .blob(_):
            return nil
        }
    }

    var forWhereClause: String {
        switch self {
        case .null:
            return "NULL"
        case .float(let dbl):
            return "\(dbl)"
        case .integer(let intVal):
            return "\(intVal)"
        case .text(let str):
            return str.sqliteSafeString()
        case .blob(let data):
             return "X'\(data.hexEncodedString())'"
        }
    }
}
