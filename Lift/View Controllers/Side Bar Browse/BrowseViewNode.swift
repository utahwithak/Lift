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

    @objc dynamic var children = [BrowseViewNode]() {
        willSet {
            willChangeValue(for: \.childCount)
        }
        didSet {
            didChangeValue(for: \.childCount)
        }
    }

    @objc dynamic var childCount: Int {
        return children.count
    }

    @objc dynamic var canDrop: Bool {
        return false
    }
}

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
        } else if tableGroup.children.isEmpty, let index = children.index(of: tableGroup) {
            children.remove(at: index)
        }

        if !viewGroup.children.isEmpty && !children.contains(viewGroup) {
            if let index = children.index(of: tableGroup) {
                children.insert(viewGroup, at: index + 1)
            } else {
                children.insert(viewGroup, at: 0)
            }
        } else if viewGroup.children.isEmpty, let viewIndex = children.index(of: viewGroup) {
            children.remove(at: viewIndex)
        }

        if !systemTableGroup.children.isEmpty && !children.contains(systemTableGroup) {
            // always at the end
            children.append(systemTableGroup)
        } else if systemTableGroup.children.isEmpty, let existingIndex = children.index(of: systemTableGroup) {
            children.remove(at: existingIndex)
        }

    }
}

class TableViewNode: BrowseViewNode {

    @objc dynamic var refreshingCount = false
    @objc dynamic var rowCount: NSNumber?

    override var canDrop: Bool {
        return provider?.isEditable ?? false
    }

    weak var provider: DataProvider?
    private var tokens = [NSObjectProtocol]()
    init(provider: DataProvider) {

        refreshingCount = provider.refreshingRowCount

        self.provider = provider

        super.init(name: provider.name)
        startListening()

        if let curCount =  provider.rowCount {
            rowCount = NSNumber(value: curCount)
            refreshingCount = false
        }

        children = provider.columns.map { ColumnNode(parent: provider, column: $0) }

    }

    func stopListening() {
        tokens.forEach { NotificationCenter.default.removeObserver($0) }
        tokens.removeAll(keepingCapacity: true)
    }

    func startListening() {
        stopListening()
        let token1 =  NotificationCenter.default.addObserver(forName: .TableDidBeginRefreshingRowCount, object: provider, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshingCount = true
            }

        }

        let token2 = NotificationCenter.default.addObserver(forName: .TableDidEndRefreshingRowCount, object: provider, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshingCount = false
            }
        }

        let token3 = NotificationCenter.default.addObserver(forName: .TableDidChangeRowCount, object: provider, queue: nil) { [weak self, weak provider] _ in
            guard let table = provider, let mySelf = self else {
                return
            }
            DispatchQueue.main.async {
                if let num = table.rowCount {
                    mySelf.rowCount = NSNumber(value: num)
                } else {
                    mySelf.rowCount = nil
                }
            }
        }
        tokens = [token1, token2, token3]
    }

    func refresh(with provider: DataProvider, with predicate: NSPredicate?) {
        self.provider = provider

        startListening()
        refreshingCount = provider.refreshingRowCount

        if let curCount =  provider.rowCount {
            rowCount = NSNumber(value: curCount)
            refreshingCount = false
        }
        children = provider.columns.map { ColumnNode(parent: provider, column: $0) }.filter({ predicate?.evaluate(with: $0) ?? true })
    }
}

class ColumnNode: BrowseViewNode {

    weak var provider: DataProvider?
    weak var column: Column?
    init(parent: DataProvider, column: Column) {
        provider = parent
        self.type = column.type
        self.column = column
        super.init(name: column.name)
    }

    @objc dynamic let type: String
}
