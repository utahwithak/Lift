//
//  ResultsTableViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/13/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class ResultsTableViewController: NSViewController {
    var results: ExecuteQueryResult!

    @IBOutlet weak var tableView: TableView!
    @IBOutlet weak var durationLabel: NSTextField!
    @IBOutlet var copyMenu: NSMenu?

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "useFixedCellHeight")
    }

    override func viewDidLoad() {
        tableView.rowHeight = 19
        updateTableviewCellHeights()
        UserDefaults.standard.addObserver(self, forKeyPath: "useFixedCellHeight", options: [], context: nil)

        while tableView.numberOfColumns > 0 {
            tableView.removeTableColumn(tableView.tableColumns[0])
        }

        for (index, name) in results.columnNames.enumerated() {

            let identifier = NSUserInterfaceItemIdentifier("\(index)")
            TableDataViewController.identifierMap[identifier] = index
            let newColumn = NSTableColumn(identifier: identifier)
            newColumn.title = name
            newColumn.width = 150
            newColumn.minWidth = 150
            tableView.addTableColumn(newColumn)
        }

        if let tableScroll = tableView.enclosingScrollView as? TableScrollView {
            tableScroll.lineNumberView.rowCount = results.rows.count
        }

        if let duration = results.duration {
            let numberFormatter = NumberFormatter()
            numberFormatter.locale = NSLocale.current
            numberFormatter.numberStyle = .decimal
            numberFormatter.usesGroupingSeparator = true

            let ti = duration
            var seconds = duration
            while seconds >= 60 {
                seconds-=60
            }

            let minutes = (Int(ti) / 60) % 60
            let hours = (Int(ti) / 3600)
            guard let description = numberFormatter.string(from: results.rows.count as NSNumber) else {
                return
            }
            var text = "\(description) record"
            if results.rows.count != 1 {
                text.append("s")
            }
            text += " in"

            if hours > 0 {
                if hours != 1 {
                    text.append(String(format: NSLocalizedString(" %lu hours", comment: "hours description"), hours))
                } else {
                    text.append(NSLocalizedString(" 1 hour", comment: "hour description"))
                }
            }

            if minutes > 0 {
                if minutes != 1 {
                    text.append(String(format: NSLocalizedString(" %lu minutes", comment: "minutes description"), minutes))
                } else {
                    text.append(NSLocalizedString(" 1 minute", comment: "minutes description"))
                }
            }

            if seconds > 0 {
                if seconds != 1 {
                    text.append(String(format: NSLocalizedString("  %.3f seconds", comment: "seconds description"), seconds ))
                } else {
                    text.append(NSLocalizedString(" 1 second", comment: "second description"))
                }
            }

            durationLabel.stringValue = text

        } else {
            durationLabel.stringValue = ""
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "useFixedCellHeight" {
            updateTableviewCellHeights()
            tableView.noteHeightOfRows(withIndexesChanged: IndexSet(integersIn: 0..<tableView.numberOfRows))
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private func updateTableviewCellHeights() {
        if UserDefaults.standard.bool(forKey: "useFixedCellHeight") {
            tableView.usesAutomaticRowHeights = false
        } else {
            tableView.usesAutomaticRowHeights = true
        }
    }
}

extension ResultsTableViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return results.rows.count
    }

}

extension ResultsTableViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("dataRow"), owner: self) as? NSTableCellView, let textField = cellView.textField else {
            return nil
        }

        guard let columnIdentifier = tableColumn?.identifier, let column = TableDataViewController.identifierMap[columnIdentifier] else {
            return nil
        }

        let object = results.object(at: row, column: column)
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

        if textField.alignment != justification {
            textField.alignment = justification
        }
        if textField.textColor != color {
            textField.textColor = color
        }

        textField.layout()

        return cellView
    }
}

extension ResultsTableViewController: NSMenuDelegate {

    /// Selection box columns -> TableDataColumn
    var columnMap: [Int: Int] {
        var colMap = [Int: Int]()
        for tCol in 0..<tableView.numberOfColumns {
            let identifier = tableView.tableColumns[tCol].identifier
            colMap[tCol] = TableDataViewController.identifierMap[identifier]!
        }
        return colMap
    }

    private func copySelection(_ selection: SelectionBox, asJson copyAsJSON: Bool) {
        var validOp = true
        let keepGoing: () -> Bool = {
            return validOp
        }

        let doCopy: () -> String? = {
            var pasteBoardString: String?

            if copyAsJSON {
                pasteBoardString = RowData.json(from: self.results.rows, inSelection: selection, columnNames: self.results.columnNames, map: self.columnMap, keepGoingCheck: keepGoing)

            } else {
                pasteBoardString = RowData.csv(from: self.results.rows, inSelection: selection, map: self.columnMap, keepGoingCheck: keepGoing)
            }
            return pasteBoardString
        }

        if selection.isSingleCell {
            if let pasteBoardString = doCopy() {

                NSPasteboard.general.declareTypes([.string], owner: nil)
                NSPasteboard.general.setString(pasteBoardString, forType: .string)
            }
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
            let pasteBoardString: String? = doCopy()

            DispatchQueue.main.async {
                self.dismiss(waitingVC)
                if let pbStr = pasteBoardString {
                    NSPasteboard.general.declareTypes([.string], owner: nil)
                    NSPasteboard.general.setString(pbStr, forType: .string)
                }

            }
        }

    }

    @IBAction func copy(_ sender: Any) {
        guard let selectionBox = tableView.selectionBoxes.first else {
            return
        }

        copySelection(selectionBox, asJson: false)
    }

    @objc private func copyAsCSV(_ sender: Any) {
        guard let selectionBox = tableView.selectionBoxes.first else {
            return
        }
        copySelection(selectionBox, asJson: false)
    }

    @objc private func copyAsJSON(_ sender: Any) {
        guard let selectionBox = tableView.selectionBoxes.first else {
            return
        }

        copySelection(selectionBox, asJson: true)

    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        guard tableView.selectionBoxes.first != nil else {
            return
        }

        menu.addItem(withTitle: NSLocalizedString("Copy as CSV", comment: "Copy csv menu item"), action: #selector(copyAsCSV), keyEquivalent: "")
        menu.addItem(withTitle: NSLocalizedString("Copy as JSON", comment: "Copy JSON menu item"), action: #selector(copyAsJSON), keyEquivalent: "")
    }
}
