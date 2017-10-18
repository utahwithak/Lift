//
//  TableDataViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/8/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa



class TableDataViewController: LiftViewController {

    @IBOutlet weak var tableView: TableView!
    @IBOutlet weak var tableScrollView: TableScrollView!


    let foreignKeyColumnColor = NSColor(calibratedRed:0.71, green:0.843, blue:1.0, alpha:0.5).cgColor

    let numberColor = NSColor(calibratedRed:0.2, green:0.403, blue:0.507, alpha:1)

    override var selectedTable: Table? {
        didSet {
            clearTable()

            data = selectedTable?.basicData
            data?.delegate = self
            resetTableView()
        }
    }
    var data: TableData?

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

    var visibleRowCountBuffer: Int = 0


    var foreignKeyIdentifiers = Set<Int>()

    private var currentForeignKey: ForeignKeyConnection?
    private var customStart: CustomTableStart?

    @objc private func jumpToForeignKey(_ item: NSMenuItem) {
        guard let jump = item.representedObject as? ForeignKeyConnection else {
            print("Missing connection for jump!")
            return
        }

        currentForeignKey = jump

        guard let database = document?.database, let toTable = database.table(named: jump.toTable) else {
            print("Missing database")
            return
        }

        guard let data = data, let columnNames = data.columnNames, let selection = tableView.selectionBoxes.first?.startRow else {
            return
        }

        var args = [SQLiteData]()
        for column in jump.fromColumns {
            guard let colIndex = columnNames.index(of: column) else {
                fatalError("Missing column!")
            }

            args.append(data.object(at: selection, column: colIndex))
        }

        var customStartQuery = " WHERE "
        for (index, toColumn) in jump.toColumns.enumerated() {
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

        guard let newData = data, let table = selectedTable else {
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

        let fromColumns = Set<String>(table.foreignKeys.flatMap { $0.fromColumns })

        for (index,name) in columns.dropLast().enumerated() {
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

        let object = data.object(at: row, column: column)

        let justification: NSTextAlignment
        var color: NSColor?
        switch object {
        case .text(let strVal):
            cell.textField?.stringValue = strVal
            justification = .left
        case .blob(_):
            cell.textField?.stringValue = "<blob>"
            justification = .left
        case .null:
            cell.textField?.stringValue = "<null>"
            justification = .center
            color = NSColor.lightGray
        case .integer(let int):
            cell.textField?.stringValue = "\(int)"
            justification = .right
            color = numberColor
        case .float(let dbl):
            cell.textField?.stringValue = "\(dbl)"
            justification = .right
            color = numberColor
        }

        if foreignKeyIdentifiers.contains(column) {
            cell.layer?.backgroundColor = foreignKeyColumnColor
        } else {
            cell.layer?.backgroundColor = nil
        }

        if cell.textField?.alignment != justification {
            cell.textField?.alignment = justification
        }
        if cell.textField?.textColor != color {
            cell.textField?.textColor = color
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

            if let index = Int(tableColumn.identifier.rawValue), foreignKeyIdentifiers.contains(index), let columns = data?.columnNames, let table = selectedTable {
                let columnName = columns[index]

                let connections = table.foreignKeys(from: columnName)
                if connections.count == 1 {
                    let fKeyMenuItem = NSMenuItem(title: "Jump To Related", action: #selector(jumpToForeignKey), keyEquivalent: "")
                    fKeyMenuItem.representedObject = connections[0]
                    menu.addItem(fKeyMenuItem)

                } else {

                }
            }

        } else {
            print("Multiple Things!")
        }
    }

}
