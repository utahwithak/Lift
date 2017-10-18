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

    @objc dynamic weak var selectedTable: Table? {
        didSet {
            window?.title = selectedTable?.name ?? document?.displayName ?? ""
        }
    }
    @IBAction func changeSplitViewPanels(_ sender: Any) {
        guard let splitView = contentViewController as? LiftMainSplitViewController else {
            return
        }

        splitView.setLocation(.left, collapsed: !panelSegmentedControl.isSelected(forSegment: 0))
        splitView.setLocation(.bottom, collapsed: !panelSegmentedControl.isSelected(forSegment: 1))
        splitView.setLocation(.right, collapsed: !panelSegmentedControl.isSelected(forSegment: 2))

    }

    override func windowDidLoad() {

        window?.titleVisibility = .hidden
        attachDetachSegmentedControl.setEnabled(false, forSegment: 1)

        if let splitView = contentViewController as? LiftMainSplitViewController {
            splitView.splitDelegate = self
        }
    }

    @IBAction func unwindFromAttachingDatabase(_ sender: Any? ) {

    }

    @IBAction override func newWindowForTab(_ sender: Any?) {
        guard let document = document as? LiftDocument else {
            return
        }

        guard let otherWindowController = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as? NSWindowController, let window = otherWindowController.window else {
            return
        }
        self.window?.addTabbedWindow(window, ordered: .above)
        document.addWindowController(otherWindowController)

        otherWindowController.window?.orderFront(self.window)
        otherWindowController.window?.makeKey()


    }

    @IBAction func refreshDatabase( _ sender: NSSegmentedControl) {
        (document as? LiftDocument)?.refresh()
    }

    @IBAction func switchMainEditor(_ sender: NSSegmentedControl) {

        guard let splitView = contentViewController as? LiftMainSplitViewController, let tabController = splitView.mainEditor else {
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

    @IBAction func loadExtension(_ sender: Any) {
        guard let database = (document as? LiftDocument)?.database else {
            return
        }

        let openFile = NSOpenPanel()
        openFile.canChooseDirectories = false
        openFile.canChooseFiles = true
        let auxView = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 22))
        let label = NSTextField(labelWithString: "Entry Point:")
        auxView.addSubview(label)
        let field = NSTextField(frame: NSRect(x: label.frame.width, y: 0, width: 450, height: 22))
        auxView.addSubview(field)

        openFile.accessoryView = auxView

        
        if openFile.runModal() == .OK, let url = openFile.url {
            do {
                try database.loadExtension(at: url, entryPoint: field.stringValue.isEmpty ? nil : field.stringValue )
            } catch {
                print("Failed to attach db:\(error)")
                presentError(error)
            }
        }
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

extension LiftWindowController: LiftSplitViewDelegate {
    func didUpdateState(for location: SplitViewLocation, collapsed: Bool) {

        switch location {
        case .left:
            panelSegmentedControl.setSelected(!collapsed, forSegment: 0)
        case .bottom:
            panelSegmentedControl.setSelected(!collapsed, forSegment: 1)
        case .right:
            panelSegmentedControl.setSelected(!collapsed, forSegment: 2)
        }

    }
}

