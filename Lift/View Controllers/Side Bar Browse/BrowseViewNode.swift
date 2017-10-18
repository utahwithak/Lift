//
//  BrowseViewNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Foundation

class BrowseViewNode: NSObject {

    @objc dynamic let name: String

    init(name: String) {
        self.name = name
    }

    @objc dynamic var children = [BrowseViewNode]()

    @objc dynamic var childCount: Int {
        return children.count
    }

}


class DatabaseViewNode: BrowseViewNode {

    weak var database: Database?

    init(database: Database) {
        self.database = database

        super.init(name: database.name)

        for table in database.tables {
            children.append( TableViewNode(table: table))
        }

        for view in database.views {
            children.append( ViewViewNode(view: view))
        }


    }
}

class TableViewNode: BrowseViewNode {

    @objc dynamic var refreshingCount = false
    @objc dynamic var rowCount: NSNumber?

    weak var table: Table?

    init(table: Table) {
        self.table = table

        super.init(name: table.name)

        if let curCount =  table.rowCount {
            rowCount = NSNumber(integerLiteral: curCount)
        }

        for column in table.columns {
            children.append( ColumnViewNode(column: column))
        }
        NotificationCenter.default.addObserver(forName: .TableDidBeginRefreshingRowCount, object: table, queue: nil) { [weak self] _ in
            self?.refreshingCount = true
        }

        NotificationCenter.default.addObserver(forName: .TableDidEndRefreshingRowCount, object: table, queue: nil) { [weak self] _ in
            self?.refreshingCount = false
        }

        NotificationCenter.default.addObserver(forName: .TableDidChangeRowCount, object: table, queue: nil) { [weak self, weak table] _ in
            guard let table = table, let mySelf = self else {
                return
            }

            if let num = table.rowCount {
                mySelf.rowCount = NSNumber(integerLiteral: num)
            } else {
                mySelf.rowCount = nil
            }
        }

    }
}

class ColumnViewNode: BrowseViewNode {

    weak var column: Column?

    init(column: Column) {
        self.column = column
        type = column.type
        super.init(name: column.name)
    }

    @objc dynamic let type: String
}

class ViewViewNode: BrowseViewNode {
    init(view: View) {
        type = "View"
        super.init(name: view.name)
    }
    @objc dynamic let type: String

}

