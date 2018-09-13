//
//  NewRowValueTypeConversion.swift
//  Lift
//
//  Created by Carl Wieland on 4/6/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class NewRowValueTypeConversion: NSObject {

    static func conversionTypes(for data: SQLiteData) -> [NewRowValueTypeConversion] {
        switch data {
        case .text(let str):
            var types = [textType]
            if Int(str) != nil {
                types.append(.integerType)
            }
            if Double(str) != nil {
                types.append(.realType)
            }
            types.append(dataType)
            return types
        case .integer:
            return [integerType, textType, realType, dataType]
        case .float:
            return [realType, textType, integerType, dataType]
        case .blob(let data):
            var conversionTypes = [dataType]
            if String(bytes: data, encoding: .utf8) != nil {
                conversionTypes.append(textType)
            }
            if data.count <= MemoryLayout<Int>.size {
                conversionTypes.append(integerType)
            }
            if data.count <= MemoryLayout<Double>.size {
                conversionTypes.append(realType)
            }
            return conversionTypes
        case .null:
            return []
        }
    }

    @objc dynamic let name: String
    let dataType: SQLiteDataType
    init(name: String, type: SQLiteDataType) {
        self.name = name
        self.dataType = type
    }
    static let textType = NewRowValueTypeConversion(name: NSLocalizedString("String", comment: "String type description"), type: .text)
    static let integerType = NewRowValueTypeConversion(name: NSLocalizedString("Integer", comment: "Integer type description"), type: .integer)
    static let realType = NewRowValueTypeConversion(name: NSLocalizedString("Real", comment: "Double type description"), type: .float)
    static let dataType = NewRowValueTypeConversion(name: NSLocalizedString("Blob", comment: "Blob type description"), type: .blob)

    static func convert(data: SQLiteData, with conversion: NewRowValueTypeConversion) -> SQLiteData {
        switch data {
        case .text(let text):
            if conversion === integerType, let int = Int(text) {
                return .integer(int)
            } else if conversion === realType, let doub = Double(text) {
                return .float(doub)
            } else if conversion === dataType, let data = text.data(using: .utf8) {
                return .blob(data)
            } else if conversion === textType {
                return data
            }
        case .integer(let int):
            if conversion === integerType {
                return data
            } else if conversion === realType {
                return .float(Double(int))
            } else if conversion === dataType {
                var tmp = int
                let intData = Data(bytes: &tmp, count: MemoryLayout.size(ofValue: tmp))
                return .blob(intData)
            } else if conversion === textType {
                return .text("\(int)")
            }
        case .float(let dbl):
            if conversion === integerType {
                return .integer(Int(dbl))
            } else if conversion === realType {
                return data
            } else if conversion === dataType {
                var tmp = dbl
                let dblData = Data(bytes: &tmp, count: MemoryLayout.size(ofValue: tmp))
                return .blob(dblData)
            } else if conversion === textType {
                return .text("\(dbl)")
            }
        case .blob(let blb):
            if conversion === integerType {
                return .integer(blb.to(type: Int.self))
            } else if conversion === realType {
                return .float(blb.to(type: Double.self))
            } else if conversion === dataType {
                return data
            } else if conversion === textType, let converted = String(bytes: blb, encoding: .utf8) {
                return .text(converted)
            }
        default:
            return data

        }

        return data

    }
}
