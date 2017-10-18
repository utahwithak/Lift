//
//  NSTreeController+Additions.swift
//  Lift
//
//  Created by Carl Wieland on 10/16/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

extension NSTreeController {

    func indexPathOfObject(anObject: NSObject) -> IndexPath? {
        return self.indexPathOfObject(anObject: anObject, nodes: self.arrangedObjects.children)
    }

    private func indexPathOfObject(anObject: NSObject, nodes: [NSTreeNode]?) -> IndexPath? {
        guard let nodes = nodes else {
            return nil
        }
        for node in nodes {
            if (anObject == node.representedObject as! NSObject)  {
                return node.indexPath
            }

            if let path = self.indexPathOfObject(anObject: anObject, nodes: node.children) {
                return path
            }

        }
        return nil
    }

     func index(of table: Table) -> IndexPath? {
        guard let nodes = arrangedObjects.children else {
            return nil
        }

        guard let dbNode = nodes.first(where: { ($0.representedObject as? DatabaseViewNode)?.database?.tables.contains(table) ?? false }) else {
            return nil
        }

        guard let tableNode = dbNode.children?.first( where: { ($0.representedObject as? TableViewNode)?.table == table}) else {
            return nil
        }

        return tableNode.indexPath

    }
}
