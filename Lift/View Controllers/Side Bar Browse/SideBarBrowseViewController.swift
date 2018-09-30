//
//  SideBarBrowseViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class SideBarBrowseViewController: LiftViewController {

    @IBOutlet weak var outlineView: NSOutlineView!

    @IBOutlet weak var tableFilterField: NSSearchField!
    override var representedObject: Any? {

        didSet {
            refreshNodes()
            if let document = document {
                let database = document.database
                NotificationCenter.default.addObserver(self, selector: #selector(attachedDatabasesChanged), name: .AttachedDatabasesChanged, object: database)
                NotificationCenter.default.addObserver(self, selector: #selector(databaseReloaded), name: .DatabaseReloaded, object: database)
            }
        }
    }

    @objc dynamic var nodes = [BrowseViewNode]()

    @IBOutlet var treeController: NSTreeController!
    private var outlinePredicate: NSPredicate?

    func refreshNodes() {
        guard let document = document else {
            nodes = []
            return
        }
        if let headerNode = nodes.first as? HeaderViewNode {
            headerNode.refresh(with: document, filteredWith: outlinePredicate)
        } else {
            nodes.removeAll(keepingCapacity: true)
            let header = HeaderViewNode(name: NSLocalizedString("Databases", comment: "Databases header cell title"))

            for database in document.database.allDatabases {
                header.children.append(DatabaseViewNode(database: database, filteredWith: outlinePredicate))
            }
            nodes.append(header)
        }

    }

    override var selectedTable: DataProvider? {
        didSet {
            if treeControllerSelectedTable != selectedTable {
                // try and select the new table
                if let newTable = selectedTable {
                    treeController.setSelectionIndexPath(treeController.index(of: newTable))

                } else {
                    treeController.setSelectionIndexPath(nil)
                }
            }
        }
    }

    var treeControllerSelectedTable: DataProvider? {
        guard let selectedObject = treeController.selectedObjects.first as? BrowseViewNode else {
            return nil
        }

        if let dbNode = selectedObject as? DatabaseViewNode {
            return dbNode.database?.tables.first ?? dbNode.database?.views.first
        } else if let tableNode = selectedObject as? TableViewNode {
            return tableNode.provider
        } else if let colNode = selectedObject as? ColumnNode {
            return colNode.provider
        }
        return nil
    }

    @objc private func attachedDatabasesChanged(_ notification: Notification) {
        refreshNodes()
    }

    @objc private func databaseReloaded(_ notification: Notification) {
        guard let database = notification.object as? Database, self.document?.database.allDatabases.contains(where: { $0 === database }) ?? false else {
            return
        }

        self.refreshNodes()

    }

    @objc dynamic var selectedIndexes = [IndexPath]() {
        didSet {
            if windowController?.selectedTable != treeControllerSelectedTable {
                windowController?.selectedTable = treeControllerSelectedTable
                windowController?.showMainView(type: .table)
            }

            guard let selectedObject = treeController.selectedObjects.first as? BrowseViewNode else {
                windowController?.selectedColumn = nil
                return
            }
    
            windowController?.selectedColumn = (selectedObject as? ColumnNode)?.column

        }
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        (segue.destinationController as? NSViewController)?.representedObject = representedObject
    }

    @IBAction func showCreateView(_ sender: Any?) {
        performSegue(withIdentifier: "createView", sender: sender)
    }

    @IBAction func showCreateTable(_ sender: Any?) {
        performSegue(withIdentifier: "createTable", sender: sender)
    }

    @IBAction func dropSelectedTable(_ sender: NSButton) {
        guard let provider = selectedTable else {
            print("No selected provider!")
            return
        }
        drop(provider: provider)
    }
}

extension SideBarBrowseViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let repItem = (item as? NSTreeNode)?.representedObject else {
            return false
        }
        return repItem is TableViewNode || repItem is ColumnNode
    }

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return (item as? NSTreeNode)?.representedObject is HeaderViewNode
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? NSTreeNode else {
            return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ColumnCell"), owner: self)
        }

        if node.representedObject is TableViewNode {
            return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TableCell"), owner: self)
        } else if node.representedObject is DatabaseViewNode {
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Heads"), owner: self)
            DispatchQueue.main.async {
                outlineView.expandItem(item, expandChildren: false)
            }
            return view

        } else if node.representedObject is GroupViewNode {
            DispatchQueue.main.async {
                outlineView.expandItem(item, expandChildren: false)
            }
            return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self)
        } else if node.representedObject is HeaderViewNode {
            DispatchQueue.main.async {
                outlineView.expandItem(item, expandChildren: false)
            }
            return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self)
        }

        return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ColumnCell"), owner: self)

    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let node = item as? NSTreeNode else {
            return 17
        }

        if node.representedObject is TableViewNode {
            return 20
        } else if self.outlineView(outlineView, isGroupItem: item) {
            return 25
        }

        return 17
    }
}

extension SideBarBrowseViewController: NSMenuDelegate {

    @objc private func detatchDatabase(_ item: NSMenuItem) {
        guard let database = item.representedObject as? Database, let document = document else {
            return
        }
        do {
            if !(try document.database.detachDatabase(named: database.name)) {
                let alert = NSAlert()
                alert.messageText = "Failed to detach database, unknown error occured..."
                alert.runModal()
            }
        } catch {
            presentError(error)
        }

    }

    @objc private func showAttachDatabase(_ item: NSMenuItem) {
        performSegue(withIdentifier: "showAttach", sender: self)
    }

    @objc private func showDetachDatabase(_ item: NSMenuItem) {
        performSegue(withIdentifier: "showDetach", sender: self)
    }

    @objc private func dropProvider(_ item: NSMenuItem) {
        guard let provider = item.representedObject as? DataProvider else {
            return
        }
        drop(provider: provider)
    }

    private func drop(provider: DataProvider) {
        let alert = NSAlert()
        let format = NSLocalizedString("Drop %@?", comment: "title for drop alert")
        alert.messageText = String(format: format, provider.type)
        let messageFormat = NSLocalizedString("Are you sure you want to drop %@ \"%@\"?%@", comment: "Confirmation text")
        let checkText: String
        if document?.database.autocommitStatus == .autocommit {
            checkText = NSLocalizedString("\nThis cannot be undone.", comment: "Extra warning when dropping table in autocommit mode")
        } else {
            checkText = ""
        }
        alert.informativeText = String(format: messageFormat, provider.type, provider.name, checkText)
        alert.addButton(withTitle: NSLocalizedString("Drop", comment: "Drop alert button "))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "cancel Drop"))
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            do {
                _ = try provider.drop()
            } catch {
                presentError(error)
            }
        }
    }

    private func transfer(provider: DataProvider, with type: Table.TransferType) {
        guard let waitingView = storyboard?.instantiateController(withIdentifier: "waitingOperationView") as? WaitingOperationViewController else {
            return
        }
        var validOp = true
        let keepGoing: () -> Bool = {
            return validOp
        }

        let cancelOp: () -> Void = {
            validOp = false
        }

        waitingView.cancelHandler = cancelOp

        presentAsSheet(waitingView)

        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try provider.transfer(with: type, keepGoing: keepGoing)
                DispatchQueue.main.async {
                    self.dismiss(waitingView)
                }
            } catch {
                DispatchQueue.main.async {
                    self.dismiss(waitingView)
                    self.presentError(error)
                }

            }
        }

    }

    @objc private func createTempClone(_ item: NSMenuItem) {

        guard let provider = item.representedObject as? DataProvider else {
            return
        }

        transfer(provider: provider, with: .cloneToTemp)
    }

    @objc private func cloneToMain(_ item: NSMenuItem) {

        guard let provider = item.representedObject as? DataProvider else {
            return
        }

        transfer(provider: provider, with: .cloneToMain)
    }

    @objc private func moveToMain(_ item: NSMenuItem) {

        guard let provider = item.representedObject as? DataProvider else {
            return
        }
        transfer(provider: provider, with: .moveToMain)

    }

    @objc private func moveToTemp(_ item: NSMenuItem) {

        guard let provider = item.representedObject as? DataProvider else {
            return
        }
        transfer(provider: provider, with: .moveToTemp)

    }

    @objc private func showInFinder(_ item: NSMenuItem) {
        guard let url = item.representedObject as? URL else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @objc private func renameProvider(_ item: NSMenuItem) {
        guard let table = item.representedObject as? Table, let window = view.window else {
            return
        }

        let namePrompt = NSAlert()
        namePrompt.messageText = NSLocalizedString("Rename Table", comment: "Title text")
        namePrompt.informativeText = NSLocalizedString("Enter new table name.", comment: "rename table text")
        namePrompt.addButton(withTitle: NSLocalizedString("Rename", comment: "Rename button name"))
        namePrompt.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel rename string"))
        let textfield = NSTextField(frame: NSRect(x: 0, y: 0, width: 150, height: 21))
        textfield.stringValue = table.name
        namePrompt.accessoryView = textfield
        textfield.becomeFirstResponder()
        namePrompt.beginSheetModal(for: window) { (response) in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                do {
                    let newName = textfield.stringValue
                    _ = try self.document?.database.execute(statement: "ALTER TABLE \(table.qualifiedNameForQuery) RENAME TO \(newName.sqliteSafeString())")
                    self.document?.database.refresh()
                } catch {
                    self.presentError(error)
                }
            }
        }

    }

    @objc private func editProvider(_ item: NSMenuItem) {
        guard let provider = item.representedObject as? DataProvider else {
            return
        }
        edit(provider: provider)

    }

    @IBAction func editSelected(_ sender: NSButton) {
        guard let provider = selectedTable else {
            print("No selected provider!")
            return
        }
        edit(provider: provider)
    }

    private func edit(provider: DataProvider) {
        if let view = (provider as? View)?.definition {
            guard let editController = storyboard?.instantiateController(withIdentifier: "createViewViewController") as? CreateViewViewController else {
                return
            }
            editController.dropQualifiedName = provider.qualifiedNameForQuery
            editController.representedObject = representedObject
            editController.viewDefinition = view
            presentAsSheet(editController)
        } else if let tableDef = (provider as? Table)?.definition {
            guard let editController = storyboard?.instantiateController(withIdentifier: "createTableViewController") as? CreateTableViewController else {
                return
            }
            editController.representedObject = representedObject
            editController.table = CreateTableDefinition(existingDefinition: tableDef)
            presentAsSheet(editController)
        } else {
            print("UNABLE TO GET DEF!! WHATS UP!?")
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.delegate = self
        menu.removeAllItems()
        let row = outlineView.clickedRow
        let column = outlineView.clickedColumn
        print("Selection:\(row) \(column)")
        guard row >= 0 && column >= 0 else {
            return
        }

        guard let view = outlineView.view(atColumn: column, row: row, makeIfNecessary: false) as? NSTableCellView else {
            return
        }

        guard let node = view.objectValue as? BrowseViewNode else {
            return
        }

        switch node {
        case is HeaderViewNode:
            menu.addItem(withTitle: "Attach Database", action: #selector(showAttachDatabase), keyEquivalent: "")
            if !(document?.database.attachedDatabases.isEmpty ?? true) {
                menu.addItem(withTitle: "Detach Database", action: #selector(showDetachDatabase), keyEquivalent: "")
            }

        case let dbNode as DatabaseViewNode:
            if let database = dbNode.database, let document = document {
                if document.database.attachedDatabases.contains(where: { database === $0 }) {
                    let detatch = NSMenuItem(title: "Detach \(database.name)", action: #selector(detatchDatabase), keyEquivalent: "")
                    detatch.representedObject = database
                    menu.addItem(detatch)
                }

                if !database.path.isEmpty && database.path != "In Memory" {
                    let detatch = NSMenuItem(title: "Show in Finder", action: #selector(showInFinder), keyEquivalent: "")
                    detatch.representedObject = URL(fileURLWithPath: database.path)
                    menu.addItem(detatch)
                }
            }
        case let tableNode as TableViewNode:
            if !tableNode.name.hasPrefix("sqlite") {

                if let provider = tableNode.provider {
                    let dropFormat = NSLocalizedString("Drop %@", comment: "Drop table or view menu item, with %@ replaced with the name")
                    let dropObject = NSMenuItem(title: String(format: dropFormat, provider.type), action: #selector(dropProvider), keyEquivalent: "")
                    dropObject.representedObject = tableNode.provider
                    menu.addItem(dropObject)

                    if provider.database?.name != "temp" {
                        let cloneTemp = NSMenuItem(title: NSLocalizedString("Clone to temp", comment: "clone to temp db menu item"), action: #selector(createTempClone), keyEquivalent: "")
                        cloneTemp.representedObject = tableNode.provider
                        cloneTemp.keyEquivalent = "n"
                        cloneTemp.keyEquivalentModifierMask = [.command]
                        menu.addItem(cloneTemp)
                        let moveFromTemp = NSMenuItem(title: NSLocalizedString("Move to temp", comment: "clone to main menu item"), action: #selector(moveToTemp), keyEquivalent: "")
                        moveFromTemp.representedObject = tableNode.provider
                        moveFromTemp.keyEquivalent = "n"
                        moveFromTemp.isAlternate = true
                        moveFromTemp.keyEquivalentModifierMask = [.option, .command]
                        menu.addItem(moveFromTemp)
                    }

                    if provider.database?.name != "main" {

                        let cloneTemp = NSMenuItem(title: NSLocalizedString("Clone to main", comment: "clone to main menu item"), action: #selector(cloneToMain), keyEquivalent: "")
                        cloneTemp.representedObject = tableNode.provider
                        cloneTemp.keyEquivalent = "m"
                        cloneTemp.keyEquivalentModifierMask = [.command]
                        menu.addItem(cloneTemp)
                        let moveFromTemp = NSMenuItem(title: NSLocalizedString("Move to main", comment: "clone to main menu item"), action: #selector(moveToMain), keyEquivalent: "")
                        moveFromTemp.representedObject = tableNode.provider
                        moveFromTemp.keyEquivalent = "m"
                        moveFromTemp.isAlternate = true
                        moveFromTemp.keyEquivalentModifierMask = [.option, .command]
                        menu.addItem(moveFromTemp)

                    }

                    if provider is Table {
                        let renameObject = NSMenuItem(title: NSLocalizedString("Rename", comment: "Rename menu item"), action: #selector(renameProvider), keyEquivalent: "")
                        renameObject.representedObject = tableNode.provider
                        menu.addItem(renameObject)
                    }
                    if let table = provider as? Table, table.definition != nil {
                        let editObject = NSMenuItem(title: NSLocalizedString("Edit Definition", comment: "edit menu item"), action: #selector(editProvider), keyEquivalent: "")
                        editObject.representedObject = table
                        menu.addItem(editObject)
                    } else if let view = provider as? View, view.definition != nil {
                        let editObject = NSMenuItem(title: NSLocalizedString("Edit Definition", comment: "edit menu item"), action: #selector(editProvider), keyEquivalent: "")
                        editObject.representedObject = view
                        menu.addItem(editObject)
                    }

                }

            }
        default:
            return
        }

    }

}

extension SideBarBrowseViewController: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {

        if (obj.object as? NSSearchField) == self.tableFilterField {

            let predicate: NSPredicate?
            if tableFilterField.stringValue.isEmpty {
                predicate = nil
            } else {
                predicate = NSPredicate(format: "name contains[c] %@", tableFilterField.stringValue)
            }
            outlinePredicate = predicate
            refreshNodes()
            if predicate != nil {
                outlineView.expandItem(nil, expandChildren: true)
            }
        }
    }
}
