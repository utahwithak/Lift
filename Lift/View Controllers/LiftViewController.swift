//
//  LiftViewControllerBase.swift
//  Lift
//
//  Created by Carl Wieland on 10/4/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa
class LiftViewController: NSViewController {

    @objc dynamic var document: LiftDocument?

    var windowController: LiftWindowController? {
        return view.window?.windowController as? LiftWindowController
    }

    @objc dynamic weak var selectedTable: DataProvider? {
        didSet {
            guard let provider = selectedTable else {
                isEditingEnabled = false
                return
            }

            isEditingEnabled = provider.type == "table" && !provider.name.hasPrefix("sqlite")
        }
    }

    @objc dynamic var isEditingEnabled = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @objc public func selectedTableChanged(_ notification: Notification) {
        if windowController == nil && (notification.object as? LiftWindowController)?.document === document {
            selectedTable = (notification.object as? LiftWindowController)?.selectedTable
        } else if windowController == (notification.object as? LiftWindowController) {
            selectedTable = windowController?.selectedTable
        }
    }

    override var representedObject: Any? {
        didSet {
            document = representedObject as? LiftDocument

            NotificationCenter.default.addObserver(self, selector: #selector(selectedTableChanged), name: .selectedTableChanged, object: nil)

        }
    }
}
