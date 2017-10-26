//
//  BrowseViewNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

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

class HeaderViewNode: BrowseViewNode {

}

class GroupViewNode: BrowseViewNode {
    @objc dynamic var image: NSImage?
}

class DatabaseViewNode: BrowseViewNode {

    weak var database: Database?

    @objc dynamic var path: String?

    init(database: Database) {
        self.database = database

        super.init(name: database.name)

        if let url = URL(string: database.path) {
            path = url.lastPathComponent
        } else {
            path = database.path
        }

        let tableGroup = GroupViewNode(name: NSLocalizedString("Tables", comment: "Table group header name"))
        children.append(tableGroup)
        tableGroup.image = NSImage(named: NSImage.Name.listViewTemplate)
        for table in database.tables.sorted(by: { $0.name < $1.name }) {
            tableGroup.children.append( TableViewNode(provider: table))
        }

        let viewGroup = GroupViewNode(name: NSLocalizedString("Views", comment: "View group header name"))
        viewGroup.image = NSImage(named: NSImage.Name.quickLookTemplate)
        children.append(viewGroup)
        for view in database.views {
            viewGroup.children.append( TableViewNode(provider: view))
        }

        let systemTableGroup = GroupViewNode(name: NSLocalizedString("System Tables", comment: "System Table group header name"))
        children.append(systemTableGroup)
        systemTableGroup.image = NSImage(named: NSImage.Name.actionTemplate)
        for table in database.systemTables.sorted(by: { $0.name < $1.name }) {
            systemTableGroup.children.append( TableViewNode(provider: table))
        }

    }
}

class TableViewNode: BrowseViewNode {

    @objc dynamic var refreshingCount = false
    @objc dynamic var rowCount: NSNumber?

    weak var provider: DataProvider?

    init(provider: DataProvider) {
        self.provider = provider

        super.init(name: provider.name)

        if let curCount =  provider.rowCount {
            rowCount = NSNumber(integerLiteral: curCount)
        }

        for column in provider.columns {
            children.append( ColumnNode(parent: provider, name: column.name, type: column.type))
        }
        NotificationCenter.default.addObserver(forName: .TableDidBeginRefreshingRowCount, object: provider, queue: nil) { [weak self] _ in
            self?.refreshingCount = true
        }

        NotificationCenter.default.addObserver(forName: .TableDidEndRefreshingRowCount, object: provider, queue: nil) { [weak self] _ in
            self?.refreshingCount = false
        }

        NotificationCenter.default.addObserver(forName: .TableDidChangeRowCount, object: provider, queue: nil) { [weak self, weak provider] _ in
            guard let table = provider, let mySelf = self else {
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

class ColumnNode: BrowseViewNode {

    weak var provider: DataProvider?

    init(parent: DataProvider, name: String, type: String) {
        provider = parent
        self.type = type
        super.init(name: name)
    }

    @objc dynamic let type: String
}

