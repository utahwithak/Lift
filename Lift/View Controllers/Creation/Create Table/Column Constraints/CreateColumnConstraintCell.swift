//
//  CreateColumnConstraintCell.swift
//  Lift
//
//  Created by Carl Wieland on 10/29/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import AppKit

class CreateColumnConstraintCell: NSTableCellView {

    @IBOutlet weak var pkButton: NSButton!
    @IBOutlet weak var notNullButton: NSButton!
    @IBOutlet weak var uniqueButton: NSButton!
    @IBOutlet weak var checkButton: NSButton!
    @IBOutlet weak var defaultButton: NSButton!
    @IBOutlet weak var collateButton: NSButton!

    @IBOutlet weak var constraintStackView: NSStackView!

    var foreignKeyButtons = [NSButton]()
    lazy var storyboard: NSStoryboard = { NSStoryboard(name: .constraints, bundle: nil) }()

    @objc dynamic var columnDefinition: CreateColumnDefinition? {
        return objectValue as? CreateColumnDefinition
    }

    @objc dynamic var columnConstraint: CreateColumnConstraintDefinitions? {
        return columnDefinition?.constraints
    }

    private var observationContext: NSKeyValueObservation?

    override var objectValue: Any? {
        willSet {
            observationContext = nil
            unbind()
        }

        didSet {
            bind(button: pkButton, keyPath: "constraints.primaryKey.enabled")
            bind(button: notNullButton, keyPath: "constraints.nonNull.enabled")
            bind(button: uniqueButton, keyPath: "constraints.unique.enabled")
            bind(button: checkButton, keyPath: "constraints.check.enabled")
            bind(button: defaultButton, keyPath: "constraints.defaultConstraint.enabled")
            bind(button: collateButton, keyPath: "constraints.collate.enabled")

            if let constraint = columnConstraint {
                observationContext = constraint.observe(\.foreignKeys) { (_, _) in
                    self.refreshForeignKeys()
                }
            }

            refreshForeignKeys()
        }
    }

    private func unbind() {
        for button in [pkButton, notNullButton, uniqueButton, checkButton, defaultButton, collateButton] {
            button?.unbind(NSBindingName(rawValue: "drawAsEnabled"))
        }

        refreshForeignKeys()

    }

    private func refreshForeignKeys() {
        for button in foreignKeyButtons {
            button.unbind(NSBindingName(rawValue: "drawAsEnabled"))
        }

        if let constraints = columnConstraint {
            for (index, fKeyConstraint) in constraints.foreignKeys.enumerated() {

                let button = index < foreignKeyButtons.count ? foreignKeyButtons[index] : createForeignKeyButton()
                button.tag = index
                bind(button: button, keyPath: "enabled", to: fKeyConstraint)
                if index >= foreignKeyButtons.count {
                    constraintStackView.addView(button, in: .trailing)
                    foreignKeyButtons.append(button)
                }
            }
        }
    }

    private func createForeignKeyButton() -> NSButton {
        let button = ConstraintButton(image: NSImage(named: NSImage.Name("ForeignKey"))!, target: self, action: #selector(showForeignKeyConstraint))
        button.widthAnchor.constraint(equalToConstant: 17).isActive = true
        button.heightAnchor.constraint(equalToConstant: 17).isActive = true
        button.imagePosition = .imageOnly
        button.isBordered = false
        return button
    }

    private func bind(button: NSButton, keyPath: String, to: Any? = nil) {
        guard let objectValue = to ?? objectValue else {
            return
        }
        button.bind(NSBindingName(rawValue: "drawAsEnabled"), to: objectValue, withKeyPath: keyPath, options: [NSBindingOption.nullPlaceholder: false as NSNumber])
    }

    private func showConstraintView(named: String, from sender: NSButton, representedObject: Any? = nil) {
        guard let viewController = storyboard.instantiateController(withIdentifier: named) as? NSViewController else {
            return
        }
        viewController.representedObject = representedObject ?? objectValue
        let controller = NSPopover()
        controller.contentViewController = viewController
        controller.delegate = self
        controller.behavior = .semitransient
        controller.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.maxY)
    }

    @IBAction func showPrimaryKeyConstraint(_ sender: NSButton) {
        if columnConstraint?.primaryKey == nil {
            columnConstraint?.primaryKey = CreateColumnConstraintDefinitions.CreatePrimaryKey()
        }
        showConstraintView(named: "createPrimaryKeyConstraint", from: sender)
    }

    @IBAction func showNotNullConstraint(_ sender: NSButton) {
        if columnConstraint?.nonNull == nil {
            columnConstraint?.nonNull = CreateColumnConstraintDefinitions.CreateNonNull()
        }
        showConstraintView(named: "createNonNullConstraint", from: sender)

    }

    @IBAction func showUniqueConstraint(_ sender: NSButton) {
        if columnConstraint?.unique == nil {
            columnConstraint?.unique = CreateColumnConstraintDefinitions.CreateUnique()
        }
        showConstraintView(named: "createUniqueConstraint", from: sender)
    }

    @IBAction func showCheckConstraint(_ sender: NSButton) {
        if columnConstraint?.check == nil {
            columnConstraint?.check = CreateColumnConstraintDefinitions.CreateCheckConstraint()
        }
        showConstraintView(named: "createColumnCheckConstraint", from: sender)
    }

    @IBAction func showDefaultConstraint(_ sender: NSButton) {
        if columnConstraint?.defaultConstraint == nil {
            columnConstraint?.defaultConstraint = CreateColumnConstraintDefinitions.CreateDefaultValue(value: "NULL")
        }
        showConstraintView(named: "createDefaultConstraint", from: sender)
    }

    @IBAction func showCollateConstraint(_ sender: NSButton) {
        if columnConstraint?.collate == nil {
            columnConstraint?.collate = CreateColumnConstraintDefinitions.CreateCollateConstraint()
        }
        showConstraintView(named: "createCollateConstraint", from: sender)
    }

    @IBAction func showForeignKeyConstraint(_ sender: NSButton) {
        guard let constraints = columnConstraint else {
            return
        }

        showConstraintView(named: "createFKey", from: sender, representedObject: constraints.foreignKeys[sender.tag])
    }
}

extension CreateColumnConstraintCell: NSPopoverDelegate {
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        if let checkConst = columnConstraint?.check {
            if checkConst.enabled && checkConst.expression.isEmpty {
                columnConstraint?.check = nil
            } else if let name = checkConst.constraintName, name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                checkConst.constraintName = nil
            }
        }

        if let collConst = columnConstraint?.collate {
            if collConst.enabled, collConst.collationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                columnConstraint?.collate = nil
            } else if let name = collConst.constraintName, name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                collConst.constraintName = nil
            }
        }

        columnConstraint?.checkForeignKeys()
        return true
    }

}
