//
//  LiftWindowController.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

extension NSStoryboard.SceneIdentifier {
    static let attachDatabase = "attachDatabase"
    static let detachDatabase =  "detachDatabase"
}

class LiftWindowController: NSWindowController {

    static let selectedTableChanged = Notification.Name("selectedTableChanged")
    static let selectedColumnChanged = Notification.Name("selectedTableChanged")

    @IBOutlet weak var viewTypeSegmentedControl: NSSegmentedControl!
    @IBOutlet weak var panelSegmentedControl: NSSegmentedControl!

    @IBOutlet weak var attachDetachSegmentedControl: NSSegmentedControl!

    @IBOutlet weak var autocommitSegmentedControl: NSSegmentedCell!

    @objc dynamic var refreshOnWindowActivate = false

    deinit {
        NSUserDefaultsController.shared.removeObserver(self, forKeyPath: "values.refreshOnWindowActivate")
    }

    @objc dynamic weak var selectedTable: DataProvider? {
        didSet {
            window?.title = selectedTable?.name ?? document?.displayName ?? ""
            NotificationCenter.default.post(name: LiftWindowController.selectedTableChanged, object: self)
        }
    }

    @objc dynamic weak var selectedColumn: Column? {
        didSet {
            NotificationCenter.default.post(name: LiftWindowController.selectedColumnChanged, object: self)
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

    @IBAction func saveDocument(_ sender: Any) {
        document?.saveDocument(sender)
    }

    var documentDatabase: Database? {
        return (document as? LiftDocument)?.database
    }

    override func windowDidLoad() {
        window?.delegate = self

        window?.titleVisibility = .hidden
        attachDetachSegmentedControl.setEnabled(false, forSegment: 1)

        if let splitView = contentViewController as? LiftMainSplitViewController {
            splitView.splitDelegate = self
        }

        window?.registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])

        mainEditor?.sideBarViewController = sideDetails
        mainEditor?.bottomBarContainer = bottomContainer

        NSUserDefaultsController.shared.addObserver(self, forKeyPath: "values.refreshOnWindowActivate", options: [.initial, .new], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "values.refreshOnWindowActivate" {
            refreshOnWindowActivate = UserDefaults.standard.bool(forKey: "refreshOnWindowActivate")
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    @IBAction override func newWindowForTab(_ sender: Any?) {
        guard window?.sheets.isEmpty ?? false else {
            nextResponder?.newWindowForTab(sender)
            return
        }
        guard let document = document as? LiftDocument else {
            return
        }

        guard let otherWindowController = storyboard?.instantiateController(withIdentifier: "Document Window Controller") as? NSWindowController, let window = otherWindowController.window else {
            return
        }
        self.window?.addTabbedWindow(window, ordered: .above)
        document.addWindowController(otherWindowController)

        otherWindowController.window?.orderFront(self.window)
        otherWindowController.window?.makeKey()

    }

    func toggleBottomBar() {
        guard let splitView = contentViewController as? LiftMainSplitViewController else {
            return
        }
        splitView.setLocation(.bottom, collapsed: !splitView.isBottomCollapsed)

    }

    func showBottomBar() {
        guard let splitView = contentViewController as? LiftMainSplitViewController else {
            return
        }

        splitView.setLocation(.bottom, collapsed: false)

    }

    func hideBottomBar() {
        guard let splitView = contentViewController as? LiftMainSplitViewController else {
            return
        }

        splitView.setLocation(.bottom, collapsed: true)

    }

    @IBAction func refreshDatabase( _ sender: NSSegmentedControl) {
        (document as? LiftDocument)?.refresh()
    }

    @IBAction func toggleAutoCommitStatus(_ sender: NSSegmentedControl) {
        guard let database = (document as? LiftDocument)?.database else {
            return
        }
        defer {
            database.refreshAutoCommit()
        }
        do {
            switch database.autocommitStatus {
            case .inTransaction:
                try database.endTransaction()
            case .autocommit:
                try database.beginTransaction()
            }
        } catch {
            presentError(error)
        }

    }

    private var mainEditor: LiftMainEditorTabViewController? {
        guard let splitView = contentViewController as? LiftMainSplitViewController, let tabController = splitView.mainEditor else {
            return nil
        }
        return tabController
    }

    private var sideDetails: SideBarDetailsViewController? {
        return (contentViewController as? LiftMainSplitViewController)?.detailsViewController
    }

    private var bottomContainer: BottomEditorContainer? {
        return (contentViewController as? LiftMainSplitViewController)?.bottomEditorContainer
    }

    @IBAction func switchMainEditor(_ sender: NSSegmentedControl) {

        let view: MainEditorType
        switch sender.selectedSegment {
        case 0:
            view = .table
        case 1:
            view = .graph
        default:
            view = .query
        }
        showMainView(type: view)
    }

    public func showMainView(type: MainEditorType) {
        guard let tabController = mainEditor else {
            return
        }
        viewTypeSegmentedControl.selectedSegment = type.rawValue
        tabController.switchMainView(to: type)

    }

    public func showQueryView(with SQL: String) {
        guard let tabController = mainEditor else {
            return
        }
        viewTypeSegmentedControl.selectedSegment = 2
        tabController.switchMainView(to: .query)
        tabController.setQuerySQL(to: SQL)

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
            contentViewController?.presentAsSheet(viewcontroller)
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
            windowFrameAutosaveName = documentDatabase?.name ?? "Unknown"
            contentViewController?.representedObject = document
            NotificationCenter.default.addObserver(self, selector: #selector(attachedDatabasesChanged), name: .AttachedDatabasesChanged, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(autocommitStatusChanged), name: .AutocommitStatusChanged, object: nil)

        }
    }

    override var contentViewController: NSViewController? {
        didSet {
            contentViewController?.representedObject = document
        }
    }

    @objc private func autocommitStatusChanged(_ notification: Notification) {
        guard let database = notification.object as? Database, database === documentDatabase else {
            return
        }
        let image: NSImage?
        switch database.autocommitStatus {
        case .autocommit:
            image = NSImage(named: "branch")
        case .inTransaction:
            image = NSImage(named: "commit")
        }
        autocommitSegmentedControl.setImage(image, forSegment: 0)

    }

    @objc private func attachedDatabasesChanged(_ notification: Notification) {
        guard let database = notification.object as? Database, database == documentDatabase else {
            return
        }
        attachDetachSegmentedControl.setEnabled(!database.attachedDatabases.isEmpty, forSegment: 1)
    }

    @IBAction func showDatabaseLog( _ sender: Any) {
        guard let logViewController = storyboard?.instantiateController(withIdentifier: "logView") as? LogViewController else {
            return
        }
        logViewController.representedObject = document

        contentViewController?.presentAsSheet(logViewController)
    }

    @IBAction func checkDatabase( _ sender: Any) {

        guard let waitingView = storyboard?.instantiateController(withIdentifier: "statementWaitingView") as? StatementWaitingViewController else {
            return
        }

        let operation: () throws -> Bool = { [weak self] in
            guard let document = self?.document as? LiftDocument else {
                return true
            }

            let integrity = try document.checkDatabaseIntegrity()
            let fKey = try document.checkForeignKeys()

            let message: String
            if integrity && fKey {
                message = NSLocalizedString("Integrity and foreign key checks passed", comment: "message when both checks succeeded")
            } else {
                if !fKey && !integrity {
                    message = NSLocalizedString("Both integrity and foreign key checks failed", comment: "message when both checks Fail")
                } else if !fKey {
                    message = NSLocalizedString("Integrity check passed but and foreign key checks failed", comment: "message when integrity pass but fkey fails")
                } else {
                    message = NSLocalizedString("Foreign key checks passed but integrity check failed", comment: "message when fKey passes but integrity fails")
                }
            }
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Check Results", comment: "Results alert title")
                alert.informativeText = message
                alert.runModal()
            }

            return integrity && fKey

        }
        waitingView.delegate = self
        waitingView.operation = .customCall(operation)
        waitingView.representedObject = document
        contentViewController?.presentAsSheet(waitingView)
    }

    @IBAction func cleanDatabase( _ sender: Any) {

        guard let waitingView = storyboard?.instantiateController(withIdentifier: "statementWaitingView") as? StatementWaitingViewController else {
            return
        }

        let operation: () throws -> Bool = { [weak self] in
            try (self?.document as? LiftDocument)?.cleanDatabase()
            return true

        }
        waitingView.delegate = self
        waitingView.operation = .customCall(operation)
        waitingView.representedObject = document
        contentViewController?.presentAsSheet(waitingView)

    }

    @IBAction func showImportExport(_ sender: NSSegmentedControl) {
        let storyboard = NSStoryboard(name: "ImportExport", bundle: Bundle.main)
        switch sender.selectedSegment {
        case 0:

            let chooser = NSOpenPanel()
            chooser.canChooseDirectories = true
            chooser.canChooseFiles = true

            guard let vc = storyboard.instantiateController(withIdentifier: "importViewController") as? ImportViewController else {
                return
            }

            let responseHandler: (NSApplication.ModalResponse) -> Void = { _ in
                guard let url = chooser.url else {
                    return
                }
                vc.importPath = url
                vc.delegate = self
                vc.representedObject = self.document
                self.contentViewController?.presentAsSheet(vc)
            }

            if let window = window {
                chooser.beginSheetModal(for: window, completionHandler: responseHandler)
            } else {
                let response = chooser.runModal()
                responseHandler(response)
            }

        default:
            guard let vc = storyboard.instantiateController(withIdentifier: "exportViewController") as? LiftViewController else {
                return
            }

            vc.representedObject = document
            contentViewController?.presentAsSheet(vc)

        }

    }

    @IBAction func doPrintAction(_ sender: Any?) {
        mainEditor?.printCurrentView()
    }

}

extension LiftWindowController: NSWindowDelegate {
    func windowDidBecomeMain(_ notification: Notification) {
        if refreshOnWindowActivate {
            documentDatabase?.refresh()
        }
    }
}

extension LiftWindowController: StatementWaitingViewDelegate {
    func waitingView(_ view: StatementWaitingViewController, finishedSuccessfully: Bool) {
        contentViewController?.dismiss(view)
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

extension LiftWindowController: NSDraggingDestination {

    func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
        return draggingInfo.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil)
    }

    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return shouldAllowDrag(sender) ? .copy : NSDragOperation()
    }

    func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return shouldAllowDrag(sender)
    }

    func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {

        let pasteBoard = draggingInfo.draggingPasteboard

        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let url = urls.first {

            if let viewcontroller = storyboard?.instantiateController(withIdentifier: .attachDatabase) as? AttachDatabaseViewController {
                viewcontroller.representedObject = document
                contentViewController?.presentAsSheet(viewcontroller)
                viewcontroller.path = url
            }

            return true
        }

        return false

    }

}

extension LiftWindowController: ImportViewDelegate {
    func importView(_ importVC: ImportViewController, showSQL text: String) {
        contentViewController?.dismiss(importVC)
        showQueryView(with: text)
    }
}
