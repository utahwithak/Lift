//
//  ForiegnKeyConnection.swift
//  Lift
//
//  Created by Carl Wieland on 10/10/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct ForeignKeyConnection {
    let id: Int
    //id|seq|table|from|to|on_update|on_delete|match
    let fromTable: String
    let fromColumns: [String]

    let toTable: String
    let toColumns: [String]?

    var referencesPrimaryKeys: Bool {
        return toColumns == nil
    }

    func hasToColumn(named:String) -> Bool {
        return toColumns?.contains(named) ?? false
    }
}

struct ForeignKeyJump {
    let connection: ForeignKeyConnection
    let source: DataProvider
}
