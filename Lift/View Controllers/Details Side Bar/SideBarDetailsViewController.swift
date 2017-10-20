//
//  SideBarDetailsViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/5/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class SideBarDetailsViewController: LiftViewController {

    @IBOutlet var sqlView: SQLiteTextView!
    override func viewDidLoad() {
        sqlView.setup()
        sqlView.isEditable = false
    }

    override var selectedTable: DataProvider? {
        didSet {
            sqlView.string = selectedTable?.sql ?? ""
            sqlView.refresh()
        }
    }

}
