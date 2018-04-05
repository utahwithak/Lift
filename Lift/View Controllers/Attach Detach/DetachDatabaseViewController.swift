//
//  DetatchDatabaseViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/10/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class DetachDatabaseViewController: LiftViewController {

    override var representedObject: Any? {
        didSet {

            willChangeValue(forKey: #keyPath(DetachDatabaseViewController.possibleDatabases))
            selectedName = document?.database.attachedDatabases.first?.name
            didChangeValue(forKey: #keyPath(DetachDatabaseViewController.possibleDatabases))

        }
    }

    @objc dynamic var possibleDatabases: [String] {
        return document?.database.attachedDatabases.map({ $0.name }) ?? []
    }

    @objc dynamic var selectedName: String?

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let waitingView = segue.destinationController as? StatementWaitingViewController {

            let operation: () throws -> Bool = { [weak self] in
                guard let database = self?.document?.database, let name = self?.selectedName else {
                    print("No database to attach to!")
                    return false
                }

                return try database.detachDatabase(named: name)
            }

            waitingView.delegate = self

            waitingView.operation = .customCall(operation)

            waitingView.representedObject = representedObject
        }
    }

}
extension DetachDatabaseViewController: StatementWaitingViewDelegate {
    func waitingView(_ view: StatementWaitingViewController, finishedSuccessfully: Bool) {
        dismissViewController(view)

        if finishedSuccessfully {
            dismissViewController(self)
        }
    }
}
