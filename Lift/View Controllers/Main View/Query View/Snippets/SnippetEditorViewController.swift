//
//  SnippetEditorViewController.swift
//  Lift
//
//  Created by Carl Wieland on 11/11/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

protocol SnippetEditorDelegate: class {
    func editor(_ editor: SnippetEditorViewController, didEdit: Snippet, at index: Int?)
}

class SnippetEditorViewController: NSViewController {

    var snippet: Snippet!

    @IBOutlet var snippetSQLView: SQLiteTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        name = snippet.name
        snippetDescription = snippet.description
        sql = snippet.sql
        if !snippetDescription.isEmpty {
            snippetSQLView.refresh()
        }
    }

    weak var delegate: SnippetEditorDelegate?

    var editingIndex: Int?

    @objc dynamic var name = "" {
        didSet {
            snippet.name = name
        }
    }

    @objc dynamic var snippetDescription = "" {
        didSet {
            snippet.description = snippetDescription
        }
    }

    @objc dynamic var sql = "" {
        didSet {
            snippet.sql = sql
        }
    }

    @IBAction func saveEdits(_ sender: Any) {
        delegate?.editor(self, didEdit: snippet, at: editingIndex)
    }
    
}
