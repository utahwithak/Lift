//
//  TableNumberView.swift
//  Lift
//
//  Created by Carl Wieland on 10/9/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TableNumberView: NSRulerView {

    private static let DEFAULT_THICKNESS: CGFloat = 22.0
    private static let RULER_MARGIN: CGFloat = 5.0

    private var backgroundColor = NSColor.white


    var rowCount: Int = 0 {
        didSet {
            if rowCount > rows.count {
                let additional = (rows.count...rowCount).map { NSString(format:"%jd", $0 + 1) }
                rows.append(contentsOf: additional)
            }

            ruleThickness = requiredThickness

            invalidateHashMarks()
            // we need to redisplay because line numbers may change or disappear in view
            needsDisplay = true
        }
    }

    var count: Int {
        return rowCount
    }

    var tableView: NSTableView? {
        return clientView as? NSTableView
    }

    init(scrollView: NSScrollView) {
        let font = NSFont(name: "Menlo", size: NSFont.systemFontSize(for: .mini))!

        halfLineHeight = ceil(font.ascender + abs(font.descender) + font.leading) / 2

        super.init(scrollView: scrollView, orientation: .verticalRuler)
        clientView = scrollView.documentView
    }

    let halfLineHeight: CGFloat
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var defaultAlternateTextColor: NSColor {
        return NSColor.white
    }

    func drawBackground() {
        let bounds = self.bounds

        backgroundColor.set()

        __NSRectFill(bounds);
        NSColor(calibratedWhite: 0.58, alpha: 1).set()
        NSBezierPath.strokeLine(from: NSPoint(x: bounds.maxX - 0.5, y: bounds.minY), to: NSPoint(x: bounds.maxX - 0.5, y: bounds.maxY))

    }


    override var requiredThickness: CGFloat {

        let lineCount = count
        var digits = 1;
        if lineCount > 0 {
            digits = Int(log10(Double(lineCount)) + 1)
        }

        let sampleString = [String](repeating:"8", count: digits).joined()

        let stringSize = (sampleString as NSString).size(withAttributes:  textAttributes)

        // Round up the value. There is a bug on 10.4 where the display gets all wonky when scrolling if you don't
        // return an integral value here.
        return ceil(max(TableNumberView.DEFAULT_THICKNESS, stringSize.width + TableNumberView.RULER_MARGIN * 2));
    }

   let textAttributes: [NSAttributedStringKey: Any] = {
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = .right
        return [.font: NSFont(name: "Menlo", size: NSFont.systemFontSize(for: .mini))!, .foregroundColor: NSColor(calibratedWhite: 0.42, alpha: 1), .paragraphStyle: paraStyle]
    }()

    let context = NSStringDrawingContext()


    var rows = [NSString]()


    override func drawHashMarksAndLabels(in rect: NSRect) {
        drawBackground()

        guard let tableView = self.tableView, let visibleRect = tableView.enclosingScrollView?.documentVisibleRect, rowCount > 0 else {
            return
        }

        let boundWidth = NSWidth(bounds) - TableNumberView.RULER_MARGIN

        let visibleRowRange = tableView.rows(in: tableView.visibleRect)

        var row = visibleRowRange.location

        while NSLocationInRange(row, visibleRowRange) {

            let rowRect = tableView.rect(ofRow: row)

            let ypos = NSMinY(rowRect) - NSMinY(visibleRect)

            let labelText = rows[row]

            let textRect = NSRect(x: 0, y: ypos + halfLineHeight, width: boundWidth, height: NSHeight(rowRect))

            labelText.draw(with: textRect, options: [.usesLineFragmentOrigin], attributes: textAttributes, context: context)

            row += 1
        }
    
    }
}

