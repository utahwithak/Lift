//
//  NSImage+Additions.swift
//  Tabs
//
//  Created by Carl Wieland on 11/6/17.
//  Copyright © 2017 Datum Apps. All rights reserved.
//

import Cocoa

extension NSImage {

    func tintedImage(with color: NSColor) -> NSImage {
        var imageRect = NSRect.zero
        imageRect.size = self.size

        let highlightImage = NSImage(size: imageRect.size)
        highlightImage.lockFocus()
        draw(in: imageRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        color.set()
        imageRect.fill(using: .sourceAtop)
        highlightImage.unlockFocus()
        return highlightImage
    }
}
