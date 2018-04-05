//
//  AttachDatabaseViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/10/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class AttachDatabaseViewController: LiftViewController {

    @IBOutlet weak var destinationView: DestinationView!

    @objc dynamic var name: String = ""
    @objc dynamic var path: URL? {
        didSet {
            if name.isEmpty || name == oldValue?.deletingPathExtension().lastPathComponent {
                name = path?.deletingPathExtension().lastPathComponent ?? ""
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        destinationView.delegate = self
    }

    @IBAction func choosePath(_ sender: Any) {
        let openPanel = NSOpenPanel()

        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false

        openPanel.runModal()
        path = openPanel.url

    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let waitingView = segue.destinationController as? StatementWaitingViewController {

            let operation: () throws -> Bool = { [weak self] in
                guard let database = self?.document?.database, let path = self?.path, let name = self?.name else {
                    print("No database to attach to!")
                    return false
                }

                SQLiteDocumentPresenter.addPresenters(for: path)

                return try database.attachDatabase(at: path, with: name)
            }

            waitingView.delegate = self

            waitingView.operation = .customCall(operation)

            waitingView.representedObject = representedObject
        }
    }

}

extension AttachDatabaseViewController: DestinationViewDelegate {

    func processURLs(_ urls: [URL], center: NSPoint) {
        path = urls.first
    }
}

extension AttachDatabaseViewController: StatementWaitingViewDelegate {
    func waitingView(_ view: StatementWaitingViewController, finishedSuccessfully: Bool) {
        dismissViewController(view)

        if finishedSuccessfully {
            dismissViewController(self)
        }
    }
}
