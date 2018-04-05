//
//  XLSXExportOptions.swift
//  Yield
//
//  Created by Carl Wieland on 4/18/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation

class XLSXExportOptions: ExportOptions {
    @objc dynamic var exportNULLValues: Bool = false
    @objc dynamic var includeColumnNames: Bool = true
    @objc dynamic var exportBlobData: Bool = false
}
