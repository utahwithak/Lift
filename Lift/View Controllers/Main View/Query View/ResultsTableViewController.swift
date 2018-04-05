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

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var durationLabel: NSTextField!

    override func viewDidLoad() {
        while tableView.numberOfColumns > 0 {
            tableView.removeTableColumn(tableView.tableColumns[0])
        }

        for (index, name) in results.columnNames.enumerated() {

            let identifier = NSUserInterfaceItemIdentifier("\(index)")
            TableDataViewController.identifierMap[identifier] = index
            let newColumn = NSTableColumn(identifier: identifier)
            newColumn.title = name
            newColumn.width = 150
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
