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

    public var dropQualifiedName: String?

    @IBOutlet weak var createViewButton: NSButton!
    @objc dynamic var databases: [String] {
        return document?.database.allDatabases.map({ $0.name }) ?? []
    }

    override func viewDidLoad() {
        if dropQualifiedName != nil {
            createViewButton.title = NSLocalizedString("Update View", comment: "Update view button title when we're modifing an existing view")
        }
    }
    @IBOutlet weak var tableView: NSTableView!

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let waitingView = segue.destinationController as? StatementWaitingViewController {
            waitingView.delegate = self
            let statement: OperationType
            if let dropFirst = dropQualifiedName {
                statement = .customCall({ () throws -> Bool in
                    guard let db = self.document?.database else {
                        return false
                    }
                    try db.beginSavepoint(named: "alterTable")

                    defer {
                        try? db.releaseSavepoint(named: "alterTable")
                    }

                    do {

                        try db.execute(statement: "DROP VIEW \(dropFirst)")
                        try db.execute(statement: self.viewDefinition.createStatement)
                    } catch {
                        try? db.rollbackSavepoint(named: "alterTable")
                        throw error

                    }

                    return true
                })
            } else {
                statement = .statement(viewDefinition.createStatement)
            }

            waitingView.operation = statement
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
        return SQLiteName(rawValue: "Column \( (count ?? 0) + 1)")
    }
}
