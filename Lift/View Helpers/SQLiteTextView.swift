//
//  SQLiteTextView.swift
//  Lift
//
//  Created by Carl Wieland on 10/4/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class SQLiteTextView: NSTextView {

    private var highlighter: SQLiteSyntaxHighlighter!

    override func awakeFromNib() {
        if highlighter == nil {
            highlighter = SQLiteSyntaxHighlighter(for: self)
        }
        isAutomaticQuoteSubstitutionEnabled = false
        
    }
    
}
