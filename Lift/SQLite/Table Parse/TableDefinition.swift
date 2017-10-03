//
//  TableDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class TableDefinition: NSObject {
    @objc dynamic public var isTemp = false {
        didSet {
            if isTemp {
                databaseName = SQLiteName(rawValue: "temp")
            } else {
                databaseName = nil
            }
        }
    }
    @objc dynamic public var withoutRowID = false
    @objc dynamic public var databaseName: SQLiteName? {
        didSet {
            if isTemp && databaseName?.rawValue != "temp" {
                isTemp = false
            }
        }
    }
    @objc dynamic public var tableName = SQLiteName(rawValue: "")

    
    @objc dynamic public var columns = [ColumnDefinition]()

     @objc dynamic public var tableConstraints = [TableConstraint]()

}
