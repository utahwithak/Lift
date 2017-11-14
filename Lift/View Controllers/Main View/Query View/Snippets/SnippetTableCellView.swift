//
//  SnippetTableCellView.swift
//  Lift
//
//  Created by Carl Wieland on 11/11/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class SnippetTableCellView: NSTableCellView {

    @IBOutlet var nameLabel: NSTextField!
    @IBOutlet var descriptionLabel: NSTextField!

    override var objectValue: Any? {
        didSet {
            guard let snippet = objectValue as? Snippet else {
                return
            }

            nameLabel.stringValue = snippet.name
            descriptionLabel.stringValue = snippet.description
        }
    }
}
