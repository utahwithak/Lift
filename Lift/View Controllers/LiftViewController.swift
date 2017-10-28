//
//  LiftViewControllerBase.swift
//  Lift
//
//  Created by Carl Wieland on 10/4/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa
class LiftViewController: NSViewController {
    var document: LiftDocument? {
        return representedObject as? LiftDocument
    }

    var windowController: LiftWindowController? {
        return view.window?.windowController as? LiftWindowController
    }

    @objc dynamic weak var selectedTable: DataProvider?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(selectedTableChanged), name: .selectedTableChanged, object: nil)
    }

    @objc private func selectedTableChanged(_ notification: Notification) {
        if windowController == (notification.object as? LiftWindowController) {
            selectedTable = windowController?.selectedTable
        }
    }

    override var representedObject: Any? {
        didSet {


        }
    }
}
