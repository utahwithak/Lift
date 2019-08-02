//
//  TableView.swift
//  Lift
//
//  Created by Carl Wieland on 10/13/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

struct SelectionBox {
    let startRow: Int
    let endRow: Int

    let startColumn: Int
    let endColumn: Int

    var isSingleCell: Bool {
        return startRow == endRow && startColumn == endColumn
    }
    var isSingleRow: Bool {
        return startRow == endRow
    }
}

func + (lhs: SelectionBox, rhs: Int) -> SelectionBox {
    return SelectionBox(startRow: lhs.startRow + rhs, endRow: lhs.endRow + rhs, startColumn: lhs.startColumn, endColumn: lhs.endColumn)
}

extension CGRect {
    init(p1: CGPoint, p2: CGPoint) {
        self.init(x: min(p1.x, p2.x), y: min(p1.y, p2.y), width: abs(p1.x - p2.x), height: abs(p1.y - p2.y))
    }
}

class TableView: NSTableView {

    override var selectedRow: Int {
        return selectionBoxes.first?.startRow ?? -1
    }

    func selectRow(_ row: Int, column: Int? = nil) {
        if let column = column, column >= 0 {
            selectionBoxes = [SelectionBox(startRow: row, endRow: row, startColumn: column, endColumn: column)]
        } else {
            selectionBoxes = [SelectionBox(startRow: row, endRow: row, startColumn: 0, endColumn: numberOfColumns - 1)]
        }
    }

    private var selectionViews = [NSView]() {
        didSet {
            oldValue.forEach({$0.removeFromSuperview()})
            selectionViews.forEach { addSubview($0, positioned: .above, relativeTo: nil) }
        }
    }
    override func selectAll(_ sender: Any?) {
        selectionBoxes = [SelectionBox(startRow: 0, endRow: numberOfRows - 1, startColumn: 0, endColumn: numberOfColumns - 1)]
    }

    public var sortOrders: [ColumnSort] {
        set {
            (headerView as? CustomTableHeaderView)?.sortOrders = newValue
        }
        get {
            return (headerView as? CustomTableHeaderView)?.sortOrders ?? []
        }
    }

    private var selectionRects = [NSRect]() {
        didSet {
            var views = [NSView]()

            for rect in selectionRects {
                let width: CGFloat = 1
                let selection = PassthroughView(frame: rect.insetBy(dx: -2 * width, dy: -2 * width))
                if selection.frame.origin.x < 0 {
                    selection.frame.size.width += selection.frame.origin.x
                    selection.frame.origin.x = 0
                }

                if selection.frame.origin.y < 0 {
                    selection.frame.size.height += selection.frame.origin.y
                    selection.frame.origin.y = 0
                }

                selection.wantsLayer = true
                selection.layer?.backgroundColor = CGColor.clear
                selection.layer?.borderColor = NSColor.keyboardFocusIndicatorColor.withAlphaComponent(0.7).cgColor

                selection.layer?.borderWidth = width

                views.append(selection)
            }

            selectionViews = views
        }

    }

    var selectionBoxes = [SelectionBox]() {
        didSet {
            refreshSelection()
        }
    }

    @IBAction func copy(sender: Any) {

    }

    private func refreshSelection() {
        guard !selectionBoxes.isEmpty else {
            selectionRects = []
            return
        }
        var rects = [NSRect]()
        for selection in selectionBoxes {
            let firstRect = self.frameOfCell(atColumn: selection.startColumn, row: selection.startRow)
            let endBox = self.frameOfCell(atColumn: selection.endColumn, row: selection.endRow)
            let selectionRect = firstRect.union(endBox)
            rects.append(selectionRect)
        }
        selectionRects = rects

    }

    override func addTableColumn(_ tableColumn: NSTableColumn) {
        super.addTableColumn(tableColumn)

        tableColumn.addObserver(self, forKeyPath: #keyPath(NSTableColumn.width), options: [], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(NSTableColumn.width) {
            refreshSelection()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    override func sizeToFit() {

    }

    override func awakeFromNib() {
        NotificationCenter.default.addObserver(self, selector: #selector(columnResized), name: NSTableView.columnDidResizeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(columnMoved), name: NSTableView.columnDidMoveNotification, object: nil)

    }

    @objc private func columnResized(_ notification: Notification) {
        refreshSelection()
    }

    @objc private func columnMoved(_ notification: Notification) {
        selectionBoxes = []
    }
    override func mouseUp(with event: NSEvent) {
        if event.clickCount == 2 {
            if let doubleAction = doubleAction, let target = target {
                _ = target.perform(doubleAction, with: self)
            }
        }
    }
    override func mouseDown(with event: NSEvent) {
        guard event.clickCount == 1 else {
            return
        }
        allowsColumnReordering = true

        let converted: CGPoint
        if event.modifierFlags.contains(.shift), let oldBox = selectionBoxes.first {
            let frame = frameOfCell(atColumn: oldBox.startColumn, row: oldBox.startRow)
            let p1 = CGPoint(x: frame.midX, y: frame.midY)
            let mousePoint = event.locationInWindow
            let p2 = convert(mousePoint, from: nil)
            selectPoints(p1: p1, p2: p2)
            converted = p1

        } else {

            let mousePoint = event.locationInWindow
            converted = convert(mousePoint, from: nil)
            let row = self.row(at: converted)
            if row >= 0 {

                let col = column(at: converted)
                if col >= 0 {
                    selectionBoxes = [SelectionBox(startRow: row, endRow: row, startColumn: col, endColumn: col)]
                } else {
                    selectionBoxes = []
                }

            } else {
                selectionBoxes = []
            }
        }

        while let curEvent = self.window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]), curEvent.type != .leftMouseUp {
            let curPoint = convert(curEvent.locationInWindow, from: nil)
            selectPoints(p1: converted, p2: curPoint)
        }

    }

    private func selectPoints(p1: CGPoint, p2: CGPoint) {
        let selectionRect = CGRect(p1: p1, p2: p2)

        let rowRange = rows(in: selectionRect)
        let colRange = columnIndexes(in: selectionRect)
        var minCol = -1
        var maxCol = -1
        for col in colRange {
            minCol = minCol == -1 ? col : min(minCol, col)
            maxCol = maxCol == -1 ? col : max(maxCol, col)
        }

        if minCol != -1 && maxCol != -1 {
            selectionBoxes = [SelectionBox(startRow: rowRange.lowerBound, endRow: rowRange.upperBound - 1, startColumn: minCol, endColumn: maxCol)]
        } else {
            selectionBoxes = []
        }
    }

    override var wantsLayer: Bool {
        get {
            return true
        }
        set {  _ = newValue }
    }

    override func selectColumnIndexes(_ indexes: IndexSet, byExtendingSelection extend: Bool) {

        if extend {

        } else {
            allowsColumnReordering = false
            var minCol = -1
            var maxCol = -1
            for col in indexes {
                minCol = minCol == -1 ? col : min(minCol, col)
                maxCol = maxCol == -1 ? col : max(maxCol, col)
            }
            if minCol != -1 && maxCol != -1 {
                selectionBoxes = [SelectionBox(startRow: 0, endRow: numberOfRows - 1, startColumn: minCol, endColumn: maxCol)]
            }
        }

    }
    override func selectRowIndexes(_ indexes: IndexSet, byExtendingSelection extend: Bool) {
        if extend {

        } else {

            if let start = indexes.first, let end = indexes.last, start >= 0 && end < numberOfRows {
                selectionBoxes = [SelectionBox(startRow: start, endRow: end, startColumn: 0, endColumn: numberOfColumns - 1)]
            }
        }
    }

    override func deselectAll(_ sender: Any?) {
        selectionBoxes.removeAll(keepingCapacity: true)
    }

    override func insertRows(at indexes: IndexSet, withAnimation animationOptions: NSTableView.AnimationOptions = []) {

        super.insertRows(at: indexes, withAnimation: animationOptions)

        guard let selection = selectionBoxes.first else {
            return
        }
        let offset = (indexes.first ?? Int.max) <= selection.startRow ? indexes.count : 0

        if offset > 0 {
            selectionBoxes = [selection + offset]
        }

    }

    override func rulerView(_ ruler: NSRulerView, handleMouseDownWith event: NSEvent) {
        allowsColumnReordering = true

        if event.modifierFlags.contains(.command) {
        } else if event.type == .rightMouseUp || event.type == .rightMouseDown || event.type == .rightMouseDragged {
            return
        }

        let mousePoint = convert(event.locationInWindow, from: nil)
        let converted = CGPoint(x: 1, y: mousePoint.y)
        let row = self.row(at: converted)
        if row >= 0 {
            selectionBoxes = [SelectionBox(startRow: row, endRow: row, startColumn: 0, endColumn: numberOfColumns - 1)]
        }

        while let curEvent = self.window?.nextEvent(matching: [.leftMouseUp, .leftMouseDragged]), curEvent.type != .leftMouseUp {

            let curPoint = convert(curEvent.locationInWindow, from: nil)
            let p2 = CGPoint(x: 2, y: curPoint.y)
            let selectionRect = CGRect(p1: converted, p2: p2)

            let rowRange = rows(in: selectionRect)
            if rowRange.length >= 1 {
                selectionBoxes = [SelectionBox(startRow: rowRange.lowerBound, endRow: rowRange.upperBound - 1, startColumn: 0, endColumn: numberOfColumns - 1)]
            } else {
                selectionBoxes.removeAll(keepingCapacity: true)
            }

        }

    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let mousePoint = event.locationInWindow
        let converted = convert(mousePoint, from: nil)

        if selectionBoxes.isEmpty {

            let row = self.row(at: converted)

            if row >= 0 && delegate?.tableView?(self, shouldSelectRow: row) ?? true {

                let col = column(at: converted)
                if col >= 0 {
                    selectionBoxes = [SelectionBox(startRow: row, endRow: row, startColumn: col, endColumn: col)]
                }

            }
        } else {

            if let index = selectionRects.firstIndex(where: { $0.contains(converted) }) {
                selectionBoxes = [ selectionBoxes[index] ]
            } else {

                let row = self.row(at: converted)
                if row >= 0 && delegate?.tableView?(self, shouldSelectRow: row) ?? true {

                    let col = column(at: converted)
                    if col >= 0 {
                        selectionBoxes = [SelectionBox(startRow: row, endRow: row, startColumn: col, endColumn: col)]
                    }

                }
            }
        }

        return menu
    }

}
