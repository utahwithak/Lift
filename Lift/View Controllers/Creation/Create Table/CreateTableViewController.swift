//
//  CreateTableViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class CreateTableViewController: LiftViewController {

    @objc dynamic var table = CreateTableDefinition()

    @IBOutlet weak var createTabView: NSTabView!

    @IBOutlet weak var definitionTabView: NSTabView!

    @IBOutlet weak var columnArrayController: CreateColumnArrayController!

    @IBOutlet weak var tableConstraintArrayController: CreateTableConstraintArrayController!

    @IBOutlet weak var advancedTableView: NSTableView!
    @IBOutlet weak var basicTableView: NSTableView!
    @IBOutlet weak var alterButton: NSButton!
    @objc dynamic var databases: [String] {
        return document?.database.allDatabases.map({ $0.name }) ?? []
    }

    @IBOutlet var selectStatementView: SQLiteTextView!

    @IBAction func toggleCreationType(_ sender: NSSegmentedControl) {
        definitionTabView.selectTabViewItem(at: sender.selectedSegment)
    }

    override func viewDidLoad() {
        columnArrayController.table = table
        tableConstraintArrayController.table = table
        super.viewDidLoad()

        if table.originalDefinition != nil {
            alterButton.title = NSLocalizedString("Modify Table", comment: "Modify table button title")
            createTabView.removeTabViewItem(at: 1)
            createTabView.tabViewBorderType = .none
            createTabView.tabPosition = .none
        } else {
            alterButton.title = NSLocalizedString("Create Table", comment: "Create table button title")
        }
        basicTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "private.table-row")])
        advancedTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "private.table-row")])

    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {

    }

    @IBAction func doAction(_ sender: NSButton) {
        let mainStoryboard = NSStoryboard(name: .main, bundle: .main)
        guard let waitingView = mainStoryboard.instantiateController(withIdentifier: "statementWaitingView") as? StatementWaitingViewController else {
            return
        }
        waitingView.delegate = self

        guard let selectedSegment = createTabView.selectedTabViewItem else {
            return
        }
        let index = createTabView.indexOfTabViewItem(selectedSegment)
        if index == 1 {
            let statement = "CREATE TABLE \(table.toDefinition.qualifiedNameForQuery) AS \(selectStatementView.string)"
            waitingView.operation = .statement(statement)

        } else {
            if table.originalDefinition != nil {
                waitingView.operation = .migrate(with: table)
            } else {
                waitingView.operation = .statement(table.toDefinition.createStatment)
            }
        }

        waitingView.representedObject = representedObject

        presentAsSheet(waitingView)

    }
}

extension CreateTableViewController: NSTableViewDataSource {
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: NSPasteboard.PasteboardType(rawValue: "private.table-row"))
        tableView.deselectAll(nil)
        return item
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return []
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        var oldIndexes = [Int]()
        info.enumerateDraggingItems(options: [], for: tableView, classes: [NSPasteboardItem.self], searchOptions: [:]) { (draggingItem, _, _) in
            if let str = (draggingItem.item as? NSPasteboardItem)?.string(forType: NSPasteboard.PasteboardType(rawValue: "private.table-row")), let index = Int(str) {
                oldIndexes.append(index)
            }
        }

        var oldIndexOffset = 0
        var newIndexOffset = 0

        for oldIndex in oldIndexes {
            if oldIndex < row {
                table.columns.swapAt(oldIndex + oldIndexOffset, row - 1)
                oldIndexOffset -= 1
            } else {
                table.columns.swapAt(oldIndex, row + newIndexOffset)
                newIndexOffset += 1
            }
        }
        tableView.deselectAll(nil)

        return true
    }
}

extension CreateTableViewController: StatementWaitingViewDelegate {
    func waitingView(_ view: StatementWaitingViewController, finishedSuccessfully: Bool) {
        dismiss(view)

        if finishedSuccessfully {
            dismiss(self)
            document?.database.refresh()
        }
    }
}

class CreateColumnArrayController: NSArrayController {
    var table: CreateTableDefinition!

    // overridden to add a new object to the content objects and to the arranged objects
    override func newObject() -> Any {
        let count = (arrangedObjects as? NSArray)?.count
        return CreateColumnDefinition(name: "Column \( (count ?? 0) + 1)", table: table)
    }
}

class CreateTableConstraintArrayController: NSArrayController {
    var table: CreateTableDefinition!

    // overridden to add a new object to the content objects and to the arranged objects
    override func newObject() -> Any {
        var type = CreateTableConstraintRowItem.TableConstraintType.primaryKey
        if let constraints = arrangedObjects as? [CreateTableConstraintRowItem], constraints.first(where: { $0.primaryKey != nil }) != nil {
            type = .unique

        }
        return CreateTableConstraintRowItem(type: type)
    }
}
