//
//  TableDefinition.swift
//  Lift
//
//  Created by Carl Wieland on 9/28/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class TableDefinition {
    public var isTemp = false
    public var withoutRowID = false
    public var databaseName: SQLiteName?
    public var tableName = SQLiteName(rawValue: "")

    
    public var columns = [ColumnDefinition]()

    public var tableConstraints = [TableConstraint]()

}
