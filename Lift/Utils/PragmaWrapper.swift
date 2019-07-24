//
//  PragmaWrapper.swift
//  Lift
//
//  Created by Carl Wieland on 7/2/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Foundation

@propertyWrapper
struct PragmaValue<T> {
    var connection: sqlite3?
    let pragma: String
    let defaultValue: T

    init(_ pragma: String, defaultValue: T) {
        self.pragma = pragma
        self.defaultValue = defaultValue
    }

    var wrappedValue: T? {
        get {
            guard let connection = connection else {
                return nil
            }
            do {
                let query = try Query(connection: connection, query: "PRAGMA \(pragma)")
                let results = try query.allRows()
                return results.first?.first?.toAny as? T
            } catch {
                print("Failed to get pragma for key:\(pragma)... \(error)")
            }
            return nil
        }
        set {
            _ = newValue
        }
    }
}
