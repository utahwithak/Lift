//
//  TableNumberView.swift
//  Lift
//
//  Created by Carl Wieland on 10/9/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TableNumberView: LineNumberView {

    var rowCount: Int = 0 {
        didSet {
            ruleThickness = requiredThickness

            invalidateHashMarks()
            // we need to redisplay because line numbers may change or disappear in view
            needsDisplay = true
        }
    }

    override var count: Int {
        return rowCount
    }

    var tableView: NSTableView? {
        return clientView as? NSTableView
    }


    override init(scrollView: NSScrollView) {
        super.init(scrollView: scrollView)

    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func drawHashMarksAndLabels(in rect: NSRect) {
        drawBackground()

        guard let tableView = self.tableView, let visibleRect = tableView.enclosingScrollView?.documentVisibleRect, rowCount > 0 else {
            return
        }

        let boundWidth = NSWidth(bounds)

        let visibleRowRange = tableView.rows(in: tableView.visibleRect)

        var row = visibleRowRange.location
        let context = NSStringDrawingContext()

        while NSLocationInRange(row, visibleRowRange) {

            let rowRect = tableView.rect(ofRow: row)

            let ypos = NSMinY(rowRect) - NSMinY(visibleRect)

            // Line numbers are internally stored starting at 0
            let labelText = NSString(format:"%jd", row + 1)

            let stringSize = labelText.size(withAttributes: textAttributes)

            // Draw string flush right, centered vertically within the line
            let textRect = NSRect(x: boundWidth - stringSize.width - LineNumberView.RULER_MARGIN,
                                  y: ypos + (NSHeight(rowRect) - stringSize.height) / 2.0,
                                  width: boundWidth - LineNumberView.RULER_MARGIN * 2.0,
                                  height: NSHeight(rowRect))
            labelText.draw(with: textRect, options: [.usesLineFragmentOrigin], attributes: textAttributes, context: context)

            row += 1
        }
    }
}
