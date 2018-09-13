//
//  SnippetViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/10/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa
protocol SnippetDataDelegate: class {
    var currentSQL: String { get }
}

class SnippetViewController: LiftViewController {

    private let newSnippetIdentifier = "newSnippet"
    private let editSnippetIdentifer = "editSnippet"

    @IBOutlet weak var tableView: NSTableView!

    @IBOutlet var newSnippetMenu: NSMenu!
    @IBOutlet var rightClickMenu: NSMenu!

    public weak var snippetDataProvider: SnippetDataDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.doubleAction = #selector(editSnippet)
        tableView.target = self
        tableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])

    }

    @IBAction func duplicateSelected(_ sender: Any) {

        var selection = tableView.selectedRowIndexes

        if sender is NSMenuItem && tableView.clickedRow != -1 && !selection.contains(tableView.clickedRow) {
            selection.removeAll()
        }

        if selection.isEmpty && tableView.clickedRow != -1 {
            selection.insert(tableView.clickedRow)
        }

        tableView.beginUpdates()
        let preCount = SnippetManager.shared.numberOfSnippets
        for index in selection {
            let snippet = SnippetManager.shared.snippets[index]
            SnippetManager.shared.addNewSnippet(snippet)
        }
        let postcount = SnippetManager.shared.numberOfSnippets
        tableView.insertRows(at: IndexSet(preCount..<postcount), withAnimation: .effectFade)
        tableView.endUpdates()

    }

    @IBAction func removeSnippet(_ sender: Any) {
        var indexes = tableView.selectedRowIndexes

        if sender is NSMenuItem && tableView.clickedRow != -1 && !indexes.contains(tableView.clickedRow) {
            indexes.removeAll()
        }

        if indexes.isEmpty && tableView.clickedRow != -1 {
            indexes.insert(tableView.clickedRow)
        }

        guard !indexes.isEmpty else {
            return
        }
        tableView.beginUpdates()
        tableView.removeRows(at: indexes, withAnimation: NSTableView.AnimationOptions.effectFade)

        for index in indexes.reversed() {
            SnippetManager.shared.removeSnippet(at: index)
        }
        tableView.endUpdates()

    }

    @objc @IBAction func editSnippet(_ sender: Any) {
        if sender is NSMenuItem && tableView.clickedRow != -1 && (tableView.selectedRow != tableView.clickedRow || tableView.selectedRowIndexes.count > 1) {
            tableView.selectRowIndexes(IndexSet([tableView.clickedRow]), byExtendingSelection: false)
        }
        performSegue(withIdentifier: editSnippetIdentifer, sender: self)
    }

    @IBAction func createNewSnippet(_ sender: Any) {
        performSegue(withIdentifier: newSnippetIdentifier, sender: self)
    }

    @IBAction func createNewSnippetFromSQL(_ sender: Any) {
        guard let delegate = snippetDataProvider, let editorView = storyboard?.instantiateController(withIdentifier: "snippetEditorView") as? SnippetEditorViewController else {
            return
        }

        editorView.snippet = Snippet(name: "Current SQL", description: "", sql: delegate.currentSQL )
        editorView.delegate = self
        presentAsSheet(editorView)

    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == editSnippetIdentifer, let dest = segue.destinationController as? SnippetEditorViewController {
            let selection = tableView.selectedRow
            if selection >= 0 {
                dest.snippet = SnippetManager.shared.snippets[selection]
                dest.editingIndex = selection
            } else {
                dest.snippet = Snippet(name: "", description: "", sql: "")
            }
            dest.delegate = self

        } else if let dest = segue.destinationController as? SnippetEditorViewController {
            dest.snippet = Snippet(name: "", description: "", sql: "")
            dest.delegate = self
        }
    }
}

extension SnippetViewController: NSTableViewDelegate {

}

extension SnippetViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return SnippetManager.shared.numberOfSnippets
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("snippetTableCell"), owner: self)

        if let snippetView = view as? SnippetTableCellView {
            snippetView.objectValue = SnippetManager.shared.snippets[row]
        }

        return view
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 33
    }

    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        pboard.declareTypes([.string], owner: self)

        let sql = rowIndexes.sorted().map({ SnippetManager.shared.snippets[$0].sql }).joined(separator: "\n")

        pboard.setString(sql, forType: .string)
        return true
    }
}

extension SnippetViewController: SnippetEditorDelegate {
    func editor(_ editor: SnippetEditorViewController, didEdit snippet: Snippet, at index: Int?) {
        dismiss(editor)
        if let index = index {
            SnippetManager.shared.replace(at: index, with: snippet)
        } else {
            SnippetManager.shared.addNewSnippet(snippet)
        }
        tableView.reloadData()
    }
}
