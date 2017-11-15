//
//  ExportOptions.swift
//  Yield
//
//  Created by Carl Wieland on 5/3/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation

class ExportOptions: NSObject, Codable {
    @objc dynamic var nullPlaceHolder = ""
    @objc dynamic var exportRawBlobData: Bool = false
    @objc dynamic var blobDataPlaceHolder = "<Blob>"
}
