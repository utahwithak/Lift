//
//  DatabaseLoadErrorViewController.swift
//  Lift
//
//  Created by Carl Wieland on 3/26/19.
//  Copyright © 2019 Datum Apps. All rights reserved.
//

import Cocoa

class DatabaseLoadErrorViewController: NSViewController {

    class TableError: NSObject {
        @objc dynamic let name: String
        @objc dynamic let errorDescription: String
        init(name: String, error: Error) {
            self.name = name
            self.errorDescription = error.localizedDescription
        }
    }

    var rawErrors: [String: Error]?

    @objc dynamic public private(set) var errorObjects = [TableError]()

    override func viewDidLoad() {
        errorObjects = rawErrors?.map({ (key, value) -> TableError in
            return TableError(name: key, error: value)
        }) ?? []
    }
}
