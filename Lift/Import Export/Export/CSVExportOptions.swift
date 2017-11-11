//
//  CSVExportOptions.swift
//  Yield
//
//  Created by Carl Wieland on 4/18/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation

class CSVExportOptions: ExportOptions {
    // CSV Section
    @objc dynamic var separator: String = ","
    @objc dynamic var shouldQuoteFields: Bool = true
    @objc dynamic var lineEnding = "\n"
    @objc dynamic var includeColumnNames: Bool = true

}
