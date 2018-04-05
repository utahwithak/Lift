//
//  TabButton.swift
//  Tabs
//
//  Created by Carl Wieland on 11/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class TabButton: NSButton {

    private lazy var minWidthConstraint: NSLayoutConstraint = {
        return NSLayoutConstraint(item: self, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
    }()

    private lazy var maxWidthConstraint: NSLayoutConstraint = {
        return NSLayoutConstraint(item: self, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
    }()

    override class var cellClass: Swift.AnyClass? {
        get {
            return TabCell.self
        }
        set {

        }
    }

    var tabCell: TabCell! {
        return cell as! TabCell
    }

    public var showsMenu: Bool {
        get {
            return tabCell.showsMenu
        }
        set {
            tabCell.showsMenu = newValue
        }
    }

    public var isShowingMenu: Bool {
        return tabCell.isShowingMenu
    }

    public var borderMask: BorderMask {
        set {
            tabCell.borderMask = newValue
        }
        get {
            return tabCell.borderMask
        }
    }

    public var borderColor: NSColor {
        get {
            return tabCell.borderColor
        }
        set {
            tabCell.borderColor = newValue
        }
    }

    public var backgroundColor: NSColor? {
        get {
            return tabCell.backgroundColor
        }
        set {
            tabCell.backgroundColor = newValue
        }
    }

    public var titleColor: NSColor {
        get {
            return tabCell.titleColor
        }
        set {
            tabCell.titleColor = newValue
        }
    }

    public var titleHighlightColor: NSColor {
        get {
            return tabCell.titleHighlightColor
        }
        set {
            tabCell.titleHighlightColor = newValue
        }
    }

    public var minWidth: CGFloat {
        get {
            return tabCell.minWidth
        }
        set {
            tabCell.minWidth = newValue
        }
    }
    public var maxWidth: CGFloat {
        get {
            return tabCell.maxWidth
        }
        set {
            tabCell.maxWidth = newValue
        }
    }

    override var cell: NSCell? {
        didSet {
            if let tabCell = cell as? TabCell {
                constrainSize(with: tabCell)
            }
        }
    }

    @objc dynamic func constrainSize(with cell: TabCell) {
        if cell.minWidth > 0 {
            minWidthConstraint.constant = cell.minWidth
            minWidthConstraint.isActive = true
        } else {
            minWidthConstraint.isActive = false
        }

        if cell.maxWidth > 0 {
            maxWidthConstraint.constant = cell.maxWidth
            maxWidthConstraint.isActive = true
        } else {
            maxWidthConstraint.isActive = false
        }

        needsLayout = true
    }
}
