//
//  CreateTableConstraintCell.swift
//  Lift
//
//  Created by Carl Wieland on 10/29/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class CreateTableConstraintCell: NSTableCellView {

    private func showViewController(with identifier: String, from sender: NSButton, object: Any?) {
        let storyboard = NSStoryboard(name: .constraints, bundle: nil)
        guard let viewController = storyboard.instantiateController(withIdentifier: identifier) as? NSViewController else {
            return
        }
        viewController.representedObject = object ?? objectValue
        let controller = NSPopover()
        controller.contentViewController = viewController
        controller.delegate = self
        controller.behavior = .semitransient
        if #available(OSX 10.14, *) {
            controller.appearance = controller.effectiveAppearance.name == NSAppearance.Name.aqua ? NSAppearance(named: .aqua) : NSAppearance(named: .darkAqua)
        } else {
            controller.appearance = NSAppearance(named: .aqua)

        }
        controller.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.minY)
    }

    @IBAction func showCheckConstraint(_ sender: NSButton) {
        showViewController(with: "createCheckConstraint", from: sender, object: nil)
    }

    @IBAction func showPrimaryKeyConstraint(_ sender: NSButton) {
        guard let pk = (objectValue as? CreateTableConstraintRowItem)?.primaryKey else {
            return
        }
        showViewController(with: "createIndexedTableConstraint", from: sender, object: pk)
    }

    @IBAction func showForeignKeyConstraint(_ sender: NSButton) {
        guard let fKey = (objectValue as? CreateTableConstraintRowItem)?.foreignKey else {
            return
        }
        showViewController(with: "createTableForeignKey", from: sender, object: fKey)

    }

    @IBAction func showUniqueConstraint(_ sender: NSButton) {
        guard let unique = (objectValue as? CreateTableConstraintRowItem)?.unique else {
            return
        }
        showViewController(with: "createIndexedTableConstraint", from: sender, object: unique)
    }
}

extension CreateTableConstraintCell: NSPopoverDelegate {

}
