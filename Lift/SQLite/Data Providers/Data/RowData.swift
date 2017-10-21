//
//  RowData.swift
//  Lift
//
//  Created by Carl Wieland on 10/18/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct RowData {

    init(row: [SQLiteData]) {
        self.data = row
    }

    let data: [SQLiteData]

    lazy var datas: [CellData] = {
        return self.data.map {
            switch $0 {
            case .text(let strVal):
                return CellData(type: .text, displayValue: strVal)
            case .blob(_):
                return CellData(type: .blob, displayValue: "<blob>")
            case .null:
                return CellData(type: .null, displayValue: "<null>")
            case .integer(let int):
                return CellData(type: .integer, displayValue: "\(int)")
            case .float(let dbl):
                return CellData(type: .float, displayValue:  "\(dbl)")
            }
        }
    }()

    func last(_ x: Int) -> ArraySlice<SQLiteData> {
        return data.dropFirst(data.count - x)
    }



    subscript (index: Int) -> CellData {
        mutating get {
            return datas[index]
        }
    }
}

struct CellData {
    let type: SQLiteDataType
    let displayValue: String
}
