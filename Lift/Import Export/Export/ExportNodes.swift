//
//  ExportNodes.swift
//  Yield
//
//  Created by Carl Wieland on 5/3/17.
//  Copyright © 2017 Datum. All rights reserved.
//

import Foundation
import SwiftXLSX

class ExportNode: NSObject {
    @objc dynamic let name: String
    @objc dynamic let children: [ExportNode]
    @objc dynamic var export = true

    init(name: String, children: [ExportNode]) {
        self.name = name
        self.children = children

        super.init()

        children.forEach { (node) in
            node.addObserver(self, forKeyPath: "export", options: [], context: nil)
        }
    }

    deinit {
        children.forEach { (node) in
            node.removeObserver(self, forKeyPath: "export")
        }
    }

    @objc dynamic var isLeaf: Bool {
        if children.isEmpty {
            return true
        } else {
            return false
        }
    }

    @objc dynamic var count: Int {
        return children.count
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else {
            super.observeValue(forKeyPath: nil, of: object, change: change, context: context)
            return
        }

        if keyPath == "export" {
            export = children.reduce(false, { $0 || $1.export } )

        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }


}

class ExportDatabaseNode: ExportNode {

    let database: Database
    init( database: Database) {
        self.database = database
        super.init(name: database.name, children: database.tables.map({ ExportTableNode(table: $0)}))
    }
}

class ExportTableNode: ExportNode {

    let table: Table

    init( table: Table ) {
        self.table = table
        super.init(name: table.name, children: table.columns.map({ ExportColumnNode(column: $0)}))
    }

    var exportColumns: [Column] {
        guard let children = self.children as? [ExportColumnNode] else {
            print("Child type doesn't match!")
            return []
        }
        return children.filter { $0.export }.map { $0.column }

    }

    func exportQuery() throws -> Query? {
        return try table.exportQuery(for: exportColumns)
    }

    func createTableStatment() -> String {
        return table.tableCreationStatement(with: exportColumns)
    }

    func importStatement(with exportQuery: Query) -> String? {
        return table.importStatement(for: exportColumns, using: exportQuery)
    }

    func exportCSV(with writer: Writer, options: CSVExportOptions) throws {
        try table.exportCSV(columns: exportColumns, writer: writer, with: options)
    }

    func export(to sheet: Sheet, with options: XLSXExportOptions) throws {
        try table.export(to: sheet, columns: exportColumns, with: options)
    }

    func exportXML(with options: XMLExportOptions) throws -> XMLElement {
        return try table.exportToXML(columns: exportColumns, with: options)
    }

    func exportJSON(with options: JSONExportOptions) throws -> [String: Any] {
        return try table.exportToJSON(columns: exportColumns, with: options)
    }
}

class ExportColumnNode: ExportNode {
    let column: Column
    init(column: Column) {
        self.column = column
        super.init(name: column.name, children: [])
    }
}


