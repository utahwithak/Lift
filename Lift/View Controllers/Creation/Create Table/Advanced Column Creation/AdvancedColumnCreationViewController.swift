//
//  AdvancedColumnCreationViewController.swift
//  Lift
//
//  Created by Carl Wieland on 10/25/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Cocoa

protocol AdvancedColumnCreationDelegate: class {
    func didFinishEditing(definition: CreateColumnDefinition)

}

class AdvancedColumnCreationViewController: NSViewController {

    @objc dynamic var constraintSections = [ConstraintSection]()

    weak var delegate: AdvancedColumnCreationDelegate?

    @objc dynamic var column: CreateColumnDefinition! {
        didSet {
            columnName = column.name
            type = column.type
            constraintSections.append(PrimaryKeySection(primaryKey: column.constraints.primaryKey))
        }
    }

    private var isPrimaryKey: Bool {
        return column.constraints.primaryKey != nil
    }
    private var isNonNull: Bool {
        return column.constraints.nonNull != nil
    }

    @objc dynamic var columnName: String = ""
    @objc dynamic var type: String?

}

extension NSUserInterfaceItemIdentifier {
    fileprivate static let primaryKeyConstraint = NSUserInterfaceItemIdentifier(rawValue: "primaryKeyConstraint")

}
extension AdvancedColumnCreationViewController: NSOutlineViewDelegate {

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? NSTreeNode else {
            return nil
        }

        switch node.representedObject {
        case is PrimaryKeySection:
            let view = outlineView.makeView(withIdentifier: .primaryKeyConstraint, owner: self) as? NSTableCellView
            return view

        default:
            return outlineView.makeView(withIdentifier: .primaryKeyConstraint, owner: self)
        }

    }
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelect tableColumn: NSTableColumn?) -> Bool {
        return false
    }

    public func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return true
    }

    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        return true
    }
}
