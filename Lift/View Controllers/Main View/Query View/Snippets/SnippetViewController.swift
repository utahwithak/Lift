//
//  SnippetViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/10/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class SnippetViewController: LiftViewController {


    @IBOutlet weak var tableView: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.doubleAction = #selector(editSnippet)
        tableView.target = self
        tableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
    }

    @IBAction func removeSnippet(_ sender: Any) {

    }

    @objc private func editSnippet(_ sender: Any) {
        performSegue(withIdentifier: NSStoryboardSegue.Identifier("editSnippet"), sender: self)
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier?.rawValue == "editSnippet", let dest = segue.destinationController as? SnippetEditorViewController {
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
        return 59
    }

    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        pboard.declareTypes([.string], owner: self)
        guard let first = rowIndexes.first else {
            return false
        }
        pboard.setString(SnippetManager.shared.snippets[first].sql, forType: .string)
        return true
    }
}

extension SnippetViewController: SnippetEditorDelegate {
    func editor(_ editor: SnippetEditorViewController, didEdit snippet: Snippet, at index: Int?) {
        dismissViewController(editor)
        if let index = index {
            SnippetManager.shared.replace(at: index, with: snippet)
        } else {
            SnippetManager.shared.addNewSnippet(snippet)
        }
        tableView.reloadData()
    }
}
