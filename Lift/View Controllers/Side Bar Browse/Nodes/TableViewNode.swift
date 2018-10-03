//
//  TableViewNode.swift
//  Lift
//
//  Created by Carl Wieland on 10/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class TableViewNode: BrowseViewNode {

    @objc dynamic var refreshingCount = false
    @objc dynamic var rowCount: NSNumber?

    override var canDrop: Bool {
        return provider?.isEditable ?? false
    }

    weak var provider: DataProvider?

    private var lastPredicate: NSPredicate?

    private var tokens = [NSObjectProtocol]()

    private lazy var columnNode: GroupViewNode = {
        let node = GroupViewNode(name: NSLocalizedString("tableViewNode.columnNode.name", value: "COLUMNS", comment: "column section name"))
        node.image = NSImage(named: NSImage.columnViewTemplateName)
        return node
    }()

    private lazy var indexNode: GroupViewNode = {
        let node = GroupViewNode(name: NSLocalizedString("tableViewNode.indexNode.name", value: "INDEXES", comment: "Index section name"))
        node.image = NSImage(named: NSImage.revealFreestandingTemplateName)
        return node
    }()

    private lazy var triggerNode: GroupViewNode = {
        let node = GroupViewNode(name: NSLocalizedString("tableViewNode.triggerNode.name", value: "TRIGGERS", comment: "trigger section name"))
        node.image = NSImage(named: "trigger")

        return node
    }()

    init(provider: DataProvider) {

        refreshingCount = provider.refreshingRowCount

        self.provider = provider

        super.init(name: provider.name)
        startListening()

        if let curCount =  provider.rowCount {
            rowCount = NSNumber(value: curCount)
            refreshingCount = false
        }

        NotificationCenter.default.addObserver(self, selector: #selector(indexesReloaded), name: Table.didSetIndexes, object: provider)
        NotificationCenter.default.addObserver(self, selector: #selector(triggersReloaded), name: Table.didSetTriggers, object: provider)
        refreshChildren(predicate: nil)
    }

    func stopListening() {
        tokens.forEach { NotificationCenter.default.removeObserver($0) }
        tokens.removeAll(keepingCapacity: true)
    }

    func startListening() {
        stopListening()
        let token1 =  NotificationCenter.default.addObserver(forName: Table.didStartCountingRows, object: provider, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshingCount = true
            }

        }

        let token2 = NotificationCenter.default.addObserver(forName: Table.didStopCountingNames, object: provider, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshingCount = false
            }
        }

        let token3 = NotificationCenter.default.addObserver(forName: Table.rowCountChangedNotification, object: provider, queue: nil) { [weak self, weak provider] _ in
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

    @objc private func indexesReloaded(_ notification: Notification) {
        refreshChildren(predicate: lastPredicate)
    }
    @objc private func triggersReloaded(_ notification: Notification) {
        refreshChildren(predicate: lastPredicate)
    }

    func refresh(with provider: DataProvider, with predicate: NSPredicate?) {
        self.provider = provider

        startListening()
        refreshingCount = provider.refreshingRowCount

        if let curCount =  provider.rowCount {
            rowCount = NSNumber(value: curCount)
            refreshingCount = false
        }
        refreshChildren(predicate: predicate)
    }

    private func refreshChildren(predicate: NSPredicate?) {

        self.lastPredicate = predicate

        guard let provider = provider else {
            children = []
            return
        }
        if let table = provider as? Table {

            columnNode.children = provider.columns.map { ColumnNode(parent: provider, column: $0) }.filter({ predicate?.evaluate(with: $0) ?? true })

            var hasIndexes = false
            if !table.indexes.isEmpty {
                hasIndexes = true
                indexNode.children = table.indexes.map { IndexNode(parent: provider, index: $0) }
            } else {
                indexNode.children = []
            }

            var hasTriggers = false
            if !table.triggers.isEmpty {
                hasTriggers = true
                triggerNode.children = table.triggers.map { TriggerNode(parent: provider, trigger: $0) }
            } else {
                triggerNode.children = []
            }

            if hasIndexes || hasTriggers {
                children = [columnNode]
                if hasIndexes {
                    children.append(indexNode)
                }
                if hasTriggers {
                    children.append(triggerNode)
                }
            } else {
                children = columnNode.children
            }

        } else {
            children = provider.columns.map { ColumnNode(parent: provider, column: $0) }.filter({ predicate?.evaluate(with: $0) ?? true })
        }
    }
}
