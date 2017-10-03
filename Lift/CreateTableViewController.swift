//
//  CreateTableViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class CreateTableViewController: NSViewController {
    @objc dynamic var table = TableDefinition()

    var document: LiftDocument {
        return representedObject as! LiftDocument
    }

    @objc dynamic var databases: [String] {
        return document.database.allDatabases.map( { $0.name })
    }
    
}
