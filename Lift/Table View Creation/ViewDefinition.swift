//
//  ViewDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 10/4/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class ViewDefinition: NSObject {
    @objc dynamic public var isTemp = false {
        didSet {
            if isTemp && (databaseName != nil || databaseName?.rawValue != "temp"){
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
    @objc dynamic public var name = SQLiteName(rawValue: "")


    @objc dynamic public var columns = [SQLiteName]() 
}
