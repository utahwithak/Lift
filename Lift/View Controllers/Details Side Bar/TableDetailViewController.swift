//
//  TableDetailViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/26/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TableDetailViewController: LiftViewController {

    @IBOutlet weak var contentTabView: NSTabView!

    @IBOutlet weak var sqlViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var sqlTextView: SQLiteTextView!

    override var selectedTable: DataProvider? {
        didSet {
            if selectedTable == nil {
                contentTabView.selectTabViewItem(at: 0)
            } else {
                contentTabView.selectTabViewItem(at: 1)
                sqlTextView.refresh()

            }
        }
    }

    @IBAction func toggleSQLView(_ sender: NSButton) {

        if sender.state == .on {
            sqlViewHeightConstraint.animator().constant = 150
        } else {
            sqlViewHeightConstraint.animator().constant = 0
        }

    }
}
