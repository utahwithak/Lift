//
//  EditRowData.swift
//  Lift
//
//  Created by Carl Wieland on 3/7/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class EditRowData: NSObject {

    @objc dynamic let name: String

    @objc dynamic let newValue = NewRowValue()

    @objc dynamic public private(set) var typeDescription = ""

    @objc dynamic var supportsMultipleTypes: Bool {
        return availableTypes.count > 1
    }

    var availableTypes = [SQLiteDataType]()

    init(data: SQLiteData, column: String) {
        name = column

        newValue.newValueType = .data(data)
        newValue.refreshDisplayValue()
        newValue.currentValue = data
    }
    init(column: String) {
        name = column
        newValue.newValueType = .defaultValue
        newValue.refreshDisplayValue()
        newValue.currentValue = .null
    }

    var hasChanges: Bool {
        switch newValue.newValueType {
        case .data(let data):
            return data != newValue.currentValue
        case .defaultValue:
            return false
        default:
            return true
        }
    }

    var useDefaultValue: Bool {
        switch newValue.newValueType {
        case .defaultValue:
            return true
        default:
            return false
        }
    }

    func valueString(index: Int) -> String? {
        switch newValue.newValueType {
        case .date:
            return "CURRENT_DATE"
        case .defaultValue:
            return nil
        case .file(_), .data(_), .null:
            return "$\(index)" // bind an argument
        case .time:
            return "CURRENT_TIME"
        case .timeStamp:
            return "CURRENT_TIMESTAMP"

        }
    }

    func argument() -> SQLiteData? {
        switch newValue.newValueType {
        case .date:
            return nil
        case .defaultValue:
            return nil
        case .null:
            return SQLiteData.null
        case .file(let url):
            guard let data = try? Data(contentsOf: url, options: Data.ReadingOptions.mappedIfSafe) else {
                return .null
            }
            return .blob(data)
        case .time:
            return nil
        case .timeStamp:
            return nil
        case .data(let data):
            return data
        }
    }

}
