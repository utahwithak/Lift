//
//  LiftWindowController.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

extension  NSStoryboard.SceneIdentifier {
    static let attachDatabase = NSStoryboard.SceneIdentifier("attachDatabase")
    static let detachDatabase =  NSStoryboard.SceneIdentifier("detachDatabase")
}

class LiftWindowController: NSWindowController {

    @IBOutlet weak var panelSegmentedControl: NSSegmentedControl!

    @IBOutlet weak var attachDetachSegmentedControl: NSSegmentedControl!

    override func windowDidLoad() {
        window?.titleVisibility = .hidden
        attachDetachSegmentedControl.setEnabled(false, forSegment: 1)
    }

    @IBAction func unwindFromAttachingDatabase(_ sender: Any? ) {

    }

    @IBAction func switchMainEditor(_ sender: NSSegmentedControl) {

        guard let splitView = contentViewController as? LiftSplitViewController, let tabController = splitView.mainEditor else {
            return
        }

        tabController.switchMainView(to: sender.selectedSegment == 0 ? .table : .canvas)
    }

    @IBAction func showAttachDetach(_ sender: NSSegmentedControl) {
        let identifier: NSStoryboard.SceneIdentifier

        switch sender.selectedSegment {
        case 0:
            identifier = .attachDatabase
        default:
            guard !((document as? LiftDocument)?.database.attachedDatabases.isEmpty ?? false) else {
                return
            }
            identifier = .detachDatabase
        }

        if let viewcontroller = storyboard?.instantiateController(withIdentifier: identifier) as? LiftViewController {
            viewcontroller.representedObject = document
            contentViewController?.presentViewControllerAsSheet(viewcontroller)
        }

    }


    @IBAction func reloadDatabase(_ sender: NSButton) {
        
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        (segue.destinationController as? NSViewController)?.representedObject = document
    }

    override var document: AnyObject? {
        didSet {
            contentViewController?.representedObject = document

            if let document = document as? LiftDocument {
                NotificationCenter.default.addObserver(self, selector: #selector(attachedDatabasesChanged), name: .AttachedDatabasesChanged, object: document.database)
            }
        }
    }

    override var contentViewController: NSViewController? {
        didSet {
            contentViewController?.representedObject = document
        }
    }

    @objc private func attachedDatabasesChanged(_ notification: Notification) {
        guard let database = notification.object as? Database else {
            return
        }
        attachDetachSegmentedControl.setEnabled(!database.attachedDatabases.isEmpty, forSegment: 1)

    }
}
