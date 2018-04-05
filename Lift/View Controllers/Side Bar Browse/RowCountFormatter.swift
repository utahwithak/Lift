//
//  RowCountFormatter.swift
//  Lift
//
//  Created by Carl Wieland on 10/8/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class RowCountFormatter: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let rowCount = value as? Int else {
            return ""
        }

        if rowCount == 1 {
            return NSLocalizedString("1 row", comment: "Subtitle for single row")
        } else {
            let format = NSLocalizedString("%@ rows", comment: "subititle for lots of rows. %@ repaced with a formatted number")

            return String(format: format, RowCountFormatter.numberFormatter.string(for: rowCount) ?? "Lots of")
        }
    }

    static let numberFormatter: NumberFormatter = {
        var formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

}
