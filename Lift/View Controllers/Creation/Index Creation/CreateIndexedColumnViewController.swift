//
//  CreateIndexedColumnViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/3/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

protocol CreateIndexedColumnDelegate: class {
    func didFinish(with column: IndexedColumn)
}

class CreateIndexedColumnViewController: NSViewController {

    weak var delegate: CreateIndexedColumnDelegate?

    @objc dynamic var actionTitle: String {
        if isModifying {
            return NSLocalizedString("createindexedcolumn.actiontitle.modify", value: "Modify", comment: "Modify title when modifying indexed column")

        } else {
            return NSLocalizedString("createindexedcolumn.actiontitle.Add", value: "Add", comment: "action title when adding new  indexed column")

        }

    }

    var isModifying = false {
        willSet {
            willChangeValue(for: \.actionTitle)
        }
        didSet {
            didChangeValue(for: \.actionTitle)
        }
    }

    @IBOutlet var columnArrayController: NSArrayController!
    @objc dynamic var table: Table?

    @objc dynamic var useCollation = false

    @objc dynamic var sortOrderIndex: NSInteger = 0

    @objc dynamic var useColumn = true

    @objc dynamic var expression = ""

    @objc dynamic var collationName: String?

    var sortOrder: IndexColumnSortOrder {
        switch sortOrderIndex {
        case 1:
            return .ASC
        case 2:
            return .DESC
        default:
            return .notSpecified
        }
    }

    @IBAction func typeChanged(_ sender: NSButton) {
//        switch sender.tag {
//        case 0:
//            useColumn = true
//        default:
//            useColumn = false
//        }
    }

    @IBAction func addColumn(_ sender: Any) {

        guard let table = table else {
            return
        }

        let provider: ColumnNameProvider = useColumn ? table.columns[columnArrayController.selectionIndex] : expression
        var column = IndexedColumn(provider: provider)
        column.collationName = useCollation ? collationName : nil
        column.sortOrder = sortOrder
        delegate?.didFinish(with: column)
        dismiss(nil)
    }

}

extension Column: ColumnNameProvider {

}
