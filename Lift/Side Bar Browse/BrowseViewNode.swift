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
    init(database: Database) {
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

    init(table: Table) {
        super.init(name: table.name)
        
    }
}

class ViewViewNode: BrowseViewNode {
    init(view: View) {
        super.init(name: view.name)
    }
}

