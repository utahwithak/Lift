//
//  CustomTableViewHeaderView.swift
//  Lift
//
//  Created by Carl Wieland on 2/28/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class CustomTableHeaderView: NSTableHeaderView {

    var sortOrders: [ColumnSort]?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let tableView = tableView else {
            return
        }

        if let sorts = sortOrders {
            for (priority, order) in sorts.enumerated() {
                if priority > 0 {

                }
                if let index = tableView.tableColumns.index(where: { $0.title == order.column}) {
                    var rect = headerRect(ofColumn: index)
                    var indicatorRect = CGRect.zero
                    for _ in 0..<(priority + 1) {
                    rect.size.width = rect.width - indicatorRect.width
                    tableView.tableColumns[index].headerCell.drawSortIndicator(withFrame: rect, in: self, ascending: order.asc, priority: 0)
                    indicatorRect = tableView.tableColumns[index].headerCell.sortIndicatorRect(forBounds: rect)

                    }

                }
            }
        }
    }

}
