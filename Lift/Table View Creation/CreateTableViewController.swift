//
//  CreateTableViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class CreateTableViewController: LiftViewController {
    @objc dynamic var table = TableDefinition()


    @objc dynamic var databases: [String] {
        return document.database.allDatabases.map( { $0.name })
    }
    
}
