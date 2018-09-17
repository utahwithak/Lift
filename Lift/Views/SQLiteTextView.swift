//
//  SQLiteTextView.swift
//  Lift
//
//  Created by Carl Wieland on 10/4/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

protocol SQLiteTextViewCompletionDelegate: class {
    func completionsFor(range: NSRange, in textView: SQLiteTextView) -> [SQLiteTextView.CompletionResult]
}

class SQLiteTextView: NSTextView {

    enum CompletionResult {
        case database(String)
        case table(String, database: String)
        case column(String, table: String)
        case keyword(String)
        var image: NSImage? {
            switch self {
            case .database:
                return NSImage(named: "databaseType")
            case .table:
                return NSImage(named: "tableType")
            case .column:
                return NSImage(named: "columnType")
            case .keyword:
                return NSImage(named: "sqliteType")
            }
        }

        func width(with font: NSFont) -> CGFloat {
            let text: String
            switch self {
            case .database(let d):
                text = d
            case .table(let t, database: _):
                text = t
            case .column(let c, table: _):
                text = c
            case .keyword(let k):
                text = k
            }
            return (text as NSString).size(withAttributes: [.font: font]).width + 10

        }

        var parentText: String? {
            switch self {
            case .column(_, table: let table):
                return table
            case .table(_, database: let db):
                return db
            default:
                return nil
            }
        }

        var completion: String {
            switch self {
            case .database(let name):
                return name
            case .table(let name, database: _):
                return name
            case .column(let name, table: _):
                return name
            case .keyword(let word):
                return word
            }
        }

    }

    private let rowHeight: CGFloat = 20

    private var isShowingAutocomplete: Bool {
        return autocompletePanel != nil
    }

    private var highlighter: SQLiteSyntaxHighlighter!

    private weak var autocompletePanel: CompletionPanel?
    private var autoCompletionData = [CompletionResult]()
    private var tableView: NSTableView!
    private var iconColumn: NSTableColumn!
    private var parentColumn: NSTableColumn!
    private var autoCompleteColumn: NSTableColumn!
    private var tableContainer: NSScrollView!

    public weak var completionDelegate: SQLiteTextViewCompletionDelegate?

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

        NotificationCenter.default.addObserver(self, selector: #selector(windowChanged), name: NSWindow.willStartLiveResizeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowChanged), name: NSWindow.didResignKeyNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowChanged), name: NSWindow.didResignMainNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowChanged), name: NSWindow.willMoveNotification, object: nil)
    }

    @objc private func boundsChanged(_ not: Notification) {
        highlighter.highlight(self)
    }

    @objc private func windowChanged(_ not: Notification) {
        if (not.object as? NSWindow) != autocompletePanel {
            finishCompletion()
        }
    }

    private func finishCompletion() {
            autocompletePanel?.orderOut(nil)
            autocompletePanel = nil

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

    override func complete(_ sender: Any?) {

        guard let completionData = completionDelegate?.completionsFor(range: rangeForUserCompletion, in: self)  else {
            NSSound.beep()
            return
        }

        let current = autoCompletionData
        autoCompletionData = completionData

        var p = NSRange(location: 0, length: 0)
        let rectRange = firstRect(forCharacterRange: rangeForUserCompletion, actualRange: &p)

        //This allows the view to be resized by the view holding it
        if tableView == nil {
            let tableView = NSTableView(frame: NSRect(x: 0, y: 0, width: 250, height: 40))
            let iconColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "type"))
            iconColumn.width = rowHeight
            tableView.addTableColumn(iconColumn)
            self.iconColumn = iconColumn

            parentColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "parent"))

            autoCompleteColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "autocomplete"))

            tableView.backgroundColor = .clear
            tableView.headerView = nil
            tableView.delegate = self
            tableView.dataSource = self

            let tableContainer = NSScrollView(frame: tableView.frame)
            tableContainer.hasVerticalScroller = true
            tableContainer.horizontalScrollElasticity = .none
            tableContainer.autoresizingMask = [.width]
            tableView.autoresizingMask = [.width, .height]
            tableContainer.documentView = tableView

            self.tableContainer = tableContainer
            self.tableView = tableView
        }

        tableView.removeTableColumn(parentColumn)
        tableView.removeTableColumn(autoCompleteColumn)

        let parentColumnWidth = parentColumnSize
        parentColumn.width = parentColumnWidth

        if parentColumnWidth > 0 {
            tableView.addTableColumn(parentColumn)
        }

        let autocompleteSize = self.autocompleteSize
        autoCompleteColumn.width = autocompleteSize
        tableView.addTableColumn(autoCompleteColumn)

        let colWidth = iconColumn.width + parentColumn.width + autoCompleteColumn.width

        var height: CGFloat = 20*8
        if autoCompletionData.count < 8 {
            height = CGFloat(autoCompletionData.count) * rowHeight + CGFloat(autoCompletionData.count * 2)
        }
        tableView.frame = NSRect(x: 0, y: 0, width: colWidth, height: 50)
        tableContainer.frame = NSRect(x: 0, y: 0, width: colWidth, height: height)
        self.autocompletePanel?.orderOut(nil)
        self.autocompletePanel = nil
        let autocompletePanel = CompletionPanel(contentRect: NSRect(x: rectRange.origin.x - (iconColumn.width + parentColumn.width), y: rectRange.origin.y - self.tableContainer.frame.size.height, width: tableContainer.frame.size.width, height: tableContainer.frame.size.height), styleMask: [.borderless], backing: .buffered, defer: true)

        let mainView = autocompletePanel.contentView
        mainView?.addSubview(tableContainer)

        autocompletePanel.hasShadow = true
        autocompletePanel.isReleasedWhenClosed = false
        autocompletePanel.delegate = self
        window?.addChildWindow(autocompletePanel, ordered: .above)

        tableView.reloadData()
        self.autocompletePanel = autocompletePanel
    }

    private var parentColumnSize: CGFloat {
        return autoCompletionData.compactMap({ $0.parentText }).reduce(0) {
            return max($0, ($1 as NSString).size(withAttributes: [.font: standardFont]).width + 10)
        }

    }

    private var standardFont: NSFont {
        return self.font ?? NSFont(name: "Menlo", size: NSFont.systemFontSize(for: .small))!
    }

    private var autocompleteSize: CGFloat {
        return autoCompletionData.reduce(0, { max($0, $1.width(with: standardFont))})
    }

    override func resignFirstResponder() -> Bool {
        finishCompletion()
        return super.resignFirstResponder()
    }
    override func cancelOperation(_ sender: Any?) {
        if isShowingAutocomplete {
            finishCompletion()
        } else {
            complete(nil)
        }
    }

    func completion(for row: Int) -> String {
        guard row < autoCompletionData.count && row >= 0 else {
            print("ASKING FOR INVALID COMPLETION!")
            return ""
        }

        return autoCompletionData[row].completion
    }

    private func doCompletion(movement: Int) {
        let selected = tableView.selectedRow
        if selected >= 0 {
            let completion = self.completion(for: selected)
            self.insertCompletion(completion, forPartialWordRange: rangeForUserCompletion, movement: movement, isFinal: true)
            highlighter.highlight(self)

        }

        finishCompletion()

    }

    override func insertTab(_ sender: Any?) {
        if isShowingAutocomplete {
            doCompletion(movement: NSTabTextMovement)
        } else {
            super.insertTab(sender)
        }
    }

    override func insertNewline(_ sender: Any?) {
        if isShowingAutocomplete {
            doCompletion(movement: NSReturnTextMovement)
        } else {
            super.insertNewline(sender)
        }
    }

    override func moveDown(_ sender: Any?) {
        if isShowingAutocomplete {
            let selected = min(tableView.selectedRow + 1, autoCompletionData.count - 1)
            insertCompletion(completion(for: selected), forPartialWordRange: rangeForUserCompletion, movement: NSDownTextMovement, isFinal: false)
            tableView.selectRowIndexes(IndexSet([selected]), byExtendingSelection: false)
            tableView.scrollRowToVisible(selected)
        } else {
            super.moveDown(sender)
        }
    }

    override func moveUp(_ sender: Any?) {
        if isShowingAutocomplete {
            let selected = max(tableView.selectedRow - 1, -1)

            if selected >= 0 {
                self.insertCompletion(completion(for: selected), forPartialWordRange: rangeForUserCompletion, movement: NSUpTextMovement, isFinal: false)
                tableView.selectRowIndexes(IndexSet([selected]), byExtendingSelection: false)
            } else {
                tableView.deselectRow(tableView.selectedRow)
                insertCompletion("", forPartialWordRange: rangeForUserCompletion, movement: NSUpTextMovement, isFinal: false)
                delete(nil)
            }
            tableView.scrollRowToVisible(selected)
        } else {
           super.moveUp(sender)
        }
    }

    override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        if event.keyCode == 49 { //Spacebar keyCode is 49
            finishCompletion()

        } else if isShowingAutocomplete && event.keyCode != 125 && event.keyCode != 126 {
            complete(nil)
        }
    }
    override func insertCompletion(_ word: String, forPartialWordRange charRange: NSRange, movement: Int, isFinal flag: Bool) {

        let partialWord = (self.string as NSString).substring(with: charRange)

        if partialWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            super.insertCompletion(word, forPartialWordRange: charRange, movement: movement, isFinal: flag)
        } else {
            // last will be empty string from the "." so we drop that and get the actual last
            //
            if partialWord.last == "." {
                super.insertCompletion(partialWord + word, forPartialWordRange: charRange, movement: movement, isFinal: flag)
            } else if let lastComponent = partialWord.components(separatedBy: ".").last {
                super.insertCompletion(partialWord.dropLast(lastComponent.count) + word, forPartialWordRange: charRange, movement: movement, isFinal: flag)
            } else {
                super.insertCompletion(word, forPartialWordRange: charRange, movement: movement, isFinal: flag)
            }
        }
        if flag  || movement == NSTabTextMovement || movement == NSReturnTextMovement {
            finishCompletion()
        }
    }

}

extension SQLiteTextView: NSTableViewDataSource {

    var parentTextColor: NSColor? {
        return NSColor(named: "parentCompletionColor")
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return autoCompletionData.count
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return rowHeight
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        guard row < autoCompletionData.count else {
            return nil
        }

        guard let tableColumn = tableColumn else {
            return nil
        }

        let identifier = tableColumn.identifier
        let completion = autoCompletionData[row]
        if identifier.rawValue == "autocomplete" || identifier.rawValue == "parent" {

            var result: NSTextField! = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTextField
            if result == nil {
                result = NSTextField(frame: NSRect(x: 0, y: 0, width: tableColumn.width, height: rowHeight))
            }
            result.isBezeled = false
            result.drawsBackground = false
            result.isEditable = false
            result.isSelectable = false
            result.font = standardFont

            if identifier.rawValue == "parent" {
                if case .column(_, table: let tableName) = completion {
                    result.textColor = parentTextColor
                    result.alignment = .right
                    result.stringValue = tableName
                } else {
                    result.stringValue = ""
                }
            } else {
                result.stringValue =  completion.completion
            }
            return result
        } else if identifier.rawValue == "type" {
            var imageView: NSImageView? = tableView.makeView(withIdentifier: identifier, owner: self) as? NSImageView
            if imageView == nil {
                imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 20, height: rowHeight))
            }
            imageView?.image = completion.image
            return imageView
        }

        return nil
    }
}

extension SQLiteTextView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if tableView.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "parent")) == 1 {
            if let cell =  tableView.view(atColumn: 1, row: row, makeIfNecessary: false) as? NSTextField {
                cell.textColor = .white
            }
            if tableView.selectedRow >= 0, let cell = tableView.view(atColumn: 1, row: tableView.selectedRow, makeIfNecessary: false) as? NSTextField {
                cell.textColor = parentTextColor
            }
        }

        self.insertCompletion(completion(for: row), forPartialWordRange: rangeForUserCompletion, movement: NSOtherTextMovement, isFinal: false)

        return true
    }
}

extension SQLiteTextView.CompletionResult: Hashable {
}

extension SQLiteTextView: NSWindowDelegate {

}
