//
//  SQLiteExportOptions.swift
//  Yield
//
//  Created by Carl Wieland on 5/5/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation


class SQLiteExportOptions: NSObject {

    @objc dynamic var exportTriggers: Bool = false

    @objc dynamic var maintainRowID: Bool = true

}
