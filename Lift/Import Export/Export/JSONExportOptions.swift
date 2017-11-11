//
//  JSONExportOptions.swift
//  Yield
//
//  Created by Carl Wieland on 5/3/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation

class JSONExportOptions: ExportOptions {

    @objc dynamic var useNullLiterals: Bool = true

    @objc dynamic var separateFilePerTable: Bool = false

    @objc dynamic var rowName: String = "data"

    @objc dynamic var rowsAsDictionaries: Bool = true

    @objc dynamic var includeProperties: Bool = true

    @objc dynamic var prettyPrint: Bool = false


}
