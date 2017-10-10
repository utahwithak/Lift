//
//  ForiegnKeyConnection.swift
//  Lift
//
//  Created by Carl Wieland on 10/10/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct ForeignKeyConnection {

    //id|seq|table|from|to|on_update|on_delete|match
    let fromTable: String
    let fromColumns: [String]

    let toTable: String
    let toColumns: [String]
}
