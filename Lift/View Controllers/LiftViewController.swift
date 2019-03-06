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

    @objc dynamic var windowController: LiftWindowController? {
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

    @objc dynamic weak var selectedColumn: Column?

    @objc dynamic var isEditingEnabled = false

    override func viewDidLoad() {
        NotificationCenter.default.addObserver(self, selector: #selector(selectedTableChanged), name: LiftWindowController.selectedTableChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(selectedColumnChanged), name: LiftWindowController.selectedColumnChanged, object: nil)

        super.viewDidLoad()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if windowController?.selectedTable != selectedTable {
            selectedTable = windowController?.selectedTable
        }

    }

    @objc public func selectedTableChanged(_ notification: Notification) {
        if windowController == nil && (notification.object as? LiftWindowController)?.document === document {
            selectedTable = (notification.object as? LiftWindowController)?.selectedTable
        } else if windowController == (notification.object as? LiftWindowController) {
            selectedTable = windowController?.selectedTable
        }
    }

    @objc public func selectedColumnChanged(_ notification: Notification) {
        if windowController == nil && (notification.object as? LiftWindowController)?.document === document {
            selectedColumn = (notification.object as? LiftWindowController)?.selectedColumn
        } else if windowController == (notification.object as? LiftWindowController) {
            selectedColumn = windowController?.selectedColumn
        }
    }

    override var representedObject: Any? {
        didSet {
            document = representedObject as? LiftDocument
        }
    }
}
