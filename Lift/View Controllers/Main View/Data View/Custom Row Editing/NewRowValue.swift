//
//  NewRowValue.swift
//  Lift
//
//  Created by Carl Wieland on 3/7/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class NewRowValue: NSObject {

    enum NewValueType {
        case data(SQLiteData)
        case null
        case date
        case time
        case timeStamp
        case file(URL)
        case defaultValue

        var index: Int {
            switch self {
            case .data(let data):
                if data.type == .null {
                    return 1
                }
                return 0
            case .null:
                return 1
            case .date:
                return 2
            case .time:
                return 3
            case .timeStamp:
                return 4
            case .file:
                return 5
            case .defaultValue:
                return 6
            }
        }
    }

    @objc dynamic var typeIndex: Int {
        get {
            return newValueType.index
        }
        set {
            switch newValue {
            case 0:
                if currentValue.type == .null {
                    newValueType = .data(.text(""))
                } else {
                    newValueType = .data(currentValue)
                }
            case 1:
                newValueType = .null
            case 2:
                newValueType = .date
            case 3:
                newValueType = .time
            case 4:
                newValueType = .timeStamp
            default:
                newValueType = .file(URL(string: "")!)

            }
            refreshDisplayValue()

        }
    }

    var currentValue: SQLiteData!

    @objc dynamic var canEditTextually = false

    var newValueType: NewValueType = .null {
        didSet {
            refreshTextEdit()
            if case .data(let data) = newValueType {
                availableConversionTypes = NewRowValueTypeConversion.conversionTypes(for: data)
            } else {
                availableConversionTypes = []
            }
        }
    }

    @objc dynamic var availableConversionTypes = [NewRowValueTypeConversion]() {
        didSet {
            customTypeConverter = availableConversionTypes.first
        }
    }

    @objc dynamic var customTypeConverter: NewRowValueTypeConversion? {
        didSet {
            if customTypeConverter != availableConversionTypes.first, let newType = customTypeConverter, case .data(let data) = newValueType {

                newValueType = .data(NewRowValueTypeConversion.convert(data: data, with: newType))
            }
        }
    }

    @objc dynamic var text = "" {

        didSet {
            switch newValueType {
            case .data(let dat):
                if dat.type != .null && text != dat.forEditing {
                    newValueType = .data(.text(text))
                    textColor = .black
                }
            default:
                return
            }
        }
    }
    @objc dynamic var textColor = NSColor.black

    func refreshDisplayValue() {
        textColor = .lightGray
        switch newValueType {
        case .data(let data):
            if data.type == .null {
                text = NSLocalizedString("Value will be set to NULL", comment: "updating the value to null")
            } else {
                text = data.forEditing
                textColor = .black
            }
        case .defaultValue:
            text = NSLocalizedString("Value will be set to the default value", comment: "setting column to default value")

        case .file(let fileURL):
            let format = NSLocalizedString("Value will be set to contents of: %@", comment: "update when value will be set to file, arg with the path")
            text = String(format: format, fileURL.path)
        case .null:
            text = NSLocalizedString("Value will be set to NULL", comment: "updating the value to null")
        case .date:
            text = NSLocalizedString("Value will be set to CURRENT_DATE", comment: "updating the value to the current date")
        case .time:
            text = NSLocalizedString("Value will be set to CURRENT_TIME", comment: "update to time")
        case .timeStamp:
            text = NSLocalizedString("Value will be set to CURRENT_TIMESTAMP", comment: "Update to current time stamp")
        }

    }

    private func refreshTextEdit() {
        switch newValueType {
        case .data(let data):
            if data.type == .null {
                canEditTextually = false
            } else {
                canEditTextually = true
            }
        default:
            canEditTextually = false
        }

    }
}

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

            var conversionTypes = [NewRowValueTypeConversion]()
            conversionTypes.append(dataType)
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
