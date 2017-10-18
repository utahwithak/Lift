//
//  SideBarBrowseViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class SideBarBrowseViewController: LiftViewController {

    override var representedObject: Any? {
        didSet {
            refreshNodes()
            if let document = document {
                let database = document.database
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
        nodes.removeAll(keepingCapacity: true)
        for database in document.database.allDatabases {
            nodes.append(DatabaseViewNode(database: database))
        }
    }

    override var selectedTable: Table? {
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

    var treeControllerSelectedTable: Table? {
        guard let selectedObject = treeController.selectedObjects.first as? BrowseViewNode else {
            return nil
        }

        if let dbNode = selectedObject as? DatabaseViewNode {
            return dbNode.database?.tables.first
        } else if let tableNode = selectedObject as? TableViewNode {
            return tableNode.table
        } else if let colNode = selectedObject as? ColumnViewNode {
            return colNode.column?.table
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
