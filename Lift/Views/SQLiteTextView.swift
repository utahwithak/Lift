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
        isAutomaticDataDetectionEnabled = false
        isAutomaticLinkDetectionEnabled = false
        isAutomaticTextCompletionEnabled = false
        isAutomaticDashSubstitutionEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        isAutomaticTextReplacementEnabled = false
        font = NSFont(name: "SF Mono", size: 11) ?? NSFont(name: "Menlo", size: 11)
        
    }
    
}
