//
//  CustomRowEditorViewController.swift
//  Lift
//
//  Created by Carl Wieland on 3/2/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class CustomRowEditorViewController: NSViewController {

    static let storyboardIdentifier = "editRowViewController"

    @IBOutlet weak var insertTypeConstraint: NSLayoutConstraint!
    var row: RowData?
    var columnNames: [String]!
    var sortCount: Int = 0
    @objc dynamic var creatingRow = false
    @IBOutlet weak var actionButton: NSButton!
    @objc dynamic var insertionType = NSNumber(value: 0)

    @IBOutlet var editValuesArrayController: NSArrayController!

    @IBOutlet var editView: NSTextView!

    var table: Table!

    override func viewDidLoad() {
        super.viewDidLoad()

        if !creatingRow, let row = row {
            for (index, name) in columnNames.enumerated() where index > (sortCount - 1) {
                editRows.append(EditRowData(data: row.data[index], column: name))
            }
        } else {
            for (index, name) in columnNames.enumerated() where index > (sortCount - 1) {
                editRows.append(EditRowData(column: name))
            }
        }
        actionButton.title = creatingRow ? NSLocalizedString("Add", comment: "Button title for adding new custom row") : NSLocalizedString("Update", comment: "Button title when editing custom row")
        editView.bind(NSBindingName.textColor, to: editValuesArrayController, withKeyPath: "selection.newValue.textColor", options: nil)
    }

    var selectedObject: EditRowData? {
        return editValuesArrayController.selectedObjects.first as? EditRowData
    }

    @objc dynamic var typeOptions: [String] {
        if creatingRow {
            return InsertOption.insertionOptions
        } else {
            return UpdateOption.updateOptions
        }
    }

    @IBAction func chooseFileForItem(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        panel.runModal()
        if let url = panel.url {
            selectedObject?.newValue.newValueType = .file(url)
        }
    }

    @IBAction func doAction(_ sender: Any) {

        if creatingRow {
            generateCreateRow()
        } else {
            generateUpdateQuery()
        }
    }

    @objc dynamic var editRows = [EditRowData]()

    private func generateCreateRow() {

        let insertionType = InsertOption(type: self.insertionType)
        var builder = insertionType.sql + " INTO " + table.qualifiedNameForQuery

        let editedColumns = CustomRowEditorViewController.editedColumns(in: editRows)

        if !editedColumns.isEmpty {
            builder += "(" + editedColumns.joined(separator: ", ") + ")"
        }

        var arguments = [String: SQLiteData]()
        if CustomRowEditorViewController.allDefaultValues(in: editRows) {
            builder += " DEFAULT VALUES"
        } else {
            let values = CustomRowEditorViewController.valueString(from: editRows)
            arguments = CustomRowEditorViewController.arguments(for: editRows)
            guard !values.isEmpty else {
                print("NO VALUES AND NOT DEFAULT VALUES!?")
                return
            }
            builder += " VALUES (" + values.joined(separator: ", ") + ")"

        }
        guard let waitingView = storyboard?.instantiateController(withIdentifier: "statementWaitingView") as? StatementWaitingViewController else {
            return
        }

        let operation: () throws -> Bool = {
            let query = try Statement(connection: self.table.connection, text: builder)
            try query.bind(arguments)
            return try query.step()
        }

        waitingView.delegate = self
        waitingView.operation = .customCall(operation)
        waitingView.representedObject = representedObject
        presentAsSheet(waitingView)

    }

    private func generateUpdateQuery() {
        let updateType = UpdateOption(type: self.insertionType)
        var builder = updateType.sql + " " + table.qualifiedNameForQuery + " SET"

        let editedColumns = CustomRowEditorViewController.editedColumns(in: editRows)

        let values = CustomRowEditorViewController.valueString(from: editRows)

        guard editedColumns.count == values.count else {
            return
        }

        var args = [String]()
        for i in 0..<editedColumns.count {
            args.append(" \(editedColumns[i].sqliteSafeString()) = \(values[i])")
        }
        builder += args.joined(separator: ", ") + " WHERE "

        var arguments = CustomRowEditorViewController.arguments(for: editRows)

        for i in 0..<sortCount {
            builder += "\(columnNames[i].sqliteSafeString()) = $whereArg\(i)"
            arguments["$whereArg\(i)"] = row?.data[i]
        }

        guard let waitingView = storyboard?.instantiateController(withIdentifier: "statementWaitingView") as? StatementWaitingViewController else {
            return
        }

        let operation: () throws -> Bool = {
            let query = try Statement(connection: self.table.connection, text: builder)
            try query.bind(arguments)
            return try query.step()
        }

        waitingView.delegate = self
        waitingView.operation = .customCall(operation)
        waitingView.representedObject = representedObject
        presentAsSheet(waitingView)

    }

    private static func editedColumns(in editRows: [EditRowData]) -> [String] {
        var columns = [String]()
        for row in editRows where row.hasChanges {
            columns.append(row.name.sqliteSafeString())
        }
        return columns
    }

    private static func allDefaultValues(in editRows: [EditRowData]) -> Bool {
        return editRows.first(where: { !$0.useDefaultValue }) == nil
    }

    private static func valueString(from editRows: [EditRowData]) -> [String] {
        var values = [String]()
        for (index, row) in editRows.enumerated() {
            if row.hasChanges, let value = row.valueString(index: index) {
                values.append(value)
            }
        }
        return values
    }

    private static func arguments(for editRows: [EditRowData]) -> [String: SQLiteData] {
        var values = [String: SQLiteData]()
        for (index, row) in editRows.enumerated() {
            if row.hasChanges, let value = row.argument() {
                values["$\(index)"] = value
            }
        }
        return values
    }

}

extension CustomRowEditorViewController: StatementWaitingViewDelegate {
    func waitingView(_ view: StatementWaitingViewController, finishedSuccessfully: Bool) {
        dismiss(view)

        if finishedSuccessfully {
            dismiss(self)
            table.refreshTableCount()
            if let document = representedObject as? LiftDocument {
                document.database.refresh()
            }
        }
    }
}
