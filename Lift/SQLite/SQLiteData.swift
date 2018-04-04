//
//  SQLiteData.swift
//  Lift
//
//  Created by Carl Wieland on 10/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

enum SQLiteDataType: Int {
    case null
    case integer
    case float
    case text
    case blob
}


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

    var forEditing: String {
        switch self {
        case .null:
            return ""
        case .float(let dbl):
            return "\(dbl)"
        case .integer(let intVal):
            return "\(intVal)"
        case .text(let str):
            return str
        case .blob(let data):
            return "X'\(data.hexEncodedString())'"
        }
    }

    var type: SQLiteDataType {
        switch self {
        case .null:
            return .null
        case .float:
            return .float
        case .integer:
            return .integer
        case .text:
            return .text
        case .blob:
            return .blob
        }
    }
}
extension SQLiteData: Equatable {
    
}

func ==(lhs:SQLiteData, rhs: SQLiteData) -> Bool {
    switch (lhs, rhs) {
    case (.text(let l), .text(let r)):
        return l == r
    case (.float(let l), .float(let r)):
        return l == r
    case (.blob(let l), .blob(let r)):
        return l == r
    case (.integer(let l), .integer(let r)):
        return l == r
    case (.null, .null):
        return true
    default:
        return false
    }
}
