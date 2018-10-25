//
//  TableDetailViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/26/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TableDetailViewController: LiftViewController {
    enum DetailSection {
        case sql(String)
        case indexes([Index])
        case triggers([Trigger])
    }

    @IBOutlet weak var contentTabView: NSTabView!

    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var alterButton: NSButton!

    var sections = [DetailSection]()

    override func viewDidLoad() {
        outlineView.indentationPerLevel = 0
        super.viewDidLoad()
        let trackingArea = NSTrackingArea(rect: alterButton.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: view, userInfo: nil)
        alterButton.addTrackingArea(trackingArea)
        alterButton.animator().alphaValue = 0
    }

    override func mouseEntered(with event: NSEvent) {
        alterButton.animator().alphaValue = 1
        super.mouseEntered(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        alterButton.animator().alphaValue = 0
        super.mouseExited(with: event)
    }

    override var representedObject: Any? {
        didSet {
            if let document = document {
//                sqlTextView?.setIdentifiers(document.keywords())
            }
        }
    }

    override var selectedTable: DataProvider? {
        didSet {
            if selectedTable == nil {
                contentTabView.selectTabViewItem(at: 0)
            } else {
                contentTabView.selectTabViewItem(at: 1)
                sections.removeAll()

               if let provider = selectedTable {
                    sections.append(.sql(provider.sql))
                    if let table = provider as? Table {
                        if !table.indexes.isEmpty {
                            sections.append(.indexes(table.indexes))
                        }

                        if !table.triggers.isEmpty {
                            sections.append(.triggers(table.triggers))
                        }
                    }
                }

                outlineView.reloadItem(nil)
//                if let document = document {
//                    sqlTextView.setIdentifiers(document.keywords())
//                }
            }
//            sqlTextView.string = selectedTable?.sql ?? ""
//
//            sqlTextView.setIdentifiers(document?.keywords() ?? [] )
//            sqlTextView.refresh()

        }
    }

    @IBAction func alterTable(_ sender: Any) {
        if let view = selectedTable as? View, let definition = view.definition {
            guard let editController = storyboard?.instantiateController(withIdentifier: "createViewViewController") as? CreateViewViewController else {
                return
            }
            editController.dropQualifiedName = view.qualifiedNameForQuery
            editController.representedObject = representedObject
            editController.viewDefinition = definition
            presentAsSheet(editController)
        } else if let table = selectedTable as? Table, let tableDef = table.definition {
            guard let editController = storyboard?.instantiateController(withIdentifier: "createTableViewController") as? CreateTableViewController else {
                return
            }
            editController.representedObject = representedObject
            editController.table = CreateTableDefinition(existingDefinition: tableDef)
            presentAsSheet(editController)
        } else {
            print("UNABLE TO GET DEF!! WHATS UP!?")
        }
    }
}

extension NSUserInterfaceItemIdentifier {
    fileprivate static let sqliteTitleCell = NSUserInterfaceItemIdentifier(rawValue: "sqlTitleCell")
    fileprivate static let sqliteContentCell = NSUserInterfaceItemIdentifier(rawValue: "contentCell")
    fileprivate static let sqlOnlyCell = NSUserInterfaceItemIdentifier(rawValue: "sqlOnlyCell")

}

extension TableDetailViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        switch item {
        case let detail as DetailSection:
            let view = outlineView.makeView(withIdentifier: .sqliteTitleCell, owner: self) as? NSTableCellView
            switch detail {
            case .sql:
                view?.textField?.stringValue = NSLocalizedString("SQL", comment: "Table detail section title")
            case .indexes:
                view?.textField?.stringValue = NSLocalizedString("INDEXES", comment: "Table detail section title")
            case .triggers:
                view?.textField?.stringValue = NSLocalizedString("TRIGGERS", comment: "Table detail section title")
            }
            return view
        case let index as Index:
            let view = outlineView.makeView(withIdentifier: .sqliteContentCell, owner: self) as? SideBarDetailCell
            view?.sqlView.setup()
            if let ids = document?.keywords() {
                view?.sqlView.setIdentifiers(ids)
            }
            view?.titleLabel?.stringValue = index.name
            view?.sqlView.string = index.sql ?? ""
            view?.sqlView.refresh()

            return view
        case let trigger as Trigger:
            let view = outlineView.makeView(withIdentifier: .sqliteContentCell, owner: self) as? SideBarDetailCell
            view?.sqlView.setup()
            if let ids = document?.keywords() {
                view?.sqlView.setIdentifiers(ids)
            }
            view?.titleLabel?.stringValue = trigger.name
            view?.sqlView.string = trigger.sql ?? ""
            view?.sqlView.refresh()

            return view
        case let sql as String:
            let view = outlineView.makeView(withIdentifier: .sqlOnlyCell, owner: self) as? SideBarDetailCell
            view?.sqlView.setup()
            if let ids = document?.keywords() {
                view?.sqlView.setIdentifiers(ids)
            }
            view?.sqlView.string = sql
            view?.sqlView.refresh()

            return view
        default:
            return nil
        }

    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelect tableColumn: NSTableColumn?) -> Bool {
        return false
    }

    public func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return true
    }

    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        return true
    }
}

extension TableDetailViewController: NSOutlineViewDataSource {

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        switch item {
        case let x as DetailSection:
            switch x {
            case .sql:
                return 1
            case .indexes(let indexes):
                return indexes.count
            case .triggers(let triggers):
                return triggers.count
            }
        default:
            return sections.count
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        switch item {
        case let x as DetailSection:
            switch x {
            case .sql(let value):
                return value
            case .indexes(let indexes):
                return indexes[index]
            case .triggers(let triggers):
                return triggers[index]
            }
        default:
            return sections[index]
        }
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        switch item {
        case is DetailSection:
            return true
        default:
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return item
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        switch item {
        case is DetailSection:
            return 24
        default:
            return 100
        }
    }
}
