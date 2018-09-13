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
        setup()
    }

    public func setIdentifiers(_ ids: Set<String>) {
        if highlighter == nil {
            setup()
        }

        highlighter.autocompleteWords = ids.union(["sqlite_master", "sqlite_sequence"])
    }

    func setup() {
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

        if let clipView = enclosingScrollView?.contentView {
            clipView.postsBoundsChangedNotifications = true
            NotificationCenter.default.addObserver(self, selector: #selector(boundsChanged), name: NSView.boundsDidChangeNotification, object: clipView)
        }

    }

    @objc private func boundsChanged(_ not: Notification) {
        highlighter.highlight(self)
    }

    func refresh() {
        highlighter.highlight(self)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return isEditable ? .copy : NSDragOperation()
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {

    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return isEditable
    }

    override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {

        defer {
            highlighter.highlight(self)
        }

        let pasteBoard = draggingInfo.draggingPasteboard

        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], urls.count > 0 {
            for url in urls {
                if let text = try? String(contentsOf: url, encoding: .utf8) {
                    self.textStorage?.append(NSAttributedString(string: text))
                }
            }
            return true
        }
        return super.performDragOperation(draggingInfo)
    }
}
