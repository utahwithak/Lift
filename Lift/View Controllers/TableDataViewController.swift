//
//  TableDataViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/8/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TableDataViewController: LiftViewController {

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var tableScrollView: TableScrollView!

    weak var table: Table?

    override func viewDidLoad() {

        NotificationCenter.default.addObserver(self, selector: #selector(selectionChanged), name: .SelectionDataChanged, object: nil)

        clearTable()

    }

    @objc func selectionChanged(_ notification: Notification) {

        guard let browser = notification.object as? SideBarBrowseViewController else {
            return
        }
        clearTable()

        table = browser.selectedTable
        data = table?.basicData
        data?.delegate = self
        resetTableView()
    }



    var data: TableData?
    func clearTable() {
        tableView.beginUpdates()
        for column in tableView.tableColumns {
            tableView.removeTableColumn(column)
        }
        data = nil
        tableView.removeRows(at: IndexSet(0..<tableView.numberOfRows), withAnimation: .effectFade)

        tableView.endUpdates()


    }

    private func resetTableView() {


        guard let newData = data else {
            return
        }

        do {
            try newData.loadInitial()
        } catch {
            print("Failed to load initial:\(error)")
            return
        }

        guard let columns = newData.columnNames else {
            return
        }



        for (index,name) in columns.dropLast().enumerated() {
            let newColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("\(index)"))
            newColumn.title = name
            tableView.addTableColumn(newColumn)
        }
        if newData.count > 0 {
            tableView.beginUpdates()
            tableView.insertRows(at: IndexSet(0..<newData.count), withAnimation: [.effectFade,.slideDown])
            tableView.endUpdates()
        }

    }

}

extension TableDataViewController: TableDataDelegate {
    func tableDataDidChange(_ data: TableData) {

        tableScrollView.lineNumberView.rowCount = data.count

        guard !tableView.tableColumns.isEmpty else {
            return
        }
        let currentCount = tableView.numberOfRows
        let newCount = data.count

        tableView.beginUpdates()
        tableView.insertRows(at: IndexSet(currentCount..<newCount), withAnimation: [])
        tableView.endUpdates()

    }
}


extension TableDataViewController: NSTableViewDelegate {

}


extension TableDataViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data?.count ?? 0
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("defaultCell"), owner: nil) as? TableViewCell else {
            return nil
        }

        guard let data = data, let identifier = tableColumn?.identifier, let column = Int(identifier.rawValue) else {
            return nil
        }

        let object = data.object(at: row, column: column)

        switch object {
        case .text(let strVal):
            cell.textField?.stringValue = strVal
        case .blob(_):
            cell.textField?.stringValue = "<blob>"
        case .null:
            cell.textField?.stringValue = "null"
        case .integer(let int):
            cell.textField?.stringValue = "\(int)"
        case .float(let dbl):
            cell.textField?.stringValue = "\(dbl)"
        }

        let visibleRowCount = tableView.rows(in: tableView.visibleRect).length

        if !data.finishedLoading && row > (data.count - (4 * visibleRowCount))  {
            data.loadNextPage()
        }

        return cell
    }

}
