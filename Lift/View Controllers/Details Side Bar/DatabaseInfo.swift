//
//  DatabaseInfo.swift
//  Lift
//
//  Created by Carl Wieland on 7/2/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

class DatabaseInfo {

    @PragmaValue("user_version", defaultValue: nil)
    var version: String?

    let database: Database

    init(database: Database) {
        self.database = database
        version = "!@"

    }

}
