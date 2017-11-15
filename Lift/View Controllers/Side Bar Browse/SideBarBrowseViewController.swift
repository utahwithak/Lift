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
    override var representedObject: Any? {
        didSet {
            refreshNodes()
            if let document = document {
                let database = document.database
                NotificationCenter.default.addObserver(self, selector: #selector(attachedDatabasesChanged), name: .AttachedDatabasesChanged, object: database)
                NotificationCenter.default.addObserver(forName: .DatabaseReloaded, object: nil, queue: nil, using: { notification in
                    guard let database = notification.object as? Database, self.document?.database.allDatabases.contains(where: { $0 === database }) ?? false else {
                        return
                    }

                    self.refreshNodes()

                })
            }
        }
    }

    @objc dynamic var nodes = [BrowseViewNode]()

    @IBOutlet var treeController: NSTreeController!
    
    func refreshNodes() {
        guard let document = document else {
            nodes = []
            return
        }
        if let headerNode = nodes.first as? HeaderViewNode {
            headerNode.refresh(with: document)

        } else {
            nodes.removeAll(keepingCapacity: true)
            let header = HeaderViewNode(name: NSLocalizedString("Databases", comment: "Databases header cell title"))

            for database in document.database.allDatabases {
                header.children.append(DatabaseViewNode(database: database))
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

    @objc dynamic var selectedIndexes = [IndexPath]() {
        didSet {
            if windowController?.selectedTable != treeControllerSelectedTable {
                windowController?.selectedTable = treeControllerSelectedTable
            }

        }
    }

    override func mouseDown(with event: NSEvent) {
        print("Mouse down!")
        super.mouseDown(with: event)
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        (segue.destinationController as? NSViewController)?.representedObject = representedObject
    }


    @IBAction func showCreateView(_ sender: Any?) {
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("createView"), sender: sender)
    }

    @IBAction func showCreateTable(_ sender: Any?) {
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("createTable"), sender: sender)
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
            return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue:"TableCell"), owner: self)
        } else if node.representedObject is DatabaseViewNode  {
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue:"Heads"), owner: self)
            DispatchQueue.main.async {
                outlineView.expandItem(item, expandChildren: false)
            }
            return view;

        } else if node.representedObject is GroupViewNode {
            DispatchQueue.main.async {
                outlineView.expandItem(item, expandChildren: false)
            }
            return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue:"DataCell"), owner: self)
        } else if node.representedObject is HeaderViewNode {
            DispatchQueue.main.async {
                outlineView.expandItem(item, expandChildren: false)
            }
            return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue:"HeaderCell"), owner: self)
        }

        return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue:"ColumnCell"), owner: self)

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
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("showAttach"), sender: self)
    }

    @objc private func showDetachDatabase(_ item: NSMenuItem) {
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("showDetach"), sender: self)
    }

    @objc private func dropProvider(_ item: NSMenuItem) {
        guard let provider = item.representedObject as? DataProvider else {
            return
        }

        let alert = NSAlert()
        let format = NSLocalizedString("Drop %@?", comment: "title for drop alert")
        alert.messageText = String(format: format, provider.type)
        let messageFormat = NSLocalizedString("Are you sure you want to drop %@ \"%@\"?\nThis cannot be undone.", comment: "Confirmation text")
        alert.informativeText = String(format: messageFormat, provider.type, provider.name)
        alert.addButton(withTitle: "Drop")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            do {
                _ = try provider.drop()
            } catch {
                presentError(error)
            }
        }
    }

    private func clone(provider: DataProvider, to type: Table.CloneType) {
        guard let waitingView = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("waitingOperationView")) as? WaitingOperationViewController else {
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

        presentViewControllerAsSheet(waitingView)

        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try provider.cloneToDB(type, keepGoing: keepGoing)
                DispatchQueue.main.async {
                    self.dismissViewController(waitingView)
                }
            } catch {
                DispatchQueue.main.async {
                    self.dismissViewController(waitingView)
                    self.presentError(error)
                }

            }
        }

    }

    @objc private func createTempClone(_ item: NSMenuItem) {

        guard let provider = item.representedObject as? DataProvider else {
            return
        }

        clone(provider: provider, to: .toTemp)
    }

    @objc private func cloneToMain(_ item: NSMenuItem) {

        guard let provider = item.representedObject as? DataProvider else {
            return
        }

        clone(provider: provider, to: .toMain)
    }

    @objc private func showInFinder(_ item: NSMenuItem) {
        guard let url = item.representedObject as? URL else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @objc private func renameProvider(_ item: NSMenuItem) {
        guard let provider = item.representedObject as? DataProvider else {
            return
        }

    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        print("update")
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

                if URL(string: database.path) != nil {
                    let detatch = NSMenuItem(title: "Show in Finder", action: #selector(showInFinder), keyEquivalent: "")
                    detatch.representedObject = URL(fileURLWithPath: database.path)
                    menu.addItem(detatch)
                }
            }
        case let tableNode as TableViewNode:
            if !tableNode.name.hasPrefix("sqlite") {

                if let provider = tableNode.provider {
                    let dropFormat = NSLocalizedString("Drop %@", comment: "Drop table or view menu item, with %@ replaced with the name")
                    let dropObject = NSMenuItem(title: String(format: dropFormat,provider.type), action: #selector(dropProvider), keyEquivalent: "")
                    dropObject.representedObject = tableNode.provider
                    menu.addItem(dropObject)

                    if provider.database?.name != "temp" {
                        let cloneTemp = NSMenuItem(title:  NSLocalizedString("Clone to temp", comment: "clone to temp db menu item"), action: #selector(createTempClone), keyEquivalent: "")
                        cloneTemp.representedObject = tableNode.provider
                        menu.addItem(cloneTemp)
                    }

                    if provider.database?.name != "main" {
                        let cloneTemp = NSMenuItem(title: NSLocalizedString("Clone to main", comment: "clone to main menu item"), action: #selector(cloneToMain), keyEquivalent: "")
                        cloneTemp.representedObject = tableNode.provider
                        menu.addItem(cloneTemp)

                    }

                    let renameObject = NSMenuItem(title: NSLocalizedString("Rename", comment: "Rename menu item"), action: #selector(renameProvider), keyEquivalent: "")
                    renameObject.representedObject = tableNode.provider
                    menu.addItem(renameObject)
                }
            }
        default:
            return
        }


    }

}
