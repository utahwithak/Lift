//
//  CompletionPanel.swift
//  Lift
//
//  Created by Carl Wieland on 9/14/18.
//  Copyright © 2018 Datum Apps. All rights reserved.
//

import Cocoa

class CompletionPanel: NSWindow {

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        styleMask = [.borderless]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
    }

    override var contentView: NSView? {
        didSet {
            if let rootView = contentView {
                rootView.wantsLayer             = true
                rootView.layer?.frame           = rootView.frame
                rootView.layer?.cornerRadius    = 4.0
                rootView.layer?.masksToBounds   = true
            }
        }
    }
}
