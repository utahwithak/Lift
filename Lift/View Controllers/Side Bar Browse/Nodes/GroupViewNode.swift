//
//  GroupViewNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class GroupViewNode: BrowseViewNode {
    @objc dynamic var image: NSImage?
    func filter(with predicate: NSPredicate) {
        var filteredChildren = [TableViewNode]()
        for case let table as TableViewNode in children {
            if predicate.evaluate(with: table) {
                filteredChildren.append(table)
            } else {
                let tableChildren = table.children.filter(predicate.evaluate)
                if !tableChildren.isEmpty {
                    table.children = tableChildren
                    filteredChildren.append(table)
                } else {

                }

            }
        }
        children = filteredChildren
    }

    func refresh( with providers: [DataProvider], with predicate: NSPredicate?) {
        var toAdd = IndexSet(0..<providers.count)
        if !children.isEmpty {
            var toRemove = IndexSet(0..<children.count)

            for tableIndex in 0..<providers.count {
                let newTable = providers[tableIndex]

                if let oldIndex = children.index(where: { ($0 as? TableViewNode)?.provider?.name == newTable.name}) {
                    toAdd.remove(tableIndex)
                    toRemove.remove(oldIndex)
                    guard let table = children[oldIndex] as? TableViewNode else {
                        continue
                    }
                    table.refresh(with: newTable, with: predicate)
                }

            }
            for toRemove in toRemove.reversed() {
                children.remove(at: toRemove)
            }
        }
        if !toAdd.isEmpty {
            var newNodes = toAdd.map({ TableViewNode(provider: providers[$0]) })
            newNodes = newNodes.filter({ predicate?.evaluate(with: $0) ?? true })
            if !newNodes.isEmpty {
                children.append(contentsOf: newNodes)
                children.sort { (l, r) -> Bool in
                    return l.name.localizedCaseInsensitiveCompare(r.name) == .orderedAscending
                }
            }
        }
    }
}
