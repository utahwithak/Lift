//
//  HeaderViewNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Foundation

class HeaderViewNode: BrowseViewNode {

    func refresh(with document: LiftDocument, filteredWith predicate: NSPredicate?) {
        guard let dbNodes = children as? [DatabaseViewNode] else {
            return
        }
        let allDbs = document.database.allDatabases

        var toRemove = IndexSet(0..<dbNodes.count)
        var toAdd = IndexSet(0..<allDbs.count)

        for newIndex in 0..<allDbs.count {
            let database = allDbs[newIndex]
            if let index = dbNodes.index(where: { $0.database?.name == database.name}) {
                toRemove.remove(index)
                dbNodes[index].reload(with: database, with: predicate)
                toAdd.remove(newIndex)
            }
        }

        for toRemove in toRemove.reversed() {
            children.remove(at: toRemove)
        }

        for toAdd in toAdd {
            children.append(DatabaseViewNode(database: allDbs[toAdd], filteredWith: predicate))
        }

        if !toAdd.isEmpty {
            children.sort { (l, r) -> Bool in
                guard let lhs = (l as? DatabaseViewNode)?.database, let rhs = (r as? DatabaseViewNode)?.database else {
                    return false
                }

                return allDbs.index(of: lhs)! < allDbs.index(of: rhs)!
            }
        }

        if let predicate = predicate {
            for case let database as DatabaseViewNode in children {
                database.filterWith(predicate: predicate)
            }
        }
    }
}
