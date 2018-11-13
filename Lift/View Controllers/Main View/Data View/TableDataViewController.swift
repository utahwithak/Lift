//
//  TableDataViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/8/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TableDataViewController: LiftMainViewController {

    public static var identifierMap = [NSUserInterfaceItemIdentifier: Int]()
    public static let numberColor = NSColor(calibratedRed: 0.2, green: 0.403, blue: 0.507, alpha: 1)

    @IBOutlet weak var filterButton: NSButton!
    @IBOutlet weak var tableView: TableView!
    @IBOutlet weak var tableScrollView: TableScrollView!

    override var representedObject: Any? {
        didSet {
            predicateViewController.representedObject = representedObject
        }
    }

    lazy var predicateViewController: TablePredicateViewController = {
        let predicateview = self.storyboard?.instantiateController(withIdentifier: "tablePredicateView") as? TablePredicateViewController

        return predicateview!
    }()

    var data: TableData?

    var visibleRowCountBuffer: Int = 0

    var foreignKeyIdentifiers = Set<Int>()

    private var currentForeignKey: ForeignKeyJump?
    private var customStart: CustomTableStart?

    /// Selection box columns -> TableDataColumn
    var columnMap: [Int: Int] {
        var colMap = [Int: Int]()
        for tCol in 0..<tableView.numberOfColumns {
            let identifier = tableView.tableColumns[tCol].identifier
            colMap[tCol] = TableDataViewController.identifierMap[identifier]!
        }
        return colMap
    }

    private var observationHandle: Any?

    override var selectedTable: DataProvider? {
        didSet {
            clearTable()
            data = selectedTable?.basicData
            data?.delegate = self
            resetTableView()

            observationHandle = windowController?.observe(\.selectedColumn, options: [], changeHandler: {[weak self] (windowController, _) in
                guard let self = self else {
                    return
                }
                if let column = windowController.selectedColumn, let columnIndex = self.selectedTable?.columns.index( where: { $0 === column}) {

                    let identifierNumber = columnIndex + (self.data?.sortCount ?? 0)
                    let identifier = NSUserInterfaceItemIdentifier("\(identifierNumber)")
                    let tableColumn = self.tableView.column(withIdentifier: identifier)
                    if tableColumn >= 0 {

                        self.tableView.selectionBoxes = [SelectionBox(startRow: 0, endRow: self.tableView.numberOfRows - 1, startColumn: tableColumn, endColumn: tableColumn)]
                    }

                }
            })
        }
    }

    private var queryString: String? {
        didSet {
            clearTable()

            if queryString?.isEmpty ?? true {
                filterButton.image = #imageLiteral(resourceName: "filter")
                data = selectedTable?.basicData
            } else {
                filterButton.image = #imageLiteral(resourceName: "highlightedFilter")
                if let provider = selectedTable {
                    data = TableData(provider: provider, customQuery: queryString)
                }
            }
            data?.delegate = self
            resetTableView()
        }
    }

    deinit {
        predicateViewController.removeObserver(self, forKeyPath: #keyPath(TablePredicateViewController.queryString))
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(TablePredicateViewController.queryString) {
            self.queryString = predicateViewController.queryString
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {

        super.prepare(for: segue, sender: sender)

        if let dest = segue.destinationController as? JumpToRowViewController {
            dest.delegate = self
        }
    }

    @objc private func doubleClickTable(_ sender: Any) {
        startEditingSelection()
    }

    fileprivate func startEditingSelection() {
        guard let selectionBox = tableView.selectionBoxes.first, selectionBox.isSingleCell else {
            return
        }

        guard let cell = tableView.view(atColumn: selectionBox.startColumn, row: selectionBox.startRow, makeIfNecessary: false) as? NSTableCellView else {
            return
        }

        let identifier = tableView.tableColumns[selectionBox.endColumn].identifier

        guard let colIndex = TableDataViewController.identifierMap[identifier] else {
            return
        }

        if let rowData = data?.object(at: selectionBox.endRow, column: colIndex), rowData.type != .blob {
            view.window?.makeFirstResponder(cell)
        }
    }

    @IBAction func copy(_ sender: Any) {
        guard let selectionBox = tableView.selectionBoxes.first else {
            return
        }

        guard let data = data else {
            return
        }

        copySelection(selectionBox, fromData: data, asJson: false, columnMap: columnMap)
    }
    @IBAction func performFindPanelAction(_ sender: Any?) {
        showFilter(nil)
    }

    @IBAction func dropSelected(_ sender: Any) {
        guard let database = document?.database, let table = selectedTable as? Table, table.isEditable else {
            return
        }
        guard let selectionBox = tableView.selectionBoxes.first else {
            return
        }

        guard let data = data else {
            return
        }
        var drop = true
        let isInAutocommit = database.autocommitStatus == .autocommit
        if isInAutocommit {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Drop Rows", comment: "Drop rows prompt title")

            alert.informativeText = NSLocalizedString("Are you sure you want to drop these rows?", comment: "Confirmation for dropping rows")
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()

            drop = response == NSApplication.ModalResponse.alertFirstButtonReturn
        }

        guard drop else {
            return
        }
        let savePointName = "DropRows\(Int(Date.timeIntervalSinceReferenceDate))"
        var customSavePoint = true
        do {
            try database.beginSavepoint(named: savePointName)
        } catch {
            customSavePoint = false
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Failed to Begin Savepoint", comment: "Save point warning prompt")

            let optionString: String
            if isInAutocommit {
                optionString = NSLocalizedString("Would you like to drop these rows immediately?", comment: "When in autocommit and we can't start savepoint")
            } else {
                optionString = NSLocalizedString("Would you like to drop these rows in the current transaction?", comment: "When in already in a transaction and we can't start savepoint")
            }

            alert.informativeText = String(format: NSLocalizedString("Unable to open a savepoint to help protect against corruption. %@\nError:%@", comment: "Confirmation for dropping rows outside of explicit savepoint"), optionString, error.localizedDescription)

            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()

            drop = response == .alertFirstButtonReturn
        }

        guard drop, let waitingVC = storyboard?.instantiateController(withIdentifier: "waitingOperationView") as? WaitingOperationViewController else {
            return
        }

        var validOp = true
        let cancelOp: () -> Void = {
            validOp = false
        }

        waitingVC.cancelHandler = cancelOp
        waitingVC.indeterminate = false

        presentAsSheet(waitingVC)

        DispatchQueue.global(qos: .userInitiated).async {

            do {
                var cur = 1.0
                let max = Double(selectionBox.endRow - selectionBox.startRow)
                let keepGoing: () -> Bool = { [weak waitingVC] in
                    DispatchQueue.main.async {
                        waitingVC?.value = cur / max
                        cur += 1
                    }
                    return validOp
                }
                try data.dropSelection(selectionBox, keepGoing: keepGoing)
                if customSavePoint {
                    if !keepGoing() {
                        try database.rollbackSavepoint(named: savePointName)
                    }
                    try database.releaseSavepoint(named: savePointName)

                }
            } catch {
                DispatchQueue.main.async {

                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Failed To Drop Rows", comment: "Drop failure prompt title")

                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Ok")
                    _ = alert.runModal()
                    if customSavePoint {
                        do {
                            try database.rollbackSavepoint(named: savePointName)
                            try database.releaseSavepoint(named: savePointName)

                        } catch {
                            NSApp.presentError(error)
                        }

                    }
                }
            }
            DispatchQueue.main.async {
                table.refreshTableCount()
                self.dismiss(waitingVC)
            }
        }
    }

    private func copySelection(_ selection: SelectionBox, fromData: TableData, asJson copyAsJSON: Bool, columnMap: [Int: Int]) {
        var validOp = true
        let keepGoing: () -> Bool = {
            return validOp
        }

        if selection.isSingleCell {
            var pasteBoardString = ""

            if copyAsJSON {
                pasteBoardString = fromData.json(inSelection: selection, map: columnMap, keepGoingCheck: keepGoing) ?? ""
            } else {
                pasteBoardString = fromData.csv(inSelection: selection, map: columnMap, keepGoingCheck: keepGoing) ?? ""

            }
            NSPasteboard.general.declareTypes([.string], owner: nil)
            NSPasteboard.general.setString(pasteBoardString, forType: .string)
            return
        }

        guard let waitingVC = storyboard?.instantiateController(withIdentifier: "waitingOperationView") as? WaitingOperationViewController else {
            return
        }

        let cancelOp: () -> Void = {
            validOp = false
        }

        waitingVC.cancelHandler = cancelOp
        waitingVC.indeterminate = true
        presentAsSheet(waitingVC)

        DispatchQueue.global(qos: .userInitiated).async {
            var pasteBoardString: String?

            if copyAsJSON {
                pasteBoardString = fromData.json(inSelection: selection, map: columnMap, keepGoingCheck: keepGoing)
            } else {
                pasteBoardString = fromData.csv(inSelection: selection, map: columnMap, keepGoingCheck: keepGoing)
            }
            DispatchQueue.main.async {
                self.dismiss(waitingVC)

                if let pbStr = pasteBoardString {
                    NSPasteboard.general.declareTypes([.string], owner: nil)
                    NSPasteboard.general.setString(pbStr, forType: .string)
                }

            }
        }

    }

    @IBAction func paste(_ sender: Any) {

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        visibleRowCountBuffer = tableView.rows(in: tableView.visibleRect).length * 4
        clearTable()
        tableView.doubleAction = #selector(doubleClickTable)
        tableView.target = self
        tableView.headerView = CustomTableHeaderView(frame: tableView.headerView?.frame ?? NSRect.zero)

        view.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(frameChanged), name: NSView.frameDidChangeNotification, object: view)

    }

    @objc private func frameChanged(_ noti: Notification) {
        visibleRowCountBuffer = tableView.rows(in: tableView.visibleRect).length * 4
    }

    @objc private func jumpToForeignKey(_ item: NSMenuItem) {
        guard let jump = item.representedObject as? ForeignKeyJump else {
            print("Missing connection for jump!")
            return
        }

        currentForeignKey = jump

        guard let database = jump.source.database, let toTable = database.table(named: jump.connection.toTable) else {
            let noTable = NSAlert()
            noTable.messageText = NSLocalizedString("Missing Table", comment: "Alert title for missing foreign key table jump")
            let informativeFormat =  NSLocalizedString("Failed to find table \"%@\" in database \"%@\"", comment: "Alert message for missing foreign key table jump")
            noTable.informativeText = String(format: informativeFormat, jump.connection.toTable, jump.source.database?.name ?? "")
            noTable.runModal()
            currentForeignKey = nil

            return
        }

        guard let data = data, let columnNames = data.columnNames, let selection = tableView.selectionBoxes.first?.startRow else {
            currentForeignKey = nil
            return
        }

        var args = [SQLiteData]()
        for column in jump.connection.fromColumns {
            guard let colIndex = columnNames.index(of: column) else {
                fatalError("Missing column!")
            }

            args.append(data.rawData(at: selection, column: colIndex))
        }

        var customStartQuery = " WHERE "
        if let toColumns = jump.connection.toColumns {
            for (index, toColumn) in toColumns.enumerated() {
                customStartQuery += "\(toColumn.sqliteSafeString()) = $\(index)"
            }
        } else {
            let primaryKeys = toTable.columns.filter({$0.isPrimaryKey})
            for (index, toColumn) in primaryKeys.enumerated() {
                customStartQuery += "\(toColumn.name.sqliteSafeString()) = $\(index)"
            }
        }

        customStart = CustomTableStart(query: customStartQuery, args: args)

        windowController?.selectedTable = toTable

    }

    @objc private func viewReferences(_ item: NSMenuItem) {
        guard let selectionBox = tableView.selectionBoxes.first, selectionBox.isSingleCell else {
            return
        }
        let selectionRow = selectionBox.startRow
        let columnIndex = selectionBox.startColumn
        let tableColumn = tableView.tableColumns[columnIndex]

        guard let table = selectedTable as? Table else {
            return
        }

        if let index = Int(tableColumn.identifier.rawValue), let data = data, let columns = data.columnNames, table.isDestination(column: columns[index]) {
            if let SQL = table.referencesSQL(from: data, row: selectionRow, columnName: columns[index]) {
                windowController?.showQueryView(with: SQL)
            }
        }

    }

    func clearTable() {

        tableView.deselectAll(self)
        for column in tableView.tableColumns {
            tableView.removeTableColumn(column)
        }
        data = nil
        tableScrollView?.lineNumberView.rowCount = 0
        tableView.removeRows(at: IndexSet(0..<tableView.numberOfRows), withAnimation: .effectFade)
        foreignKeyIdentifiers.removeAll(keepingCapacity: true)

    }

    private func resetTableView() {

        guard let newData = data else {
            return
        }

        do {
            try newData.loadInitial(customStart: customStart)
            if customStart != nil {
                newData.loadPreviousPage()
                newData.loadNextPage()
            }
        } catch {
            print("Failed to load initial:\(error)")
            return
        }

        guard let columns = newData.columnNames else {
            return
        }

        let fromColumns: Set<String>
        if let table = selectedTable as? Table {
            fromColumns = Set<String>(table.foreignKeys.flatMap { $0.fromColumns })
        } else {
            fromColumns = Set<String>()
        }

        for (index, name) in columns.enumerated() where index > (newData.sortCount - 1) {

            let identifier = NSUserInterfaceItemIdentifier("\(index)")
            TableDataViewController.identifierMap[identifier] = index
            let newColumn = NSTableColumn(identifier: identifier)
            newColumn.title = name
            if fromColumns.contains(name) {
                foreignKeyIdentifiers.insert(index)
            }

            newColumn.width = 150
            tableView.addTableColumn(newColumn)
            newColumn.sortDescriptorPrototype = NSSortDescriptor(key: name, ascending: true, selector: #selector(NSString.localizedCompare))
        }

        if newData.count > 0 {
            self.tableView.insertRows(at: IndexSet(0..<newData.count), withAnimation: [])
            visibleRowCountBuffer = tableView.rows(in: tableView.visibleRect).length * 4

        }

        if currentForeignKey != nil, tableView.numberOfRows > 0 {
            tableView.selectRow(0)
        }

        currentForeignKey = nil
        customStart = nil

    }

    /// Update the row/column to the value
    ///
    /// - Parameters:
    ///   - row: Row of the data we want to edit
    ///   - rawCol: the raw tableview column. We then convert to the real column based on identifier
    ///   - value: new value we want to set it to
    /// - Returns: `true` if successful and we want to keep editing, `false` otherwise.
    fileprivate func set(row: Int, rawCol: Int, to value: SimpleUpdateType) -> Bool {
        guard let data = data else {
            return false
        }

        guard let realColumn = TableDataViewController.identifierMap[tableView.tableColumns[rawCol].identifier] else {
            return false
        }

        do {
            switch try data.set(row: row, column: realColumn, to: value) {
            case .updated:
                tableView.reloadData(forRowIndexes: IndexSet([row]), columnIndexes: IndexSet([rawCol]))
                return true
            case .removed:
                tableView.deselectAll(self)
                tableView.removeRows(at: IndexSet([row]), withAnimation: .effectFade)
                let alert = NSAlert()
                alert.informativeText = NSLocalizedString("Row has been moved, would you like to refresh the table to find it?", comment: "Message when editing a row that disappears")
                alert.messageText = NSLocalizedString("Row Moved", comment: "Alert title")
                alert.addButton(withTitle: NSLocalizedString("Reload", comment: "button title"))
                alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "button title"))
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    for column in tableView.tableColumns {
                        tableView.removeTableColumn(column)
                    }
                    tableScrollView?.lineNumberView.rowCount = 0
                    tableView.removeRows(at: IndexSet(0..<tableView.numberOfRows), withAnimation: .effectFade)
                    resetTableView()
                    return false
                } else {
                    return true
                }
            case .failed:
                print("failed!")
                return false
            }
        } catch {
            presentError(error)
            tableView.reloadData(forRowIndexes: IndexSet([row]), columnIndexes: IndexSet([rawCol]))
            return false
        }
    }

    @IBAction func addDefaultValues(_ sender: NSButton) {

        guard isEditingEnabled, let data = data else {
            return
        }

        do {
            _ = try data.addDefaultValues()
        } catch {
            presentError(error)
        }
    }

    @IBAction func addCustomValues(_ sender: NSButton) {
        guard let table = selectedTable as? Table, isEditingEnabled else {
            return
        }

        guard let customRowEditor = storyboard?.instantiateController(withIdentifier: CustomRowEditorViewController.storyboardIdentifier) as? CustomRowEditorViewController else {
            print("failed to create row data")
            return
        }
        customRowEditor.delegate = self
        customRowEditor.table = table
        customRowEditor.sortCount = 0
        customRowEditor.columnNames = table.columns.map({ $0.name })
        customRowEditor.creatingRow = true
        presentAsSheet(customRowEditor)

    }

    @IBAction func showFilter(_ sender: NSButton?) {
        windowController?.toggleBottomBar()
    }

}

extension TableDataViewController: CustomRowEditorDelegate {
    func didFinishEditingRow(created: Bool) {
        if created {

            guard let data = data, let waitingVC = storyboard?.instantiateController(withIdentifier: "waitingOperationView") as? WaitingOperationViewController else {
                return
            }

            var validOp = true
            let keepGoing: () -> Bool = {
                return validOp
            }

            let cancelOp: () -> Void = {
                validOp = false
            }

            waitingVC.cancelHandler = cancelOp
            waitingVC.indeterminate = true
            let completion = {
                if waitingVC.presentingViewController == self {
                    self.dismiss(waitingVC)
                }
                self.tableScrollView.lineNumberView.rowCount = data.count

                let currentCount = self.tableView.numberOfRows
                let newCount = data.count
                self.tableView.insertRows(at: IndexSet(currentCount..<newCount), withAnimation: [])

                self.tableView.scrollRowToVisible(self.tableView.numberOfRows - 1)

            }
            let isLoading = data.didAddRow(completion: completion, keepGoing: keepGoing)
            if isLoading {
                presentAsSheet(waitingVC)
            }

        } else {
            if let table = selectedTable as? Table, table.definition?.withoutRowID ?? true {
                guard let data = data, let waitingVC = storyboard?.instantiateController(withIdentifier: "waitingOperationView") as? WaitingOperationViewController else {
                    return
                }

                var validOp = true
                let keepGoing: () -> Bool = {
                    return validOp
                }

                let cancelOp: () -> Void = {
                    validOp = false
                }

                waitingVC.cancelHandler = cancelOp
                waitingVC.indeterminate = true
                let completion = {
                    if waitingVC.presentingViewController == self {
                        self.dismiss(waitingVC)
                    }
                    self.tableScrollView.lineNumberView.rowCount = data.count
                    self.tableView.reloadData()
                }
                data.refreshAll(completion: completion, keepGoing: keepGoing)

                presentAsSheet(waitingVC)

            } else if let selectedRow = tableView.selectionBoxes.first?.startRow {
                data?.reloadRow(at: selectedRow)
                tableView.reloadData(forRowIndexes: IndexSet([selectedRow]), columnIndexes: IndexSet(0..<tableView.numberOfColumns))
            }

        }
    }
}

extension TableDataViewController: TableDataDelegate {
    func tableDataDidPageNextIn(_ data: TableData, count: Int) {

        tableScrollView.lineNumberView.rowCount = data.count

        guard !tableView.tableColumns.isEmpty, count > 0 else {
            return
        }

        let currentCount = tableView.numberOfRows
        let newCount = data.count

        tableView.insertRows(at: IndexSet(currentCount..<newCount), withAnimation: [])
        visibleRowCountBuffer = tableView.rows(in: tableView.visibleRect).length * 4

    }

    func tableDataDidPagePreviousIn(_ data: TableData, count: Int) {

        tableScrollView.lineNumberView.rowCount = data.count

        let vislbeRange = tableView.rows(in: tableView.visibleRect)
        let middleRow = (vislbeRange.upperBound + vislbeRange.lowerBound)/2

        guard !tableView.tableColumns.isEmpty, count > 0 else {
            return
        }

        tableView.insertRows(at: IndexSet(0..<count), withAnimation: [])
        visibleRowCountBuffer = tableView.rows(in: tableView.visibleRect).length * 4
        tableView.scrollRowToVisible(middleRow + count)
    }
    func tableData(_ data: TableData, didRemoveRows indexSet: IndexSet) {
        tableView.removeRows(at: indexSet, withAnimation: NSTableView.AnimationOptions.effectFade)
        tableView.selectionBoxes = []
        tableScrollView.lineNumberView.rowCount = data.count

    }
}

extension TableDataViewController: NSTableViewDelegate {

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool {
        return true
    }
}

extension TableDataViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return data?.count ?? 0
    }

    private static let cellIdentifier = NSUserInterfaceItemIdentifier("defaultCell")

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn, let cell = tableView.makeView(withIdentifier: TableDataViewController.cellIdentifier, owner: self) as? TableViewCell,
            let data = data, let column = TableDataViewController.identifierMap[tableColumn.identifier] else {
            return nil
        }

        guard let textField = cell.textField else {
            return nil
        }
        if textField.delegate == nil {
            textField.delegate = self
        }

        let object = data.object(at: row, column: column)
        textField.stringValue = object.displayValue
        let justification: NSTextAlignment
        var color: NSColor?
        switch object.type {
        case .text:
            justification = .left
        case .blob:
            justification = .left
        case .null:
            justification = .center
            color = NSColor.lightGray
        case .integer:
            justification = .right
            color = TableDataViewController.numberColor
        case .float:
            justification = .right
            color = TableDataViewController.numberColor
        }

        if foreignKeyIdentifiers.contains(column) {
            cell.layer?.backgroundColor = NSColor(named: "foreignKeyHighlight")?.cgColor
        } else {
            cell.layer?.backgroundColor = nil
        }

        if textField.alignment != justification {
           textField.alignment = justification
        }
        if textField.textColor != color {
            textField.textColor = color
        }

        textField.layout()

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 21
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let data = data else {
            return nil
        }
        if !data.finishedLoadingAfter && row > (data.count - visibleRowCountBuffer) {
            data.loadNextPage()
        }

        if !data.finishedLoadingPrevious && row < visibleRowCountBuffer {
            data.loadPreviousPage()
        }

        return NSTableRowView()
    }

}

extension TableDataViewController: NSMenuDelegate {

    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        guard let provider = selectedTable else {
            return
        }
        let sortOrders: [ColumnSort]
        if let curData = data {
            var curOrders = curData.customOrdering
            if let index = curOrders.index(where: { $0.column == tableColumn.title}) {
                if curOrders[index].asc {
                    curOrders[index].asc = false
                } else {
                    curOrders.remove(at: index)
                }
            } else {
                curOrders.append(ColumnSort(column: tableColumn.title, asc: true))
            }
            sortOrders = curOrders
        } else {
            sortOrders = [ColumnSort(column: tableColumn.title, asc: true)]
        }
        clearTable()
        data = TableData(provider: provider, customQuery: queryString, customSorting: sortOrders)
        data?.delegate = self
        resetTableView()
        self.tableView.sortOrders = sortOrders
    }

    func menuNeedsUpdate(_ menu: NSMenu) {

        menu.removeAllItems()

        guard let selectionBox = tableView.selectionBoxes.first else {
            return
        }

        if selectionBox.isSingleCell {
            let columnIndex = selectionBox.startColumn
            let tableColumn = tableView.tableColumns[columnIndex]

            if let table = selectedTable as? Table {
                if let index = Int(tableColumn.identifier.rawValue), foreignKeyIdentifiers.contains(index), let columns = data?.columnNames {
                    let columnName = columns[index]

                    let connections = table.foreignKeys(from: columnName)
                    if connections.count == 1 {
                        let fKeyMenuItem = NSMenuItem(title: NSLocalizedString("Jump To Related", comment: "Jump to foreign key menu item"), action: #selector(jumpToForeignKey), keyEquivalent: "")
                        fKeyMenuItem.representedObject = ForeignKeyJump(connection: connections[0], source: table)
                        menu.addItem(fKeyMenuItem)

                    } else {

                        let jumpToMenu = NSMenuItem(title: NSLocalizedString("Jump To...", comment: "Jump to menu item title, opens to show other jumps"), action: nil, keyEquivalent: "")
                        let subMenu = NSMenu()
                        jumpToMenu.submenu = subMenu
                        for connection in connections {
                            let jumpFormat = NSLocalizedString("Jump to %@, (%@)", comment: "Jump foreign key with multiple, first %@ will be table name, second is columns in the foreign key")
                            let pkeysTo: String = connection.fromColumns.count == 1 ? NSLocalizedString("Primary Key", comment: "Jump to single primary key") :  NSLocalizedString("Primary Keys", comment: "Jump to multiple primary keys")

                            let toColumns = connection.toColumns?.joined(separator: ", ") ?? pkeysTo
                            let fKeyMenuItem = NSMenuItem(title: String(format: jumpFormat, connection.toTable, toColumns), action: #selector(jumpToForeignKey), keyEquivalent: "")
                            fKeyMenuItem.representedObject = ForeignKeyJump(connection: connection, source: table)
                            subMenu.addItem(fKeyMenuItem)
                        }

                        menu.addItem(jumpToMenu)

                    }
                }

                if let index = Int(tableColumn.identifier.rawValue), let columns = data?.columnNames, table.isDestination(column: columns[index]) {
                    let referencedMenuItem = NSMenuItem(title: NSLocalizedString("View References", comment: "SQL to view places that reference this cell menu item"), action: #selector(viewReferences), keyEquivalent: "")
                    menu.addItem(referencedMenuItem)
                }

                if table.isEditable {
                    let editRow = NSMenuItem(title: NSLocalizedString("Edit Row", comment: "menu item for editing entire row"), action: #selector(editSelectedRow), keyEquivalent: "")
                    editRow.representedObject = table
                    menu.addItem(editRow)

                    let setToMenu = NSMenuItem(title: NSLocalizedString("Set To...", comment: "set to menu item title, opens to show default values"), action: nil, keyEquivalent: "")
                    let subMenu = NSMenu()
                    setToMenu.submenu = subMenu
                    for type in SimpleUpdateType.allVals {
                        let updateItem = NSMenuItem(title: type.title, action: #selector(setToType), keyEquivalent: "")
                        updateItem .representedObject = type
                        subMenu.addItem(updateItem )
                    }
                    menu.addItem(setToMenu)

                    let identifier = tableView.tableColumns[selectionBox.endColumn].identifier

                    guard let colIndex = TableDataViewController.identifierMap[identifier] else {
                        return
                    }

                    if let rowData = data?.rawData(at: selectionBox.endRow, column: colIndex) {
                        // drop the first one since it is the existing type.
                        //
                        let conversionsAvailable = NewRowValueTypeConversion.conversionTypes(for: rowData).dropFirst()
                        if !conversionsAvailable.isEmpty {
                            let convertMenu = NSMenuItem(title: NSLocalizedString("Convert Value To...", comment: "set to menu item title, opens to show conversion types"), action: nil, keyEquivalent: "")
                            let subMenu = NSMenu()
                            convertMenu.submenu = subMenu
                            for type in conversionsAvailable {
                                let convertItem = NSMenuItem(title: type.name, action: #selector(convertToType), keyEquivalent: "")
                                convertItem.representedObject = type
                                subMenu.addItem(convertItem)
                            }
                            menu.addItem(convertMenu)
                        }
                    }

                }

            }

        } else if selectionBox.isSingleRow, let table = selectedTable as? Table, table.isEditable {

            let editRow = NSMenuItem(title: NSLocalizedString("Edit Row", comment: "menu item for editing entire row"), action: #selector(editSelectedRow), keyEquivalent: "")
            editRow.representedObject = table
            menu.addItem(editRow)
        }
        menu.addItem(withTitle: NSLocalizedString("Copy as CSV", comment: "Copy csv menu item"), action: #selector(copyAsCSV), keyEquivalent: "")
        menu.addItem(withTitle: NSLocalizedString("Copy as JSON", comment: "Copy JSON menu item"), action: #selector(copyAsJSON), keyEquivalent: "")

    }

    @objc private func convertToType(_ sender: NSMenuItem) {
        guard let selectionBox = tableView.selectionBoxes.first, let type = sender.representedObject as? NewRowValueTypeConversion else {
            return
        }

        let identifier = tableView.tableColumns[selectionBox.endColumn].identifier

        guard let colIndex = TableDataViewController.identifierMap[identifier] else {
            return
        }

        if let rowData = data?.rawData(at: selectionBox.endRow, column: colIndex) {
            let newData = NewRowValueTypeConversion.convert(data: rowData, with: type)
            _ = set(row: selectionBox.startRow, rawCol: selectionBox.startColumn, to: .rawData(newData))
        }
    }

    @objc private func setToType(_ sender: NSMenuItem) {
        guard let selectionBox = tableView.selectionBoxes.first, selectionBox.isSingleCell, let type = sender.representedObject as? SimpleUpdateType else {
            return
        }

        _ = set(row: selectionBox.startRow, rawCol: selectionBox.startColumn, to: type)
    }

    @objc private func editSelectedRow(_ sender: NSMenuItem) {
        guard let selectionBox = tableView.selectionBoxes.first, let rowData = data?.rowdata(at: selectionBox.startRow), let columnNames = data?.columnNames, let sortCount = data?.sortCount, let table = selectedTable as? Table, isEditingEnabled  else {
            return
        }

        guard let editViewController = storyboard?.instantiateController(withIdentifier: CustomRowEditorViewController.storyboardIdentifier) as? CustomRowEditorViewController else {
            print("Unable to create edit row VC")
            return
        }
        editViewController.representedObject = representedObject
        editViewController.table = table
        editViewController.sortCount = sortCount
        editViewController.columnNames = columnNames
        editViewController.row = rowData
        editViewController.delegate = self
        presentAsSheet(editViewController)

    }

    @objc private func copyAsCSV(_ sender: Any) {
        guard let data = data, let selectionBox = tableView.selectionBoxes.first else {
            return
        }
        copySelection(selectionBox, fromData: data, asJson: false, columnMap: columnMap)
    }

    @objc private func copyAsJSON(_ sender: Any) {
        guard let data = data, let selectionBox = tableView.selectionBoxes.first else {
            return
        }

        copySelection(selectionBox, fromData: data, asJson: true, columnMap: columnMap)

    }
}

extension TableDataViewController: JumpDelegate {
    func jumpView(_ view: JumpToRowViewController, jumpTo: Int?) {
        guard let row = jumpTo else {
            return
        }

        if row - 1 < tableView.numberOfRows {
            tableView.scrollRowToVisible(row - 1)
            tableView.selectRow(row - 1, column: nil)

        } else if let data = data {
            if data.finishedLoadingAfter {
                NSSound.beep()
            } else {
                // Page in as many rows as we can... up to row

                guard let waitingVC = storyboard?.instantiateController(withIdentifier: "waitingOperationView") as? WaitingOperationViewController else {
                    return
                }

                var validOp = true
                let keepGoing: () -> Bool = {
                    return validOp
                }

                let cancelOp: () -> Void = {
                    validOp = false
                }

                waitingVC.cancelHandler = cancelOp
                waitingVC.indeterminate = true
                let completion = {
                    if waitingVC.presentingViewController == self {
                        self.dismiss(waitingVC)
                    }
                    self.tableScrollView.lineNumberView.rowCount = data.count

                    let currentCount = self.tableView.numberOfRows
                    let newCount = data.count
                    self.tableView.insertRows(at: IndexSet(currentCount..<newCount), withAnimation: [])
                    if row - 1 < self.tableView.numberOfRows {
                        self.tableView.scrollRowToVisible(row - 1)
                        self.tableView.selectRow(row - 1, column: nil)
                    } else {
                        NSSound.beep()
                        self.tableView.scrollRowToVisible(self.tableView.numberOfRows - 1)

                    }

                }
                let isLoading = data.loadToRowVisible(row, completion: completion, keepGoing: keepGoing)
                if isLoading {
                    presentAsSheet(waitingVC)
                }

            }

        }

    }
}

extension TableDataViewController: NSTextFieldDelegate {
    func controlTextDidBeginEditing(_ obj: Notification) {
        guard let selectionBox = tableView.selectionBoxes.first, selectionBox.isSingleCell else {
            return
        }

        guard let textField = obj.object as? NSTextField else {
            return
        }

        textField.textColor = NSColor.textColor
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let selectionBox = tableView.selectionBoxes.first, selectionBox.isSingleCell else {
            return
        }

        guard let textField = obj.object as? NSTextField else {
            return
        }

        guard set(row: selectionBox.startRow, rawCol: selectionBox.startColumn, to: .argument(textField.stringValue)) else {
            return
        }
        textField.isEditable = false

        if let rawMovement = obj.userInfo?["NSTextMovement"] as? Int, let movement = NSTextMovement(rawValue: rawMovement) {

            switch movement {
            case .down, .return:
                self.tableView.selectRow(min(selectionBox.startRow + 1, tableView.numberOfRows - 1), column: selectionBox.startColumn)
                DispatchQueue.main.async {
                    self.startEditingSelection()
                }
            case .tab, .right:
                self.tableView.selectRow(selectionBox.startRow, column: min(selectionBox.startColumn + 1, tableView.numberOfColumns - 1))
            case .backtab, .left:
                self.tableView.selectRow(selectionBox.startRow, column: max(0, selectionBox.startColumn - 1))
                DispatchQueue.main.async {
                    self.startEditingSelection()
                }
            case .up:
                self.tableView.selectRow(max(0, selectionBox.startRow - 1), column: selectionBox.startColumn)
            default:
                break
            }
        }
    }
}

extension TableDataViewController: BottomEditorContentProvider {

    var editorViewController: LiftViewController {
        predicateViewController.addObserver(self, forKeyPath: #keyPath(TablePredicateViewController.queryString), options: [], context: nil)
        return self.predicateViewController
    }

}
