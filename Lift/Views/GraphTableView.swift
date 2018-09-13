//
//  GraphTableView.swift
//  Lift
//
//  Created by Carl Wieland on 10/9/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class GraphTableView: NSViewController {

    var table: Table!

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var subtitleLabel: NSTextField!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!

    @objc dynamic var columnNames = [String]()

    @IBOutlet weak var tableView: NSTableView!
    var isCollapsed = false

    override func viewDidLoad() {
        super.viewDidLoad()

        nameLabel.stringValue = table.name
        subtitleLabel.stringValue = table.database?.name ?? ""

        view.layer?.backgroundColor = NSColor(named: "sidebarBackground")?.cgColor
        view.layer?.cornerRadius = 12
        view.layer?.borderColor = NSColor.darkGray.cgColor
        let dropShadow = NSShadow()
        dropShadow.shadowColor = NSColor.shadowColor
        dropShadow.shadowOffset = NSSize(width: 0, height: -10)
        dropShadow.shadowBlurRadius = 10

        self.view.shadow = dropShadow

        columnNames = table.columns.map { $0.name }
        tableHeightConstraint.constant = CGFloat(columnNames.count * 21) + 3
    }

    func inPoint(for column: String) -> CGPoint {
        if isCollapsed {
            return CGPoint(x: view.frame.origin.x, y: view.frame.origin.y + view.frame.height - 20)

        }
        guard let colIndex = columnNames.index(of: column) else {
            return CGPoint(x: view.frame.origin.x + view.frame.width, y: view.frame.origin.y + view.frame.height - 20)
        }

        let columnRect = tableView.rect(ofRow: colIndex)

        let yPoint = view.frame.origin.y + (tableHeightConstraint.constant - columnRect.origin.y) - columnRect.height / 2
        return CGPoint(x: view.frame.origin.x, y: yPoint)
    }

    func outPoint(for column: String) -> CGPoint {
        if isCollapsed {
            return CGPoint(x: view.frame.origin.x + view.frame.width, y: view.frame.origin.y + view.frame.height - 20)
        }
        guard let colIndex = columnNames.index(of: column) else {
            return CGPoint(x: view.frame.origin.x + view.frame.width, y: view.frame.origin.y + view.frame.height - 20)
        }

        let columnRect = tableView.rect(ofRow: colIndex)

        return CGPoint(x: view.frame.origin.x + view.frame.width, y: view.frame.origin.y + (tableHeightConstraint.constant - columnRect.origin.y) - columnRect.height / 2)
    }

}

extension GraphTableView: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 19
    }
}
