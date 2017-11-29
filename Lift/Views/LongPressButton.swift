//
//  LongPressButton.swift
//  Lift
//
//  Created by Carl Wieland on 10/17/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

class LongPressButton: NSButton {

    var delay: TimeInterval = 0.5

    private var showingMenu = false

    private var longPressTimer: Timer?

    lazy var overlayImage: NSImage? = {
        if let originalImage = self.image {
            let arrowImage = #imageLiteral(resourceName: "overlay")
            let newImage = NSImage(size: frame.size)
            newImage.lockFocus()

            originalImage.draw(in: NSRect(x: frame.midX - originalImage.size.width / 2, y: frame.midY - originalImage.size.height / 2, width: originalImage.size.width, height: originalImage.size.height))
            arrowImage.draw(in: frame , from:arrowImage.alignmentRect, operation: .sourceOver, fraction:1)
            newImage.unlockFocus()
            newImage.isTemplate = true
            return newImage
        }
        return nil
    }()

    private var originalImage: NSImage?

    override func awakeFromNib() {
        let trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }

    override func mouseDown(with event: NSEvent) {

        guard isEnabled else {
            return
        }

        showingMenu = false
        longPressTimer = Timer(timeInterval: delay, repeats: false, block: {[weak self] timer in

            if let menu = self?.menu {
                NSMenu.popUpContextMenu(menu, with: event, for: self!)
                self?.showingMenu = true
            }
        })
        RunLoop.current.add(longPressTimer!, forMode: .commonModes)

    }
    override func mouseUp(with event: NSEvent) {
        guard isEnabled else {
            return
        }
        longPressTimer?.invalidate()
        if !showingMenu, let action = self.action, let target = self.target {
            NSApp.sendAction(action, to: target, from: self)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        guard isEnabled else {
            return
        }
        originalImage = image
        image = overlayImage
        super.mouseEntered(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        guard isEnabled else {
            return
        }
        image = originalImage
        super.mouseExited(with: event)
    }
}
