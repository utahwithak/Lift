//
//  EditRowData.swift
//  Lift
//
//  Created by Carl Wieland on 3/7/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class EditRowData: NSObject {

    let originalData: SQLiteData

    @objc dynamic let name: String

    @objc dynamic let newValue = NewRowValue()

    @objc dynamic public private(set) var typeDescription = ""


    @objc dynamic var supportsMultipleTypes: Bool {
        return availableTypes.count > 1
    }

    var availableTypes = [SQLiteDataType]()

    init(data: SQLiteData, column: String) {
        name = column
        originalData = data
        
        newValue.newValueType = .data(data)
        newValue.currentValue = data
    }
}
