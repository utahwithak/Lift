//
//  CreateTableConstraintCell.swift
//  Lift
//
//  Created by Carl Wieland on 10/29/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class CreateTableConstraintCell: NSTableCellView {

    @IBAction func showCheckConstraint(_ sender: NSButton) {
        let storyboard = NSStoryboard(name: .constraints, bundle: nil)
        guard let viewController = storyboard.instantiateController(withIdentifier: "createCheckConstraint") as? NSViewController else {
            return
        }
        viewController.representedObject = objectValue
        let controller = NSPopover()
        controller.contentViewController = viewController
        controller.delegate = self
        controller.behavior = .semitransient
        controller.show(relativeTo: sender.frame, of: self, preferredEdge: NSRectEdge.minY)
//        let vc = self.stor//
    }

    @IBAction func showPrimaryKeyConstraint(_ sender: NSButton) {

    }

    @IBAction func showForeignKeyConstraint(_ sender: NSButton) {

    }

    @IBAction func showUniqueConstraint(_ sender: NSButton) {

    }
}

extension CreateTableConstraintCell: NSPopoverDelegate {

}
