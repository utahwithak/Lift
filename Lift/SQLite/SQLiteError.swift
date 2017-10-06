//
//  File.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

struct SQLiteError: LocalizedError {
    let code: Int32

    let message: String?

    let sql: String?

    init(connection: sqlite3?, code: Int32, sql: String? = nil) {
        if let connection = connection, let rawMessage = sqlite3_errmsg(connection) {
            message = String(cString: rawMessage)
        } else {
            message = nil
        }

        self.code = code
        self.sql = sql

    }

    var errorDescription: String? {
        return message ?? String(cString: sqlite3_errstr(code))
    }

    var localizedDescription: String {
        if let message = message {
            return message + " (code: \(code))"
        }
        return errorDescription ?? "Code: \(code)"
    }

    var failureReason: String {
        return sql ?? "Unknown SQL"
    }
}
