//
//  TabControl.swift
//  Tabs
//
//  Created by Carl Wieland on 11/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

@objc protocol TabControlDatasource {

    func numberOfTabsFor(_ control: TabControl) -> Int

    func tabControl(_ control: TabControl, itemAt index: Int) -> Any

    func tabControl(_ control: TabControl, titleKeyPathFor item: Any) -> String

    func tabControl(_ control: TabControl, canReorder item: Any) -> Bool

    func tabControl(_ control: TabControl, didReorderItems items: [Any]) -> Bool

    @objc optional func tabControl(_ control: TabControl, menuFor item: Any) -> NSMenu?

    @objc optional func tabControlDidChangeSelection(_ notification: Notification)

    @objc optional func tabControl(_ control: TabControl, didSelect item: Any)

    @objc optional func tabControl(_ control: TabControl, canEdit item: Any) -> Bool

    @objc optional func tabControl(_ control: TabControl, setTitle title: String, for item: Any)
}

extension Notification.Name {
    static let SelectionDidChangeNotification = Notification.Name("SelectionDidChangeNotification")
}

class TabControl: NSControl {

    weak var datasource: TabControlDatasource?

    public var addAction: Selector? {
        didSet {
            updateButtons()
        }
    }
    public var addTarget: Any? {
        didSet {
            updateButtons()
        }
    }

    override var isFlipped: Bool {
        return true
    }

    private var items = [Any]()

    private var scrollView: NSScrollView!
    private var addButton: NSButton!, scrollLeftButton: NSButton!, scrollRightButton: NSButton!
    private var editingField: NSTextField?

    private var addWidthConstraint: NSLayoutConstraint?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configureSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        cell = TabCell(textCell: "")
        configureSubviews()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureSubviews()
    }

    deinit {
        stopObservingScrollView()
    }

    private func configureSubviews() {
        guard scrollView == nil else {
            return
        }

        wantsLayer = true

        let cell = self.cell as? TabCell
        cell?.title = ""
        cell?.borderMask = [.bottom, .left, .right]

        scrollView = NSScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.drawsBackground = false
        scrollView.backgroundColor = .red
        scrollView.verticalScrollElasticity = .none

        let darkenCell = DarkenBackgroundButton(textCell: "")
        darkenCell.borderMask = [.bottom, .right]
        addButton = button(withImage: NSImage(named: NSImage.Name.addTemplate)!, target: self, action: #selector(add), cell: darkenCell)
        addButton.setButtonType(.momentaryChange)

        let leftCell = BorderedButtonCell(textCell: "")
        leftCell.borderMask = [.left]
        leftCell.backgroundColor = TabCell.defaultBackgroundColor
        scrollLeftButton = button(withImage: NSImage(named: NSImage.Name.leftFacingTriangleTemplate)!, target: self, action: #selector(goLeft), cell: leftCell)
        scrollLeftButton.setButtonType(.momentaryChange)

        leftCell.image = NSImage(named: NSImage.Name.leftFacingTriangleTemplate)!
        scrollLeftButton.cell =  leftCell

        let rightCell = BorderedButtonCell(textCell: "")
        rightCell.borderMask = []
        rightCell.backgroundColor = TabCell.defaultBackgroundColor
        scrollRightButton = button(withImage: NSImage(named: NSImage.Name.rightFacingTriangleTemplate)!, target: self, action: #selector(goRight), cell: rightCell)
        scrollRightButton.setButtonType(.momentaryChange)

        addButton.menu = nil
        scrollLeftButton.menu = nil
        scrollRightButton.menu = nil

        scrollLeftButton.isContinuous = true
        scrollRightButton.isContinuous = true
        scrollLeftButton.cell?.sendAction(on: [.leftMouseDown, .periodic])
        scrollRightButton.cell?.sendAction(on: [.leftMouseDown, .periodic])

        let views: [String: Any] = ["scrollView":scrollView, "addButton":addButton, "scrollLeftButton":scrollLeftButton, "scrollRightButton":scrollRightButton]
        subviews = [addButton, scrollView, scrollLeftButton, scrollRightButton]
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[addButton]-(-1)-[scrollView]-(-1)-[scrollLeftButton][scrollRightButton]|", options: [], metrics: nil, views: views))
        for view in subviews {
            self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view":view]))
        }
        self.addWidthConstraint = NSLayoutConstraint(item: addButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 48)
        addButton.addConstraint(self.addWidthConstraint!)

        scrollLeftButton.addConstraint(NSLayoutConstraint(item: scrollLeftButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 24))
        scrollRightButton.addConstraint(NSLayoutConstraint(item: scrollRightButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 24))

        (addButton.cell as? TabCell)?.borderMask = [.bottom, .right]
        (scrollLeftButton.cell as? TabCell)?.borderMask = [.bottom, .left]
        (scrollRightButton.cell as? TabCell)?.borderMask = [.bottom]

        startObservingScrollView()
        updateButtons()

    }

    func reloadData() {
        let tabView: NSView = NSView(frame: .zero)
        tabView.translatesAutoresizingMaskIntoConstraints = false

        guard let datasource = datasource else {
            return
        }

        let tabCount = datasource.numberOfTabsFor(self)

        items = (0..<tabCount).map { datasource.tabControl(self, itemAt: $0) }

        var newTabs = [TabButton]()
        for item in items {
            let button = tab(with: item)

            if let cell = button.cell as? TabCell, let menu = datasource.tabControl?(self, menuFor: item) {
                cell.menu = menu
                button.addTrackingArea(NSTrackingArea(rect: scrollView.bounds, options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect], owner: self, userInfo: ["item" : item]))
            }
            newTabs.append(button)
        }

        tabView.subviews = newTabs

        scrollView.documentView = items.isEmpty ? nil : tabView

        layoutTabs(items: items)

        if let documentView = scrollView.documentView {
            let clipView = scrollView.contentView
            clipView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[documentView]|", options: [], metrics: nil, views: ["documentView":documentView]))
            clipView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[documentView]", options: [], metrics: nil, views: ["documentView":documentView]))
            clipView.addConstraint(NSLayoutConstraint(item: documentView, attribute: .right, relatedBy: .greaterThanOrEqual, toItem: clipView, attribute: .right, multiplier: 1, constant: 0))
        }

        updateButtons()
        invalidateRestorableState()
    }

    private func button(withImage image: NSImage, target: AnyObject?, action: Selector?, cell: NSCell? = nil) -> NSButton {
        let button = NSButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.cell = cell ?? self.cell?.copy() as? NSCell
        button.target = target
        button.action = action

        button.isEnabled = action != nil
        button.imagePosition = .imageOnly
        button.image = image

        return button

    }

    @objc private func add(_ sender: NSButton) {
        if let addAction = self.addAction {
            NSApplication.shared.sendAction(addAction, to: self.addTarget, from: self)
        }
        sender.state = .off

        invalidateRestorableState()

    }

    @objc private func goLeft(_ sender: NSButton) {
        if let leftTab = firstTabLeftOutsideVisibleRect() {
            NSAnimationContext.runAnimationGroup({ (contex) in
                contex.allowsImplicitAnimation = true
                leftTab.scrollToVisible(leftTab.bounds)
            }, completionHandler: nil)
        }
    }

    private func firstTabLeftOutsideVisibleRect() -> NSView? {
        guard let tabView = self.scrollView.documentView else {
            return nil
        }

        let visibleRect = tabView.visibleRect

        for button in tabView.subviews.reversed() {
            if button.frame.minX < visibleRect.minX {
                return button
            }
        }
        return nil
    }

    private func firstTabRightOutsideVisibleRect() -> NSView? {
        guard let tabView = self.scrollView.documentView else {
            return nil
        }
        let visibleRect = tabView.visibleRect

        for view in tabView.subviews {
            if view.frame.maxX > visibleRect.maxX {
                return view
            }
        }
        return nil
    }

    @objc private func goRight(_ sender: NSButton) {
        if let right = firstTabRightOutsideVisibleRect() {
            NSAnimationContext.runAnimationGroup({ (context) in
                context.allowsImplicitAnimation = true
                right.scrollToVisible(right.bounds)
            }, completionHandler: nil)
        }
    }

    var selectedItem: Any? {
        set {
            guard let buttons = scrollView.documentView?.subviews.compactMap({ $0 as? TabButton}) else {
                return
            }
            for button in buttons {
                if (button.cell?.representedObject as? NSObject) == (newValue as? NSObject) {
                    button.state = .on
                    if let action = self.action {
                        NSApp.sendAction(action, to: target, from: self)
                    }
                    var notification = Notification(name: .SelectionDidChangeNotification, object: self)

                    if let item = button.cell?.representedObject {
                        notification.userInfo = ["selectedItem": item]
                        datasource?.tabControl?(self, didSelect: item)
                    }

                    NotificationCenter.default.post(notification)
                    datasource?.tabControlDidChangeSelection?(notification)

                    NSAnimationContext.runAnimationGroup({ (context) in
                        context.allowsImplicitAnimation = true
                        button.scrollToVisible(button.bounds)
                    }, completionHandler: nil)

                } else {
                    button.state = .off
                }
                button.needsDisplay = true
            }
            sortDocumentView()

            invalidateRestorableState()
        }
        get {
            return scrollView.documentView?.subviews.compactMap({ $0 as? TabButton}).first(where: { $0.state == .on })?.cell?.representedObject
        }
    }

    private static var myContext = 0

    private func startObservingScrollView() {
        scrollView.addObserver(self, forKeyPath: #keyPath(NSScrollView.frame), options: [], context: &TabControl.myContext)
        scrollView.addObserver(self, forKeyPath: #keyPath(NSScrollView.documentView.frame), options: [], context: &TabControl.myContext)

        NotificationCenter.default.addObserver(self, selector: #selector(scrollViewDidScroll), name: NSView.boundsDidChangeNotification, object: self.scrollView.contentView)

    }

    private func stopObservingScrollView() {
        scrollView.removeObserver(self, forKeyPath: #keyPath(NSScrollView.frame), context: &TabControl.myContext)
        scrollView.removeObserver(self, forKeyPath: #keyPath(NSScrollView.documentView.frame), context: &TabControl.myContext)

        NotificationCenter.default.removeObserver(self, name: NSView.boundsDidChangeNotification, object: self.scrollView.contentView)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &TabControl.myContext {
            updateButtons()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    @objc private func scrollViewDidScroll(_ notification: Notification) {
        updateButtons()
        invalidateRestorableState()
    }

    private func updateButtons() {
        let showAddButton = addAction != nil

        addWidthConstraint?.constant = showAddButton ? 48 : 0

        let contentView = scrollView.contentView

        let clipped = !contentView.subviews.isEmpty && contentView.subviews[0].frame.maxX > contentView.bounds.width
        if clipped {
            scrollLeftButton.isHidden = false
            scrollRightButton.isHidden = false
            scrollLeftButton.isEnabled = firstTabLeftOutsideVisibleRect() != nil
            scrollRightButton.isEnabled = firstTabRightOutsideVisibleRect() != nil
        } else {
            scrollLeftButton.isHidden = true
            scrollRightButton.isHidden = true
        }
    }

    @objc private func selectTab(_ tab: TabButton) {
        selectedItem = tab.cell?.representedObject

        if let item = tab.cell?.representedObject, let currentEvent = NSApp.currentEvent {
            if currentEvent.clickCount > 1 {
                edit(button: tab)
            } else if datasource?.tabControl(self, canReorder: item) ?? true, let window = window {
                // watch for a drag event and initiate dragging if a drag is found...

                if window.nextEvent(matching: [.leftMouseUp, .leftMouseDragged], until: NSDate.distantFuture, inMode: .eventTrackingRunLoopMode, dequeue: false)?.type == .leftMouseDragged {
                    reorder(tab: tab, with: currentEvent)
                    return
                }
            }

        }
        // scroll to visible if either editing or selecting...
        NSAnimationContext.runAnimationGroup({ context in
            context.allowsImplicitAnimation = true
            tab.superview?.scrollToVisible(tab.frame)
        }, completionHandler: nil)

        invalidateRestorableState()

    }

    func reorder(tab: TabButton, with startEvent: NSEvent) {
        // note existing tabs which will be reordered over
        // the course of our drag; while the dragging tab maintains
        // its position over the course of the dragging operation

        guard let tabView = self.scrollView.documentView,
            let item = tab.cell?.representedObject else {
            return
        }

        var orderedItems = items

        // create a dragging tab used to represent our drag,
        // and constraint its position and its size; the first
        // constraint sets position - we'll be varying this one
        // during our drag...

        let tabX = tab.frame.minX

        let dragPoint = tabView.convert(startEvent.locationInWindow, from: nil)

        let draggingTab = self.tab(with: item)

        let draggingConstraints   = [NSLayoutConstraint(item: draggingTab, attribute: .leading, relatedBy: .equal, toItem: tabView, attribute: .leading, multiplier: 1, constant: tabX),
                                     NSLayoutConstraint(item: draggingTab, attribute: .top, relatedBy: .equal, toItem: tabView, attribute: .top, multiplier: 1, constant: 0),
                                     NSLayoutConstraint(item: draggingTab, attribute: .bottom, relatedBy: .equal, toItem: tabView, attribute: .bottom, multiplier: 1, constant: 0)]

        let newCell = TabCell(other: tab.cell)
        newCell?.borderMask = [.bottom]
        draggingTab.cell = newCell
        draggingTab.state = .on

        // cell subclasses may alter drawing based on represented object
        draggingTab.cell?.representedObject = item

        // the presence of a menu affects the vertical offset of our title
        if let menu = tab.cell?.menu {
            draggingTab.cell?.menu = menu
        }

        tabView.addSubview(draggingTab)
        tabView.addConstraints(draggingConstraints)

        (tab.cell as! TabCell).dragging = true
        var prevPoint = dragPoint
        var dragged = false
        var reordered = false

        while let event = window?.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]), event.type != .leftMouseUp {

            // ensure the dragged tab shows borders on both of its sides when dragging
            if !dragged {
                dragged = true
            }

            // move the dragged tab
            let nextPoint = tabView.convert(event.locationInWindow, from: nil)

            let nextX = tabX + (nextPoint.x - dragPoint.x)

            let movingLeft = (nextPoint.x < prevPoint.x)
            let movingRight = (nextPoint.x > prevPoint.x)

            prevPoint = nextPoint

            draggingConstraints[0].constant = nextX

            var swapped = false
            // test for reordering...
            if movingLeft && draggingTab.frame.midX < tab.frame.minX && (tab.cell?.representedObject as? NSObject) != (orderedItems.first as? NSObject) {
                // shift left
                let index = orderedItems.index(where: { ($0 as? NSObject) == item as? NSObject})!
                orderedItems.swapAt(index, index - 1)

                swapped = true
                reordered = true

            } else if movingRight && draggingTab.frame.midX > tab.frame.maxX && (tab.cell?.representedObject as? NSObject) != (orderedItems.last as? NSObject) {
                // shift right
                let index = orderedItems.index(where: { ($0 as? NSObject) == item as? NSObject})!
                orderedItems.swapAt(index + 1, index)
                swapped = true
                reordered = true
            }
            if swapped {
                NSAnimationContext.runAnimationGroup({context in
                    context.allowsImplicitAnimation = true
                    context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
                    self.layoutTabs(items: orderedItems)
                    tabView.addConstraints(draggingConstraints)
                    tabView.layoutSubtreeIfNeeded()
                }, completionHandler: nil)
            }
        }

        tabView.removeConstraints(draggingConstraints)
        draggingTab.removeConstraints(draggingTab.constraints)

        NSAnimationContext.runAnimationGroup({context in
            context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            draggingTab.animator().frame = tab.frame
        }, completionHandler: {

            draggingTab.removeFromSuperview()
            (tab.cell as! TabCell).dragging = false
            tab.cell?.controlView = tab

            if reordered, self.datasource?.tabControl(self, didReorderItems: orderedItems) ?? true {
                self.reloadData()
                self.selectedItem = tab.cell?.representedObject
            }
        })

    }

    private func sortDocumentView() {
        scrollView.documentView?.sortSubviews({ (first, second, context) -> ComparisonResult in
            guard let b1 = first as? NSButton, let b2 = second as? NSButton else {
                return .orderedSame
            }

            if b1.state == b2.state {
                return .orderedSame
            } else {
                if b1.state == .off && b2.state == .on {
                    return .orderedAscending
                } else {
                    return .orderedDescending
                }
            }
        }, context: nil)
    }

    private func tabButton(with item: AnyObject) -> TabButton? {
        for view in scrollView.documentView?.subviews ?? [] {
            guard let button = view as? TabButton else {
                continue
            }

            if (button.cell?.representedObject as? NSObject) == (item as? NSObject) {
                return button
            }
        }
        return nil
    }

    private func tab(with item: Any) -> TabButton {

        let cell = TabCell(textCell: "")
        cell.representedObject = item
        if let bindArg = datasource?.tabControl(self, titleKeyPathFor: item) {
            cell.bind(NSBindingName.title, to: item, withKeyPath: bindArg, options: [.nullPlaceholder: "Untitled"])
        }

        cell.imagePosition = .noImage
        cell.borderMask = [.left, .right, .bottom]
        cell.target          = self
        cell.action          = #selector(selectTab)
        cell.sendAction(on: .leftMouseDown)

        let tab = TabButton(frame: .zero)
        tab.translatesAutoresizingMaskIntoConstraints = false
        tab.cell = cell
        tab.minWidth = 198
        tab.maxWidth = 250

        return tab

    }

    private func layoutTabs(items: [Any]) {
        guard let tabView = scrollView.documentView else {
            return
        }

        tabView.removeConstraints(tabView.constraints)
        let buttonViews = tabView.subviews.compactMap({ $0 as? TabButton })
        var prev: TabButton?

        for item in items {
            guard let button = buttonViews.first(where: {($0.cell?.representedObject as? NSObject) == (item as? NSObject) }) else {
                fatalError("Missing tab!")
            }
            tabView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view":button]))
            tabView.addConstraint(NSLayoutConstraint(item: button, attribute: .leading, relatedBy: .equal, toItem: prev ?? tabView, attribute: prev != nil ? .trailing : .leading, multiplier: 1, constant: prev == nil ? 0 : -1 ))
            prev = button
        }

        if let last = prev {
            let trailingConstraint = NSLayoutConstraint(item: last, attribute: .trailing, relatedBy: .lessThanOrEqual, toItem: tabView, attribute: .trailing, multiplier: 1, constant: 0)
            trailingConstraint.priority = .windowSizeStayPut
            tabView.addConstraint(trailingConstraint)
        }
        tabView.layoutSubtreeIfNeeded()
    }

    private func edit(item: Any) {
        guard let button = self.tabButton(with: item as AnyObject) else {
            return
        }
        edit(button: button)
    }
    private func edit(button: TabButton) {

        if self.editingField != nil {
            self.window?.makeFirstResponder(self)
        }
        layoutSubtreeIfNeeded()

        guard let item = button.cell?.representedObject, datasource?.tabControl?(self, canEdit: item) ?? true else {
            return
        }

        let cell = button.cell as! TabCell
        let titleRect = cell.editingRect(forBounds: button.bounds)

        let editingField = NSTextField(frame: titleRect)

        editingField.isEditable = true
        editingField.font = cell.font
        editingField.alignment = cell.alignment
        editingField.backgroundColor = cell.backgroundColor
        editingField.focusRingType = .none

        editingField.textColor = NSColor.darkGray.blended(withFraction: 0.5, of: NSColor.black)

        let textFieldCell = editingField.cell as! NSTextFieldCell

        textFieldCell.isBordered = false
        textFieldCell.isScrollable = true

        editingField.stringValue = button.title

        button.addSubview(editingField)

        editingField.delegate = self
        editingField.selectText(self)
        self.editingField = editingField
    }
}

extension TabControl: NSTextFieldDelegate {
    override func controlTextDidEndEditing(_ obj: Notification) {
        defer {
            editingField?.delegate = nil
            editingField?.removeFromSuperview()
            editingField = nil
        }

        guard let title = self.editingField?.stringValue else {
            return
        }

        guard let button = editingField?.superview as? TabButton,
            let item = button.cell?.representedObject else {
                return
        }

        if !title.isEmpty {
            button.title = title
            datasource?.tabControl?(self, setTitle: title, for: item)
        }

        NotificationCenter.default.post(name: obj.name, object: self, userInfo: obj.userInfo)
    }
}
