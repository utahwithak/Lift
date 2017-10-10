//
//  SideBarBrowseViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

extension Notification.Name {
    static let SelectionDataChanged = Notification.Name("SelectionDataChanged")
}

class SideBarBrowseViewController: LiftViewController {

    override var representedObject: Any? {
        didSet {
            refreshNodes()
            if let database = document?.database {
                NotificationCenter.default.addObserver(self, selector: #selector(attachedDatabasesChanged), name: .AttachedDatabasesChanged, object: database)
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
        
        for database in document.database.allDatabases {
            nodes.append(DatabaseViewNode(database: database))
        }
    }

    var selectedTable: Table? {
        didSet {
            NotificationCenter.default.post(name: .SelectionDataChanged, object: self, userInfo: ["selection":selectedTable as Any])
        }
    }

    @objc private func attachedDatabasesChanged(_ notification: Notification) {
        refreshNodes()
    }

    @objc dynamic var selectedIndexes = [IndexPath]() {
        didSet {
            guard let selectedObject = treeController.selectedObjects.first as? BrowseViewNode else {
                selectedTable = nil
                return
            }

            if let dbNode = selectedObject as? DatabaseViewNode {
                selectedTable = dbNode.database?.tables.first
            } else if let tableNode = selectedObject as? TableViewNode {
                selectedTable = tableNode.table
            } else if let colNode = selectedObject as? ColumnViewNode {
                selectedTable = colNode.column?.table
            }
        }
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

    @IBAction func showMenu(_ sender: NSButton) {
        if let menu = sender.menu, let event = NSApplication.shared.currentEvent {
            NSMenu.popUpContextMenu(menu, with: event, for: sender)
        }
    }
}

extension SideBarBrowseViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return true
    }

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        guard let node = item as? NSTreeNode else {
            return true
        }

        return node.representedObject is DatabaseViewNode

    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? NSTreeNode else {
            return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ColumnCell"), owner: self)
        }

        if node.representedObject is TableViewNode {
            return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue:"TableCell"), owner: self)
        } else if node.representedObject is DatabaseViewNode {


            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue:"Heads"), owner: self)
            DispatchQueue.main.async {
                outlineView.expandItem(item, expandChildren: false)
            }
            return view;

        }

        return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue:"ColumnCell"), owner: self)

    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let node = item as? NSTreeNode else {
            return 17
        }

        if node.representedObject is TableViewNode {
            return 33
        } else if self.outlineView(outlineView, isGroupItem: item) {
            return 25
        }

        return 17
    }
}
