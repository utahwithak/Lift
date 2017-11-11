//
//  SQLiteExportOptions.swift
//  Yield
//
//  Created by Carl Wieland on 5/5/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation

enum SQLiteExportType: Int {
    case database = 0
    case dumpfile

}

class SQLiteExportOptions: NSObject {

    var exportType = SQLiteExportType.database {
        didSet {
            canMaintainRowID = exportType == .dumpfile
        }
    }

    @objc dynamic var canMaintainRowID: Bool = false

    @objc dynamic var maintainRowID: Bool = true

}
