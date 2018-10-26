//
//  TabCell.swift
//  Tabs
//
//  Created by Carl Wieland on 11/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

struct BorderMask: OptionSet {
    let rawValue: UInt8
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    static let none     = BorderMask(rawValue: 0)
    static let top      = BorderMask(rawValue: 1<<0)
    static let left     = BorderMask(rawValue: 1<<1)
    static let right    = BorderMask(rawValue: 1<<2)
    static let bottom   = BorderMask(rawValue: 1<<3)
}

class BorderedButtonCell: NSButtonCell {

    override init(textCell string: String) {
        super.init(textCell: string)
        self.isBordered = true
        self.backgroundStyle = .light

        self.lineBreakMode = .byTruncatingTail
        highlightsBy = .changeBackgroundCellMask
        showsStateBy = .changeBackgroundCellMask

    }

    init(toCopy: BorderedButtonCell) {
        super.init(textCell: "")
        self.isBordered = toCopy.isBordered
        self.backgroundStyle = toCopy.backgroundStyle

        self.lineBreakMode = toCopy.lineBreakMode
        highlightsBy = toCopy.highlightsBy
        showsStateBy = toCopy.showsStateBy
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.isBordered = true
        self.backgroundStyle = .light

        self.lineBreakMode = .byTruncatingTail
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as? BorderedButtonCell

        copy!.borderMask = borderMask
//        copy.borderColor = borderColor
        copy!.borderWidth = borderWidth

        return copy!

    }

    public static let defaultBorderColor: NSColor = {
        if #available(OSX 10.14, *) {
            return NSColor.separatorColor
        }
        return NSColor(calibratedWhite: 0.75, alpha: 1)
    }()

    public var borderWidth: CGFloat = 1 {
        didSet {
            controlView?.needsDisplay = true
        }
    }

    public var borderColor = BorderedButtonCell.defaultBorderColor {
        didSet {
            controlView?.needsDisplay = true
        }
    }

    public var borderMask = BorderMask.none {
        didSet {
            controlView?.needsDisplay = true
        }
    }

    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {

        guard !borderMask.isEmpty else {
            return
        }

        borderColor.set()

        if borderMask.contains(.top) {
            let (slice, _) = frame.divided(atDistance: borderWidth, from: .minYEdge)
            slice.fill()
        }

        if borderMask.contains(.left) {
            let (slice, _) = frame.divided(atDistance: borderWidth, from: .minXEdge)
            slice.fill()
        }

        if borderMask.contains(.right) {
            let (slice, _) = frame.divided(atDistance: borderWidth, from: .maxXEdge)
            slice.fill()
        }

        if borderMask.contains(.bottom) {
            let (slice, _) = frame.divided(atDistance: borderWidth, from: .maxYEdge)
            slice.fill()
        }

    }

    override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
        isBordered = false
        super.drawImage( image, withFrame: frame, in: controlView)
        isBordered = true
    }

}

class TabCell: BorderedButtonCell {
    private static let defaultFont = NSFont(name: "HelveticaNeue-SemiBold", size: 13)

    public static let defaultTitleSelectedColor = NSColor(named: "tabTitleSelectedColor")!
    public static let defaultSelectedBackgroundColor = NSColor(named: "tabSelectedBackgroundColor")!
    public static let defaultBackgroundColor = NSColor(named: "tabDefaultBackgroundColor")!

    public var showsMenu = false {
        didSet {
            controlView?.needsDisplay = true
        }
    }

    public private(set) var isShowingMenu = false

    override var backgroundColor: NSColor? {
        didSet {
            controlView?.needsDisplay = true
        }
    }

    public var titleColor = NSColor(named: "tabTitleColor")!
    public var titleHighlightColor = TabCell.defaultTitleSelectedColor
    public var backgroundHighlightColor = TabCell.defaultBackgroundColor {
        didSet {
            controlView?.needsDisplay = true
        }
    }

    public var minWidth: CGFloat = 72 * 2.75 {
        didSet {
            if let tabButton = controlView as? TabButton {
                tabButton.constrainSize(with: self)
            }
        }
    }

    public var maxWidth: CGFloat = 720

    static let popupImage = NSImage(named: "PullDownTemplate")!.tintedImage(with: NSColor.selectedControlTextColor)

    static let popupSize = TabCell.popupImage.size

    public var dragging = false {
        didSet {
            borderMask = []
            controlView?.needsDisplay = true

        }
    }

    override init(textCell string: String) {

        super.init(textCell: string)

        self.font = TabCell.defaultFont

        backgroundColor = TabCell.defaultBackgroundColor.copy() as? NSColor

    }

    init?(other: NSCell?) {
        guard let toCopy = other as? TabCell else {
            return nil
        }

        super.init(toCopy: toCopy)
        title = other?.title
        self.font = TabCell.defaultFont

    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func cellSize(forBounds rect: NSRect) -> NSSize {
        let titleSize = attributedTitle.size()
        let popupSize = menu == nil ? .zero : TabCell.popupSize
        return NSSize(width: titleSize.width + popupSize.width * 2 + 36, height: max(titleSize.height, popupSize.height))
    }

    func popupRect(with frame: NSRect) -> NSRect {
        var popupRect = NSRect.zero
        popupRect.size = TabCell.popupSize
        popupRect.origin = NSPoint(x: frame.maxX - popupRect.width - 8, y: frame.midY - (popupRect.height / 2))

        return popupRect
    }

    override func titleRect(forBounds rect: NSRect) -> NSRect {
        let titleSize = attributedTitle.size()
        let titleRect = NSRect(x: rect.minX, y: floor(rect.midY - (titleSize.height / 2)), width: rect.width, height: titleSize.height)
        return titleRect
    }

    func editingRect(forBounds rect: NSRect) -> NSRect {
        return super.titleRect(forBounds: rect.offsetBy(dx: 0, dy: -1))
    }

    func enclosingTabControl(in view: NSView) -> TabControl? {

        var curView = view

        while let next = curView.superview {
            if let tabC = next as? TabControl {
                return tabC
            }
            curView = next
        }

        return nil

    }

    override func trackMouse(with event: NSEvent, in cellFrame: NSRect, of controlView: NSView, untilMouseUp flag: Bool) -> Bool {

        let location = controlView.convert(event.locationInWindow, from: nil)
        if let sView = controlView.superview, !hitTest(for: event, in: sView.frame, of: sView).isEmpty {

            let popupRect = self.popupRect(with: cellFrame)

            if let menu = self.menu(for: event, in: cellFrame, of: controlView), !menu.items.isEmpty && popupRect.contains(location) {
                menu.popUp(positioning: menu.items[0], at: NSPoint(x: popupRect.midX, y: popupRect.maxY), in: controlView)
                showsMenu = false
                return true
            }
        }

        return super.trackMouse(with: event, in: cellFrame, of: controlView, untilMouseUp: flag)
    }

    override func menu(for event: NSEvent, in cellFrame: NSRect, of view: NSView) -> NSMenu? {
        if let enclosingTabControl = self.enclosingTabControl(in: view), let item = self.representedObject {
            if let menu = enclosingTabControl.datasource?.tabControl?(enclosingTabControl, menuFor: item) {
                enclosingTabControl.selectedItem = self.representedObject
                return menu
            }
            return nil
        } else {
            return super.menu(for: event, in: cellFrame, of: view)
        }
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        if dragging {
            backgroundColor = DarkenBackgroundButton.selectedBackgroundColor
        } else if state == .on {
            backgroundColor = TabCell.defaultSelectedBackgroundColor
        } else {
            backgroundColor = TabCell.defaultBackgroundColor
        }
        super.draw(withFrame: cellFrame, in: controlView)
        if !dragging && showsMenu {
            TabCell.popupImage.draw(in: popupRect(with: cellFrame), from: .zero, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
        }
    }

    override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
        guard !dragging else {
            return .zero
        }

        let rect = titleRect(forBounds: frame)
        title.draw(with: rect, options: NSString.DrawingOptions.usesLineFragmentOrigin)
        return rect
    }

    override var attributedTitle: NSAttributedString {
        get {
            let title = super.attributedTitle.mutableCopy() as? NSMutableAttributedString
            title?.addAttributes([.foregroundColor: state == .on ? titleHighlightColor : titleColor], range: NSRange(location: 0, length: title?.length ?? 0))
            return title ?? NSAttributedString()
        }
        set {
            super.attributedTitle = newValue
        }
    }
}

class DarkenBackgroundButton: BorderedButtonCell {
    public static let selectedBackgroundColor = NSColor(calibratedRed: 0.91, green: 0.91, blue: 0.91, alpha: 1.0)

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        if isHighlighted {
            backgroundColor = DarkenBackgroundButton.selectedBackgroundColor
        } else {
            backgroundColor = TabCell.defaultBackgroundColor
        }
        super.draw(withFrame: cellFrame, in: controlView)

    }

    override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
        super.drawImage(image.tintedImage(with: NSColor.darkGray), withFrame: frame, in: controlView)
    }
}
