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

        var index: Int {
            switch self {
            case .data:
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
                 newValueType = .data(currentValue)
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
        }
    }

    var currentValue: SQLiteData!

    @objc dynamic var canEditTextually: Bool = false

    var newValueType: NewValueType = .null {
        didSet {
            refreshDisplayValue()
        }
    }

    @objc dynamic var displayValue = NSAttributedString()

    func refreshDisplayValue() {
        var stringValue = ""
        var attributes: [NSAttributedStringKey: Any]?

        switch newValueType {
        case .data(let data):
            stringValue = data.forWhereClause
        case .file(let fileURL):
            let format = NSLocalizedString("Value will be set to contents of: %@", comment: "update when value will be set to file, arg with the path")
            stringValue = String(format: format, fileURL.path)
            attributes = [ .foregroundColor: NSColor.lightGray]
        case .null:
            stringValue = NSLocalizedString("Value will be set to NULL", comment: "updating the value to null")
            attributes = [ .foregroundColor: NSColor.lightGray]
        case .date:
            stringValue = NSLocalizedString("Value will be set to CURRENT_DATE", comment:"updating the value to the current date")
            attributes = [ .foregroundColor: NSColor.lightGray]
        case .time:
            stringValue = NSLocalizedString("Value will be set to CURRENT_TIME", comment:"update to time")
            attributes = [ .foregroundColor: NSColor.lightGray]
        case .timeStamp:
            stringValue = NSLocalizedString("Value will be set to CURRENT_TIMESTAMP", comment:"Update to current time stamp")
            attributes = [ .foregroundColor: NSColor.lightGray]
        }

        displayValue = NSAttributedString(string: stringValue, attributes: attributes)
    }
}
