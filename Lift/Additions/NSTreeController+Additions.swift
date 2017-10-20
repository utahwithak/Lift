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

     func index(of provider: DataProvider) -> IndexPath? {
        guard let nodes = arrangedObjects.children else {
            return nil
        }
        return index(of: provider, in: nodes)
    }

    private func index(of provider: DataProvider, in nodes: [NSTreeNode]) -> IndexPath? {

        for node in nodes {
            if let tableNode = node.representedObject as? TableViewNode, tableNode.provider === provider {
                return node.indexPath
            }

            if let children = node.children, let indexPath = index(of: provider, in: children) {
                return indexPath
            }
        }

        return nil
    }
}
