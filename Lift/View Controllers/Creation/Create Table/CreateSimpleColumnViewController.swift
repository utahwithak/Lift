//
//  CreateSimpleColumnViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/24/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class CreateSimpleColumnViewController: NSViewController {
    @objc dynamic var column: CreateColumnDefinition! {
        didSet {
            columnName = column.name
            type = column.type
            defaultValue = column.defaultExpression
            isPrimary = column.isPrimary
            isUnique = column.isUnique
            isNonNull = column.isNonNull
        }
    }

    @objc dynamic var columnName: String = ""
    @objc dynamic var type: String?
    @objc dynamic var defaultValue: String?
    @objc dynamic var isPrimary = false
    @objc dynamic var isUnique = false
    @objc dynamic var isNonNull = false

    weak var delegate: SimpleCreateColumnDelegate?

    @IBAction func doneEditing(_ sender: Any) {
        column.willChangeValue(for: \.sql)
        column.type = type
        column.defaultExpression = defaultValue
        column.name = columnName
        column.isPrimary = isPrimary
        column.isUnique = isUnique
        column.isNonNull = isNonNull
        column.didChangeValue(for: \.sql)
        delegate?.didFinishEditing(definition: column)
        dismiss(self)
    }
}

protocol SimpleCreateColumnDelegate: class {
    func didFinishEditing(definition: CreateColumnDefinition)
}
