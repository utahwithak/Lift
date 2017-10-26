//
//  TableDataViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/8/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa



class TableDataViewController: LiftMainViewController {

    @IBOutlet weak var tableView: TableView!
    @IBOutlet weak var tableScrollView: TableScrollView!

    let foreignKeyColumnColor = NSColor(calibratedRed:0.71, green:0.843, blue:1.0, alpha:0.5).cgColor

    let numberColor = NSColor(calibratedRed:0.2, green:0.403, blue:0.507, alpha:1)

    var data: TableData?
    var visibleRowCountBuffer: Int = 0


    var foreignKeyIdentifiers = Set<Int>()

    private var currentForeignKey: ForeignKeyJump?
    private var customStart: CustomTableStart?


    override var selectedTable: DataProvider? {
        didSet {
            clearTable()

            data = selectedTable?.basicData
            data?.delegate = self
            resetTableView()
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {

        super.prepare(for: segue, sender: sender)

        if let dest = segue.destinationController as? JumpToRowViewController {
            dest.delegate = self
        }
    }

    @IBAction func copy(_ sender: Any) {
        guard let selectionBox = tableView.selectionBoxes.first else {
            return
        }

        guard let data = data else {
            return
        }

        copySelection(selectionBox, fromData: data, asJson: false)
    }

    private func copySelection(_ selection: SelectionBox, fromData: TableData, asJson copyAsJSON: Bool) {

        guard let waitingVC = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("waitingOperationView")) as? WaitingOperationViewController else {
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

        presentViewControllerAsSheet(waitingVC)

        DispatchQueue.global(qos: .userInitiated).async {
            var pasteBoardString: String?

            if copyAsJSON {
                pasteBoardString = fromData.json(inSelection: selection, keepGoingCheck: keepGoing)
            } else {
                pasteBoardString = fromData.csv(inSelection: selection, keepGoingCheck: keepGoing)
            }
            DispatchQueue.main.async {
                self.dismissViewController(waitingVC)

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
        view.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(forName: NSView.frameDidChangeNotification , object: view, queue: nil) { [weak self] _ in
            guard let mySelf = self else {
                return
            }
            mySelf.visibleRowCountBuffer = mySelf.tableView.rows(in: mySelf.tableView.visibleRect).length * 4
        }
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
        for (index, toColumn) in jump.connection.toColumns.enumerated() {
            customStartQuery += "\(toColumn.sqliteSafeString()) = $\(index)"
        }

        customStart = CustomTableStart(query: customStartQuery, args: args)

        windowController?.selectedTable = toTable


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


        for (index,name) in columns.enumerated() where index > (newData.sortCount - 1) {

            let identifier = NSUserInterfaceItemIdentifier("\(index)")
            TableDataViewController.identifierMap[identifier] = index
            let newColumn = NSTableColumn(identifier: identifier)
            newColumn.title = name
            if fromColumns.contains(name) {
                foreignKeyIdentifiers.insert(index)
            }

            newColumn.width = 150
            tableView.addTableColumn(newColumn)
        }

        if newData.count > 0 {
            self.tableView.insertRows(at: IndexSet(0..<newData.count), withAnimation: [])
            visibleRowCountBuffer = tableView.rows(in: tableView.visibleRect).length * 4

        }

        if currentForeignKey != nil {
            tableView.selectRow(0)
        }

        currentForeignKey = nil
        customStart = nil


    }

}

extension TableDataViewController: TableDataDelegate {
    func tableDataDidPageNextIn(_ data: TableData, count: Int) {

        tableScrollView.lineNumberView.rowCount = data.count

        guard !tableView.tableColumns.isEmpty else {
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


        guard !tableView.tableColumns.isEmpty else {
            return
        }

        tableView.insertRows(at: IndexSet(0..<count), withAnimation: [])
        visibleRowCountBuffer = tableView.rows(in: tableView.visibleRect).length * 4
        tableView.scrollRowToVisible(middleRow + count)
    }
}

extension TableDataViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }

}

extension TableDataViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data?.count ?? 0
    }
    private static let cellIdentifier = NSUserInterfaceItemIdentifier("defaultCell")
    private static var identifierMap = [NSUserInterfaceItemIdentifier: Int]()
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn, let cell = tableView.makeView(withIdentifier: TableDataViewController.cellIdentifier, owner: self) as? TableViewCell,
            let data = data, let column = TableDataViewController.identifierMap[tableColumn.identifier] else {
            return nil
        }

        guard let textField = cell.textField else {
            return nil
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
            color = numberColor
        case .float:
            justification = .right
            color = numberColor
        }

        if foreignKeyIdentifiers.contains(column) {
            cell.layer?.backgroundColor = foreignKeyColumnColor
        } else {
            cell.layer?.backgroundColor = nil
        }

        if textField.alignment != justification {
           textField.alignment = justification
        }
        if textField.textColor != color {
            textField.textColor = color
        }

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 21
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let data = data else {
            return nil
        }
        if !data.finishedLoadingAfter && row > (data.count - visibleRowCountBuffer)  {
            data.loadNextPage()
        }

        if !data.finishedLoadingPrevious && row < visibleRowCountBuffer {
            data.loadPreviousPage()
        }

        return NSTableRowView()
    }

    
}


extension TableDataViewController: NSMenuDelegate {

    func menuNeedsUpdate(_ menu: NSMenu) {

        menu.removeAllItems()

        guard let selectionBox = tableView.selectionBoxes.first else {
            return
        }
        if selectionBox.singleCell {
            let columnIndex = selectionBox.startColumn
            let tableColumn = tableView.tableColumns[columnIndex]

            if let table = selectedTable as? Table, let index = Int(tableColumn.identifier.rawValue), foreignKeyIdentifiers.contains(index), let columns = data?.columnNames {
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
                        let fKeyMenuItem = NSMenuItem(title: String(format: jumpFormat, connection.toTable, connection.toColumns.joined(separator: ", ")), action: #selector(jumpToForeignKey), keyEquivalent: "")
                        fKeyMenuItem.representedObject = ForeignKeyJump(connection: connection, source: table)
                        subMenu.addItem(fKeyMenuItem)
                    }

                    menu.addItem(jumpToMenu)

                }
            }

        } else {

            menu.addItem(withTitle: NSLocalizedString("Copy as CSV", comment: "Copy csv menu item"), action: #selector(copyAsCSV), keyEquivalent: "")
            menu.addItem(withTitle: NSLocalizedString("Copy as JSON", comment: "Copy JSON menu item"), action: #selector(copyAsJSON), keyEquivalent: "")
        }
    }

    @objc private func copyAsCSV(_ sender: Any) {
        guard let data = data, let selectionBox = tableView.selectionBoxes.first else {
            return
        }
        copySelection(selectionBox, fromData: data, asJson: false)
    }

    @objc private func copyAsJSON(_ sender: Any) {
        guard let data = data, let selectionBox = tableView.selectionBoxes.first else {
            return
        }
        
        copySelection(selectionBox, fromData: data, asJson: true)

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

                guard let waitingVC = storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("waitingOperationView")) as? WaitingOperationViewController else {
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

                let completion = {
                    if waitingVC.presenting == self {
                        self.dismissViewController(waitingVC)
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
                    presentViewControllerAsSheet(waitingVC)
                }


            }

        }

    }
}
