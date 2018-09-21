//
//  ImportDataViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/29/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

protocol ImportDataDelegate: class {
    func closeImportView(_ vc: ImportDataViewController)
}

class ImportDataViewController: LiftViewController {

    let skipColumnTitle = NSLocalizedString("Don't Import", comment: "Don't import this column title")

    var data: [[Any?]]!
    @IBOutlet var columnArrayController: NSArrayController!
    @IBOutlet var tableArrayController: NSArrayController!
    private let newTableChoice = ImportTableChoice(name: "New Table", columns: [], table: nil)

    @IBOutlet weak var tableView: NSTableView!

    weak var delegate: ImportDataDelegate?

    @objc dynamic var importIntoChoices = [ImportTableChoice]()

    @objc dynamic var intoChoice: ImportTableChoice? {
        didSet {
            creatingNewTable = intoChoice === newTableChoice
            if let table = intoChoice, !creatingNewTable {
                for i in 0..<columnChoices.count {
                    if i < table.columns.count {
                        columnChoices[i].columnName = table.columns[i]
                    } else {
                        columnChoices[i].columnName = skipColumnTitle
                    }

                }
            } else if creatingNewTable {
                if let names = data.first as? [String] {
                    for i in 0..<names.count {
                        columnChoices[i].columnName = names[i]
                    }
                }
            }
        }
    }
    @objc dynamic var closeTabOnImport = true
    @objc dynamic var createInTempDatabase = false
    @objc dynamic var convertEmptyStringToNull = false
    @objc dynamic var convertHexStringToBlob = false
    @objc dynamic var skipFirstRow = false

    @objc dynamic var columnChoices = [ImportColumnChoice]()

    override func viewDidLoad() {
        super.viewDidLoad()

        while tableView.numberOfColumns > 0 {
            tableView.removeTableColumn(tableView.tableColumns[0])
        }

        if let firstRow = data.first {
            for i in 0..<firstRow.count {
                let newColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("\(i)"))
                let format = NSLocalizedString("Column %i", comment: "import column title, %@ replaced with the column number")
                newColumn.title = String(format: format, i + 1)
                tableView.addTableColumn(newColumn)
                columnChoices.append(ImportColumnChoice())
            }
            if let names = firstRow as? [String] {
                skipFirstRow = true
                for i in 0..<names.count {
                    columnChoices[i].columnName = names[i]
                }
            }

        }

        importIntoChoices.append(newTableChoice)

        intoChoice = newTableChoice

        guard let db = document?.database else {
            return
        }

        for database in db.allDatabases {
            for table in database.tables {
                importIntoChoices.append(ImportTableChoice(name: table.name, columns: table.columns.map({ $0.name }), table: table))
            }
        }
    }

    @objc dynamic var creatingNewTable = true {
        didSet {
            tableView.reloadData(forRowIndexes: IndexSet([0]), columnIndexes: IndexSet(0..<tableView.numberOfColumns))
        }
    }

    @IBAction func closeImport(_ sender: Any) {
        delegate?.closeImportView(self)
    }

    @IBAction func importData(_ sender: Any) {

        guard let database = document?.database else {
            let invalidName = NSAlert()
            invalidName.informativeText = NSLocalizedString("Missing database!", comment: "alert message when attempting to import without a database to import into")
            invalidName.messageText = NSLocalizedString("Unable to Import", comment: "Alert title for import error message")
            invalidName.runModal()
            return
        }

        guard (creatingNewTable && !(title?.isEmpty ?? true)) || intoChoice?.table != nil else {
            let invalidName = NSAlert()
            invalidName.informativeText = NSLocalizedString("Invalid or missing table name.", comment: "alert message when attempting to import without a table to import into")
            invalidName.messageText = NSLocalizedString("Unable to Import", comment: "Alert title for import error message")
            invalidName.runModal()
            return
        }

        var intoColumns = columnChoices.map({ $0.columnName })

        var importColumnIndexes = [Int]()
        var columnNamesForInsert = [String]()

        for (index, name) in intoColumns.enumerated() {
            if name.isEmpty {
                let invalidName = NSAlert()
                let format = NSLocalizedString("Empty column name in Column %i", comment: "alert message when attempting to import to a column with empty name")
                invalidName.informativeText = String(format: format, index + 1)
                invalidName.messageText = NSLocalizedString("Unable to Import", comment: "Alert title for import error message")
                invalidName.runModal()
                return
            }

            if name != skipColumnTitle {
                importColumnIndexes.append(index)
                columnNamesForInsert.append(name)
                if (index + 1) < intoColumns.count && intoColumns[(index + 1)..<intoColumns.count].contains(name) {
                    let invalidName = NSAlert()
                    let format = NSLocalizedString("Attempting to import into the same column twice: %@", comment: "alert message when attempting to import to the same column twice")
                    invalidName.informativeText = String(format: format, name)
                    invalidName.messageText = NSLocalizedString("Unable to Import", comment: "Alert title for import error message")
                    invalidName.runModal()
                    return
                }
            }
        }

        if importColumnIndexes.isEmpty {
            let invalidConfiguration = NSAlert()
            invalidConfiguration.informativeText = NSLocalizedString("No destination columns set", comment: "alert message when attempting to import without out any destination columns")
            invalidConfiguration.messageText = NSLocalizedString("Unable to Import", comment: "Alert title for import error message")
            invalidConfiguration.runModal()
            return
        }

        let intoTableName: String

        if creatingNewTable {
            guard let tableName = title, !tableName.isEmpty else {
                DispatchQueue.main.async {
                    let invalidName = NSAlert()
                    invalidName.informativeText = NSLocalizedString("Invalid or missing table name.", comment: "alert message when attempting to import without a table to import into")
                    invalidName.messageText = NSLocalizedString("Unable to Import", comment: "Alert title for import error message")
                    invalidName.runModal()
                }
                return
            }

            var tableBuilder = TableDefinition()
            tableBuilder.tableName = tableName

            tableBuilder.isTemp = createInTempDatabase

            for name in columnNamesForInsert {
                tableBuilder.columns.append(ColumnDefinition(name: name))
            }

            let createDef = tableBuilder.createStatment

            do {
                try database.exec(createDef)
            } catch {
                let createTableFail = NSAlert()
                createTableFail.messageText = NSLocalizedString("Unable to Import", comment: "Alert title for import error message")
                let format = NSLocalizedString("Unable to create destination table: %@", comment: "Failed to import into new table, failed to create the table. %@ replaced with error text")
                createTableFail.informativeText = String(format: format, error.localizedDescription)
                createTableFail.runModal()
                return
            }

            intoTableName = tableBuilder.qualifiedNameForQuery
        } else {
            guard let table = intoChoice?.table else {
                let invalidName = NSAlert()
                invalidName.informativeText = NSLocalizedString("Invalid or missing table name.", comment: "alert message when attempting to import without a table to import into")
                invalidName.messageText = NSLocalizedString("Unable to Import", comment: "Alert title for import error message")
                invalidName.runModal()
                return
            }
            intoTableName = table.qualifiedNameForQuery
        }

        var isCanceled = false

        guard let waitingVC = storyboard?.instantiateController(withIdentifier: "waitingOperationView") as? WaitingOperationViewController else {
            return
        }

        let cancelOp: () -> Void = {
            isCanceled = true
        }

        waitingVC.cancelHandler = cancelOp
        waitingVC.indeterminate = false
        let rowCount = Double(data.count)
        presentAsSheet(waitingVC)

        DispatchQueue.global(qos: .userInitiated).async {

            defer {
                DispatchQueue.main.async {
                    self.dismiss(waitingVC)
                }

            }

            let valuesClause = importColumnIndexes.map { "$\($0)" } .joined(separator: ", ")
            let columnClause = columnNamesForInsert.map { $0.sqliteSafeString() }.joined(separator: ", ")
            let insertQueryText = "INSERT INTO \(intoTableName)(\(columnClause)) VALUES (\(valuesClause));"

            do {
                let insertQuery = try Statement(connection: database.connection, text: insertQueryText)

                var skippedFirst = !self.skipFirstRow

                do {
                    for (rowIndex, row) in self.data.enumerated() {

                        if !skippedFirst {
                            skippedFirst = true
                            continue
                        }

                        if isCanceled {
                            break
                        }

                        for index in importColumnIndexes {
                            if index < row.count, let value = row[index] {
                                try insertQuery.bind(object: value )
                            } else {
                                try insertQuery.bindNull()
                            }
                        }
                        guard try insertQuery.step() else {
                            print("Invalid Step Response!")
                            return
                        }

                        insertQuery.reset()
                        DispatchQueue.main.async {
                            waitingVC.value = Double(rowIndex) / rowCount
                        }
                    }
                } catch {
                    print("Fail \(error)")
                }

            } catch {
                DispatchQueue.main.async {
                    let createTableFail = NSAlert()
                    createTableFail.messageText = NSLocalizedString("Unable to Import", comment: "Alert title for import error message")
                    let format = NSLocalizedString("Unable to create insert query, %@. Error: %@", comment: "Failed to import into new table, failed to create the table. %@ replaced with query and error text")
                    createTableFail.informativeText = String(format: format, insertQueryText, error.localizedDescription)
                    createTableFail.runModal()
                }
                return

            }

            if !isCanceled {
                DispatchQueue.main.async {
                    database.refresh()

                    if self.closeTabOnImport {
                        self.delegate?.closeImportView(self)
                    }
                }
            }

        }
    }
}

extension ImportDataViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data.count + 1
    }
}
extension ImportDataViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return row != 0
    }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch row {
        case 0:
            return 25
        default:
            return 19
        }
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        guard let tbCol = tableColumn, let column = tableView.tableColumns.index(of: tbCol) else {
            fatalError("Asking for column, not in table columns!")
        }

        if row == 0 {
            if creatingNewTable {
                // return a default data cell with that data
                guard let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("comboCell"), owner: nil) as? NSComboBox else {
                    return nil
                }
                view.removeAllItems()
                if let firstRow = data.first?.compactMap({ $0 }).map({ "\($0)" }) {
                    view.addItems(withObjectValues: firstRow)
                    view.addItem(withObjectValue: skipColumnTitle)
                    view.selectItem(at: column)
                }

                view.bind(NSBindingName.value, to: columnChoices[column], withKeyPath: #keyPath(ImportColumnChoice.columnName), options: nil)
                return view
            } else {
                // return a default data cell with that data
                guard let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("popupCell"), owner: nil) as? NSPopUpButton else {
                    return nil
                }

                view.removeAllItems()

                if let into = intoChoice {
                    view.addItems(withTitles: into.columns)
                }

                view.addItem(withTitle: skipColumnTitle)

                view.bind(NSBindingName.selectedValue, to: columnChoices[column], withKeyPath: #keyPath(ImportColumnChoice.columnName), options: nil)

                if let item = view.item(withTitle: columnChoices[column].columnName) {
                    view.select(item)
                } else if view.itemTitles.count > column {
                    view.selectItem(at: column)
                } else {
                    view.selectItem(withTitle: skipColumnTitle)
                }

                return view
            }
        } else {
            // return a default data cell with that data
            guard let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("defaultCell"), owner: nil) as? NSTableCellView else {
                return nil
            }

            let rowData = data[row - 1]
            if column < rowData.count, let value = rowData[column] {
                view.textField?.stringValue = "\(value)"
            } else {
                view.textField?.stringValue = ""
            }

            return view
        }
    }
}

class ImportTableChoice: NSObject {
    @objc dynamic let name: String
    @objc dynamic let columns: [String]
    let table: Table?
    init(name: String, columns: [String], table: Table?) {
        self.table = table
        self.name = name
        self.columns = columns
        super.init()
    }
}

class ImportColumnChoice: NSObject {
    @objc dynamic var columnName: String = ""
}
