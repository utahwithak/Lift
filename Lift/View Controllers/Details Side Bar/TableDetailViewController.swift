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

    @IBOutlet weak var alterButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        sqlTextView.setup()
        let trackingArea = NSTrackingArea(rect: alterButton.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: view, userInfo: nil)
        alterButton.addTrackingArea(trackingArea)
        alterButton.animator().alphaValue = 0
    }
    
    override func mouseEntered(with event: NSEvent) {
        alterButton.animator().alphaValue = 1
        super.mouseEntered(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        alterButton.animator().alphaValue = 0
        super.mouseExited(with: event)
    }
    override var representedObject: Any? {
        didSet {
            if let document = document {
                sqlTextView?.setIdentifiers(document.keywords())
            }
        }
    }

    override var selectedTable: DataProvider? {
        didSet {
            if selectedTable == nil {
                contentTabView.selectTabViewItem(at: 0)
            } else {
                contentTabView.selectTabViewItem(at: 1)
                if let document = document {
                    sqlTextView.setIdentifiers(document.keywords())
                }
            }
            sqlTextView.string = selectedTable?.sql ?? ""

            sqlTextView.setIdentifiers(document?.keywords() ?? [] )
            sqlTextView.refresh()

        }
    }

    @IBAction func toggleSQLView(_ sender: NSButton) {

        if sender.state == .on {
            sqlTextView.enclosingScrollView?.animator().isHidden = false
        } else {
            sqlTextView.enclosingScrollView?.animator().isHidden = true
        }

    }
}