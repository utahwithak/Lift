//
//  DatabaseViewNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class DatabaseViewNode: BrowseViewNode {

    weak var database: Database?

    @objc dynamic var path: String?

    let tableGroup = GroupViewNode(name: NSLocalizedString("Tables", comment: "Table group header name"))
    let viewGroup = GroupViewNode(name: NSLocalizedString("Views", comment: "View group header name"))
    let systemTableGroup = GroupViewNode(name: NSLocalizedString("System Tables", comment: "System Table group header name"))

    init(database: Database, filteredWith predicate: NSPredicate?) {
        self.database = database

        super.init(name: database.name)

        if let url = URL(string: database.path) {
            path = url.lastPathComponent
        } else {
            path = database.path
        }

        tableGroup.image = NSImage(named: NSImage.listViewTemplateName)
        viewGroup.image = NSImage(named: NSImage.quickLookTemplateName)
        systemTableGroup.image = NSImage(named: NSImage.actionTemplateName)

        for table in database.tables.sorted(by: { $0.name < $1.name }) {
            tableGroup.children.append( TableViewNode(provider: table))
        }

        for view in database.views.sorted(by: { $0.name < $1.name }) {
            viewGroup.children.append( TableViewNode(provider: view))
        }

        for table in database.systemTables.sorted(by: { $0.name < $1.name }) {
            systemTableGroup.children.append( TableViewNode(provider: table))
        }

        refreshChildren()

        if let predicate = predicate {
            filterWith(predicate: predicate)
        }

    }

    func filterWith(predicate: NSPredicate) {
        tableGroup.filter(with: predicate)
        viewGroup.filter(with: predicate)
        systemTableGroup.filter(with: predicate)

        refreshChildren()
    }

    func reload(with database: Database, with predicate: NSPredicate?) {
        self.database = database

        if let url = URL(string: database.path), url.lastPathComponent != path {
            path = url.lastPathComponent
        } else if path != database.path {
            path = database.path
        }

        tableGroup.refresh(with: database.tables, with: predicate)

        viewGroup.refresh(with: database.views, with: predicate)

        systemTableGroup.refresh(with: database.systemTables, with: predicate)

        refreshChildren()

    }

    private func refreshChildren() {

        if !tableGroup.children.isEmpty && !children.contains(tableGroup) {
            children.insert(tableGroup, at: 0)
        } else if tableGroup.children.isEmpty, let index = children.firstIndex(of: tableGroup) {
            children.remove(at: index)
        }

        if !viewGroup.children.isEmpty && !children.contains(viewGroup) {
            if let index = children.firstIndex(of: tableGroup) {
                children.insert(viewGroup, at: index + 1)
            } else {
                children.insert(viewGroup, at: 0)
            }
        } else if viewGroup.children.isEmpty, let viewIndex = children.firstIndex(of: viewGroup) {
            children.remove(at: viewIndex)
        }

        if !systemTableGroup.children.isEmpty && !children.contains(systemTableGroup) {
            // always at the end
            children.append(systemTableGroup)
        } else if systemTableGroup.children.isEmpty, let existingIndex = children.firstIndex(of: systemTableGroup) {
            children.remove(at: existingIndex)
        }

    }
}
