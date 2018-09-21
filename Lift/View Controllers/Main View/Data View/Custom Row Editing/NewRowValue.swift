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
                    textColor = .textColor
                }
            default:
                return
            }
        }
    }
    @objc dynamic var textColor = NSColor.textColor

    func refreshDisplayValue() {
        textColor = .disabledControlTextColor
        switch newValueType {
        case .data(let data):
            if data.type == .null {
                text = NSLocalizedString("Value will be set to NULL", comment: "updating the value to null")
            } else {
                text = data.forEditing
                textColor = .textColor
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
