//
//  File.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct SQLiteError: Error {
    let code: Int32

    var localizedDescription: String {
        return String(cString: sqlite3_errstr(code))
    }
}
