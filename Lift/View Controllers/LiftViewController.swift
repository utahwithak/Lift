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

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(LiftWindowController.selectedTable) {
            selectedTable = (object as? LiftWindowController)?.selectedTable
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }


    override var representedObject: Any? {
        didSet {

            if let documentController = windowController {
                documentController.addObserver(self, forKeyPath: #keyPath(LiftWindowController.selectedTable), options: [], context: nil)
            }
        }
    }
}
