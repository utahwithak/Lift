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
        }
    }

    @objc dynamic var nodes = [BrowseViewNode]()


    func refreshNodes() {
        guard let document = document else {
            nodes = []
            return
        }
        
        for database in document.database.allDatabases {
            nodes.append(DatabaseViewNode(database: database))
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
        return true
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
                outlineView.expandItem(item, expandChildren: true)
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
            return 28
        } else if self.outlineView(outlineView, isGroupItem: item) {
            return 25
        }

        return 17
    }
}
