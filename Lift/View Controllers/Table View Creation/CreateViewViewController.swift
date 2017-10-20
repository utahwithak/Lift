//
//  CreateViewViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/4/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class CreateViewViewController: LiftViewController {

    @objc dynamic var viewDefinition = ViewDefinition()
    

    @objc dynamic var databases: [String] {
        return document?.database.allDatabases.map( { $0.name }) ?? []
    }

    @IBOutlet weak var tableView: NSTableView!

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let waitingView = segue.destinationController as? StatementWaitingViewController {
            waitingView.delegate = self
            waitingView.operation = .statement(viewDefinition.createStatement)
            waitingView.representedObject = representedObject

        }
    }

}

extension CreateViewViewController: StatementWaitingViewDelegate {
    func waitingView(_ view: StatementWaitingViewController, finishedSuccessfully: Bool) {
        dismissViewController(view)

        if finishedSuccessfully {
            dismissViewController(self)
            document?.database.refresh()
        }
    }
}


class CreateViewArrayController: NSArrayController {
     // overridden to add a new object to the content objects and to the arranged objects
    override func newObject() -> Any {
        let count = (arrangedObjects as? NSArray)?.count
        return SQLiteName(rawValue:"Column \( (count ?? 0) + 1)")
    }
}

