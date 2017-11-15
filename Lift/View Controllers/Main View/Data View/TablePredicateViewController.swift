//
//  TablePredicateViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/14/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TablePredicateViewController: LiftViewController {

    @IBOutlet weak var tableView: NSTableView!

    @IBOutlet var columnNameController: NSArrayController!
    override var selectedTable: DataProvider? {
        didSet {
            columnNames = selectedTable?.columns.map { $0.name } ?? []
        }
    }

    @objc dynamic var columnNames = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true

    }


    @IBAction func addSimpleRow(_ sender: Any) {

    }

    @IBAction func addCompound(_ sender: Any) {

    }

}
