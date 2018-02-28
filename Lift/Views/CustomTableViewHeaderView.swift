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
                if let index = tableView.tableColumns.index(where: { $0.title == order.column}) {
                    let rect = headerRect(ofColumn: index)
                    tableView.tableColumns[index].headerCell.drawSortIndicator(withFrame: rect, in: self, ascending: order.asc, priority: priority)
                }
            }
        }
    }

}
