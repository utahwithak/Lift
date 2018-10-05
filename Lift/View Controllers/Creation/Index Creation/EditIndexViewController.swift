//
//  EditIndexViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class EditIndexViewController: LiftViewController {

    @IBOutlet weak var columnTableView: NSTableView!
    @IBOutlet var databaseController: NSArrayController!
    @IBOutlet var tableController: NSArrayController!

    private var isModifyingExisting = false

    @objc dynamic var existingIndex: Index? {
        willSet {
            willChangeValue(for: \.actionTitle)
        }
        didSet {
            didChangeValue(for: \.actionTitle)
            indexName = existingIndex?.name ?? ""
            guard let index = existingIndex, let parsedIndex = index.parsedIndex else {
                return
            }

            whereClause = parsedIndex.whereExpression
            useWhereClause = !(whereClause?.isEmpty ?? true)

            isIndexUnique = parsedIndex.unique
            if let database = index.database {
                databaseController.setSelectedObjects([database])
                if let table = database.tables.first(where: { $0.name == index.tableName }) {
                    tableController.setSelectedObjects([table])
                }
            }

            for column in parsedIndex.columns {
                indexColumns.append(CreateIndexedColumn(with: column))
            }

        }
    }

    @IBOutlet weak var whereClauseHeightConstraint: NSLayoutConstraint!
    @objc dynamic var useWhereClause = false {
        didSet {
            if isViewLoaded {
                whereClauseHeightConstraint.animator().constant = useWhereClause ? 100 : 0
            }
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let destination = segue.destinationController as? CreateIndexedColumnViewController {
            isModifyingExisting = false
            destination.table = tableController.selectedObjects.first as? Table
            destination.delegate = self
        }
    }

    @objc dynamic var whereClause: String?

    @objc dynamic var indexName: String = ""

    @objc dynamic var isIndexUnique = false

    @objc dynamic var actionTitle: String {
        if existingIndex != nil {
            return NSLocalizedString("editIndexViewController.actionTitle.Modify", value: "Modify", comment: "Button title when we are modifying existing index")
        } else {
            return NSLocalizedString("editIndexViewController.actionTitle.Modify", value: "Create", comment: "Button title when we are modifying existing index")
        }
    }

    @objc dynamic var tableIndexes: NSIndexSet? {
        didSet {
            indexColumns.removeAll()
        }
    }
    @objc dynamic var databaseIndexes: NSIndexSet? {
        didSet {
            indexColumns.removeAll()
        }
    }

    @objc dynamic var databases = [Database]()

    override var representedObject: Any? {
        didSet {
            self.databases = document?.database.allDatabases ?? []
        }
    }

    @objc dynamic var indexColumns = [CreateIndexedColumn]()

    class CreateIndexedColumn: NSObject {
        var column: IndexedColumn {
            willSet {
                willChangeValue(for: \.name)
            }
            didSet {
                didChangeValue(for: \.name)
            }
        }
        @objc dynamic public var name: String {
            return column.nameProvider.name
        }
        init(with column: IndexedColumn) {
            self.column = column
        }
    }

    override func viewDidLoad() {
         super.viewDidLoad()
        columnTableView.doubleAction = #selector(editSelectedColumn)
        columnTableView.target = self
        whereClauseHeightConstraint.constant = useWhereClause ? 100 : 0
    }

    @objc func editSelectedColumn(_ sender: Any) {
        if columnTableView.selectedRow >= 0 {
            let index = indexColumns[columnTableView.selectedRow]
            guard let createIndexedColumn = storyboard?.instantiateController(withIdentifier: "createIndexColumn") as? CreateIndexedColumnViewController else {
                return
            }
            createIndexedColumn.isModifying = true
            createIndexedColumn.table = self.tableController.selectedObjects.first as? Table
            createIndexedColumn.useCollation = index.column.collationName != nil
            createIndexedColumn.sortOrderIndex = index.column.sortOrder.rawValue

            if let column = index.column.nameProvider as? Column {
                createIndexedColumn.useColumn = true
                createIndexedColumn.columnArrayController.setSelectedObjects([column])

            } else {
                if let column = createIndexedColumn.table?.columns.first(where: { $0.name == index.column.nameProvider.name }) {
                    createIndexedColumn.useColumn = true
                    createIndexedColumn.columnArrayController.setSelectedObjects([column])
                } else {
                    createIndexedColumn.useColumn = false
                    createIndexedColumn.expression = index.column.nameProvider.name
                }
            }

            createIndexedColumn.collationName = index.column.collationName

            createIndexedColumn.delegate = self
            isModifyingExisting = true
            presentAsSheet(createIndexedColumn)

        }
    }

    @IBAction func performAction( _ sender: Any) {
        guard !indexName.isEmpty, !indexColumns.isEmpty, tableIndexes != nil else {
            return
        }
        let mainStoryboard = NSStoryboard(name: .main, bundle: .main)
        guard let waitingView = mainStoryboard.instantiateController(withIdentifier: "statementWaitingView") as? StatementWaitingViewController else {
            return
        }
        let operation: () throws -> Bool = { [weak self] in
            guard let database = self?.document?.database, let self = self else {
                return false
            }
            let savePointName = "DatumApps_CreateIndex"
            try database.beginSavepoint(named: savePointName)
            do {
                if let existingIndex = self.existingIndex {
                    try database.exec("DROP INDEX \(existingIndex.qualifiedName)")
                }

                var newQuery = "CREATE "
                if self.isIndexUnique {
                    newQuery += "UNIQUE "
                }
                newQuery += "INDEX "

                guard let dbIndex = self.databaseIndexes?.firstIndex, dbIndex >= 0 && dbIndex < self.databases.count, let table =  self.tableController.selectedObjects.first as? Table else {
                    return false
                }
                let intoDB = self.databases[dbIndex]
                newQuery += intoDB.name + "." + self.indexName.sqliteSafeString() + " ON " + table.name.sqliteSafeString() + "( "
                newQuery += self.indexColumns.map({ $0.column.sql }).joined(separator: ", ")
                newQuery += ") "
                if self.useWhereClause, let clause = self.whereClause, !clause.isEmpty {
                    newQuery += "WHERE \(clause)"
                }

                try database.exec(newQuery)
                try database.releaseSavepoint(named: savePointName)
                return true
            } catch {
                do {
                    try database.rollbackSavepoint(named: savePointName)
                    try database.releaseSavepoint(named: savePointName)

                } catch {
                    print("Failed to rollback savepoint!")
                }
                return false
            }

        }

        waitingView.delegate = self

        waitingView.operation = .customCall(operation)

        waitingView.representedObject = representedObject
        presentAsSheet(waitingView)

    }
}

extension EditIndexViewController: CreateIndexedColumnDelegate {
    func didFinish(with column: IndexedColumn) {
        if isModifyingExisting {
            guard let index = columnTableView.selectedRowIndexes.first, index >= 0 else {
                return
            }
            indexColumns[index].column = column

        } else {
            indexColumns.append(CreateIndexedColumn(with: column))
        }
    }
}

extension EditIndexViewController: StatementWaitingViewDelegate {
    func waitingView(_ view: StatementWaitingViewController, finishedSuccessfully: Bool) {
        dismiss(view)

        if finishedSuccessfully {
            document?.database.refresh()
            dismiss(self)
        }
    }
}
