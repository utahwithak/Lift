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

    @IBAction func doAction(_ sender: NSButton) {

        let mainStoryboard = NSStoryboard(name: .main, bundle: .main)
        guard let waitingView = mainStoryboard.instantiateController(withIdentifier: "statementWaitingView") as? StatementWaitingViewController else {
            return
        }

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
                    try? db.releaseSavepoint(named: "alterTable")

                    throw error

                }

                return true
            })
        } else {
            statement = .statement(viewDefinition.createStatement)
        }

        waitingView.operation = statement
        waitingView.representedObject = representedObject

        presentAsSheet(waitingView)
    }

    @IBAction func addNewColumn(sender: Any) {
        let count = viewDefinition.columns.count
        viewDefinition.columns.append(ViewColumn(name: "Column \( count + 1)"))
    }

}

extension CreateViewViewController: StatementWaitingViewDelegate {
    func waitingView(_ view: StatementWaitingViewController, finishedSuccessfully: Bool) {
        dismiss(view)

        if finishedSuccessfully {
            dismiss(self)
            document?.database.refresh()
        }
    }
}

class CreateViewArrayController: NSArrayController {
}
